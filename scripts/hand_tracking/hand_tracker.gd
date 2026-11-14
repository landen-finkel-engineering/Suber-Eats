extends Node

# Webcam hand tracking inside Godot, using the GDMP plugin (Google MediaPipe).
# Read hand_visible, hand_position (0-1, mirrored) and is_pinching.
# The hand model downloads the first time (about 8 MB) and is kept after that.

const MODEL_URL = "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task"
const MODEL_PATH = "user://hand_landmarker.task"

# pinch starts below pinch_on and ends above pinch_off (finger gap / hand size)
@export var pinch_on := 0.3
@export var pinch_off := 0.45
@export var smoothing := 0.5

var hand_visible := false
var hand_position := Vector2(0.5, 0.5)
var is_pinching := false
var status := "Starting..."

var task
var feed: CameraFeed
var aspect := 4.0 / 3.0
var ready_to_read := false
var busy := false
var last_time := 0

# the camera picture gets drawn here, then read back and sent to MediaPipe
@onready var view = SubViewport.new()
@onready var picture = TextureRect.new()


func _ready():
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.add_child(picture)
	add_child(view)
	if not ClassDB.class_exists("MediaPipeHandLandmarker"):
		status = "Hand tracking plugin didn't load. Using the mouse."
		return
	if FileAccess.file_exists(MODEL_PATH):
		start()
	else:
		download_model()


func camera_texture():
	return view.get_texture() if feed else null


func download_model():
	status = "Downloading hand model (first time only)..."
	var http = HTTPRequest.new()
	add_child(http)
	http.download_file = MODEL_PATH + ".part"
	http.request_completed.connect(func(result, code, _h, _b):
		http.queue_free()
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			DirAccess.rename_absolute(MODEL_PATH + ".part", MODEL_PATH)
			start()
		else:
			status = "Couldn't download hand model. Using the mouse."
	)
	http.request(MODEL_URL)


func start():
	var options = ClassDB.instantiate("MediaPipeTaskBaseOptions")
	options.model_asset_buffer = FileAccess.get_file_as_bytes(MODEL_PATH)
	task = ClassDB.instantiate("MediaPipeHandLandmarker")
	task.initialize(options, 3, 1)  # 3 = live stream, 1 hand
	task.result_callback.connect(_on_result)

	status = "Looking for a camera..."
	CameraServer.camera_feeds_updated.connect(pick_camera, CONNECT_DEFERRED)
	CameraServer.monitoring_feeds = true
	pick_camera()


func pick_camera():
	if feed or CameraServer.get_feed_count() == 0:
		return
	feed = CameraServer.get_feed(0)
	# use the camera mode closest to 640 wide
	var formats = feed.get_formats()
	var best = 0
	for i in formats.size():
		if abs(formats[i].get("width", 0) - 640) < abs(formats[best].get("width", 0) - 640):
			best = i
	if formats.size() > 0:
		feed.set_format(best, {})
	picture.flip_h = feed.get_position() != CameraFeed.FEED_BACK
	feed.format_changed.connect(func(): ready_to_read = false, CONNECT_DEFERRED)
	feed.frame_changed.connect(_on_frame, CONNECT_DEFERRED)
	feed.feed_is_active = true
	status = "Camera on. Show your hand!"


# hooks the camera picture up to the viewport, converting it to normal colors
func setup_picture():
	var size = Vector2i.ZERO
	var mat = null
	if feed.get_datatype() == CameraFeed.FEED_RGB:
		var tex = CameraTexture.new()
		tex.camera_feed_id = feed.get_id()
		size = tex.get_size()
		picture.texture = tex
	elif feed.get_datatype() == CameraFeed.FEED_YCBCR:
		var tex = CameraTexture.new()
		tex.camera_feed_id = feed.get_id()
		tex.which_feed = CameraServer.FEED_YCBCR_IMAGE
		size = tex.get_size()
		mat = ShaderMaterial.new()
		mat.shader = preload("res://scripts/hand_tracking/yuy2_to_rgb.gdshader")
		mat.set_shader_parameter("texture_yuy2", tex)
	elif feed.get_datatype() == CameraFeed.FEED_YCBCR_SEP:
		var y = CameraTexture.new()
		var uv = CameraTexture.new()
		y.camera_feed_id = feed.get_id()
		uv.camera_feed_id = feed.get_id()
		y.which_feed = CameraServer.FEED_Y_IMAGE
		uv.which_feed = CameraServer.FEED_CBCR_IMAGE
		size = y.get_size()
		mat = ShaderMaterial.new()
		mat.shader = preload("res://scripts/hand_tracking/yuv420_to_rgb.gdshader")
		mat.set_shader_parameter("texture_y", y)
		mat.set_shader_parameter("texture_uv", uv)
	if size.x == 0 or size.y == 0:
		return false
	if mat:
		picture.material = mat
		picture.texture = ImageTexture.create_from_image(Image.create_empty(size.x, size.y, false, Image.FORMAT_RGB8))
	view.size = size
	aspect = float(size.x) / size.y
	return true


func _on_frame():
	if busy or task == null:
		return
	if not ready_to_read:
		ready_to_read = setup_picture()
		return
	busy = true
	await RenderingServer.frame_post_draw
	busy = false
	var image = view.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	var mp_image = ClassDB.instantiate("MediaPipeImage")
	mp_image.set_image(image)
	last_time = max(Time.get_ticks_msec(), last_time + 1)
	task.detect_async(mp_image, last_time)


# MediaPipe calls this from another thread
func _on_result(result, _image, _time):
	var points = PackedVector2Array()
	if result.hand_landmarks.size() > 0:
		for p in result.hand_landmarks[0].landmarks:
			points.append(Vector2(p.x, p.y))
	update_hand.call_deferred(points)


func update_hand(points):
	if points.size() < 21:
		hand_visible = false
		is_pinching = false
		return
	# 0 = wrist, 4 = thumb tip, 8 = index tip, 9 = base of middle finger
	var s = Vector2(aspect, 1)
	var hand_size = ((points[0] - points[9]) * s).length()
	var gap = ((points[4] - points[8]) * s).length() / hand_size
	var pinch_point = (points[4] + points[8]) / 2

	hand_position = hand_position.lerp(pinch_point, 1 - smoothing) if hand_visible else pinch_point
	hand_visible = true
	if gap < pinch_on:
		is_pinching = true
	elif gap > pinch_off:
		is_pinching = false
