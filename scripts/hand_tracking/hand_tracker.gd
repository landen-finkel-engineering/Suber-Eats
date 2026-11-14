class_name HandTracker
extends Node
## Webcam hand tracking that runs entirely inside Godot (no extra program).
## Uses the GDMP plugin in addons/GDMP, which wraps Google's MediaPipe hand tracker.
##
## Drop this node into any scene and read these variables every frame:
##   hand_visible   true when a hand is in view
##   hand_position  the pinch point (between thumb tip and index tip), 0-1 across the
##                  camera image, mirrored like a mirror so moving right moves right
##   is_pinching    true while thumb and index finger are pinched together
##   pinch_ratio    finger gap divided by hand size (about 1.0 = open, below 0.3 = pinched)
##   landmarks      all 21 hand points (0-1), for drawing the hand
##   status         a human-readable message about what the tracker is doing
##
## The first time it runs it downloads the hand model (about 8 MB) and keeps it, so you
## need internet once. To skip the download, put hand_landmarker.task in assets/models/.

signal pinch_started
signal pinch_ended
signal status_changed(text: String)

const MODEL_URL := "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task"
## If this file exists it's used and nothing is downloaded.
const BUNDLED_MODEL_PATH := "res://assets/models/hand_landmarker.task"
## Where the downloaded model is kept on each computer.
const CACHED_MODEL_PATH := "user://models/hand_landmarker.task"

# MediaPipe's hand point numbers.
const WRIST := 0
const THUMB_TIP := 4
const INDEX_TIP := 8
const MIDDLE_BASE := 9

## Start the camera and tracking automatically.
@export var start_on_ready := true
## A pinch STARTS when the finger gap is smaller than this fraction of your hand size.
@export_range(0.05, 1.0, 0.01) var pinch_on_ratio := 0.30
## A pinch ENDS when the gap gets bigger than this. Keep it above pinch_on_ratio so it doesn't flicker.
@export_range(0.05, 1.5, 0.01) var pinch_off_ratio := 0.45
## Smooths out shaky tracking. 0 = raw and jittery, 0.9 = very smooth but laggy.
@export_range(0.0, 0.95, 0.05) var smoothing := 0.5
## Preferred camera image width. Smaller is faster to track.
@export var preferred_camera_width := 640

var hand_visible := false
var hand_position := Vector2(0.5, 0.5)
var is_pinching := false
var pinch_ratio := 1.0
var landmarks := PackedVector2Array()
var status := "Starting..."
## Width / height of the camera image.
var camera_aspect := 4.0 / 3.0

var _task = null  # MediaPipeHandLandmarker. Left untyped so this script still runs without the plugin.
var _feed: CameraFeed = null
var _viewport: SubViewport
var _camera_rect: TextureRect
var _display_ready := false
var _waiting_for_frame := false
var _last_timestamp := 0
var _poll_timer := 0.0


func _ready() -> void:
	# The camera image is drawn into this hidden viewport, converted to normal colors and
	# mirrored, then read back and handed to MediaPipe.
	_viewport = SubViewport.new()
	_viewport.name = "CameraViewport"
	_viewport.size = Vector2i(640, 480)
	_viewport.disable_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_camera_rect = TextureRect.new()
	_viewport.add_child(_camera_rect)
	if start_on_ready:
		start()


func _exit_tree() -> void:
	if _task != null and _task.result_callback.is_connected(_on_result):
		_task.result_callback.disconnect(_on_result)
	_task = null
	if _feed != null:
		_feed.feed_is_active = false


## Is the hand tracking plugin available on this computer?
static func is_supported() -> bool:
	return ClassDB.class_exists("MediaPipeHandLandmarker")


## The live (mirrored) camera picture, for showing a preview on screen.
func get_camera_texture() -> Texture2D:
	if _feed == null:
		return null
	return _viewport.get_texture()


func start() -> void:
	if not is_supported():
		_set_status("Hand tracking plugin didn't load. Using the mouse.")
		return
	_load_model()


# ---------------------------------------------------------------------------
# Hand model
# ---------------------------------------------------------------------------

func _load_model() -> void:
	for path in [BUNDLED_MODEL_PATH, CACHED_MODEL_PATH]:
		if FileAccess.file_exists(path):
			var bytes := FileAccess.get_file_as_bytes(path)
			if bytes.size() > 1000:
				_create_task(bytes)
				_start_camera()
				return
	_download_model()


func _download_model() -> void:
	_set_status("Downloading hand model (8 MB, first time only)...")
	DirAccess.make_dir_recursive_absolute(CACHED_MODEL_PATH.get_base_dir())
	var request := HTTPRequest.new()
	add_child(request)
	request.download_file = CACHED_MODEL_PATH + ".part"
	request.request_completed.connect(_on_model_downloaded.bind(request))
	if request.request(MODEL_URL) != OK:
		request.queue_free()
		_set_status("Couldn't start the model download. Using the mouse.")


func _on_model_downloaded(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray, request: HTTPRequest) -> void:
	request.queue_free()
	var part := CACHED_MODEL_PATH + ".part"
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		DirAccess.remove_absolute(part)
		_set_status("Couldn't download hand model (internet?). Using mouse.")
		return
	DirAccess.remove_absolute(CACHED_MODEL_PATH)
	DirAccess.rename_absolute(part, CACHED_MODEL_PATH)
	_load_model()


func _create_task(model_bytes: PackedByteArray) -> void:
	var options = ClassDB.instantiate("MediaPipeTaskBaseOptions")
	options.delegate = ClassDB.class_get_integer_constant("MediaPipeTaskBaseOptions", "DELEGATE_CPU")
	options.model_asset_buffer = model_bytes
	_task = ClassDB.instantiate("MediaPipeHandLandmarker")
	var live_mode := ClassDB.class_get_integer_constant("MediaPipeVisionTask", "RUNNING_MODE_LIVE_STREAM")
	# initialize(options, mode, number of hands, detection / presence / tracking confidence)
	_task.initialize(options, live_mode, 1, 0.5, 0.5, 0.5)
	_task.result_callback.connect(_on_result)


# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------

func _start_camera() -> void:
	_set_status("Looking for a camera...")
	CameraServer.camera_feed_added.connect(_on_camera_added)
	# Newer Godot versions only list cameras after you ask them to.
	if "monitoring_feeds" in CameraServer:
		if CameraServer.has_signal("camera_feeds_updated"):
			CameraServer.connect("camera_feeds_updated", _pick_camera, CONNECT_DEFERRED)
		CameraServer.set("monitoring_feeds", true)
	_pick_camera()
	await get_tree().create_timer(4.0).timeout
	if _feed == null:
		_set_status("No camera found, or not allowed. Using the mouse.")


func _on_camera_added(_id: int) -> void:
	_pick_camera.call_deferred()


func _pick_camera() -> void:
	if _feed != null or CameraServer.get_feed_count() == 0:
		return
	var feeds := CameraServer.feeds()
	var chosen: CameraFeed = feeds[0]
	for feed in feeds:
		if feed.get_position() == CameraFeed.FEED_FRONT:
			chosen = feed
			break
	_feed = chosen

	# Pick the camera mode closest to preferred_camera_width (newer Godot versions).
	if _feed.has_method("get_formats") and _feed.has_method("set_format"):
		var formats: Array = _feed.call("get_formats")
		var best := -1
		var best_diff := 1 << 30
		for i in formats.size():
			var diff := absi(int(formats[i].get("width", 0)) - preferred_camera_width)
			if diff < best_diff:
				best_diff = diff
				best = i
		if best >= 0:
			_feed.call("set_format", best, {})

	_camera_rect.flip_h = _feed.get_position() != CameraFeed.FEED_BACK  # mirror front cameras
	if _feed.has_signal("format_changed"):
		_feed.connect("format_changed", _on_format_changed, CONNECT_DEFERRED)
	if _feed.has_signal("frame_changed"):
		_feed.connect("frame_changed", _on_frame_changed, CONNECT_DEFERRED)
	_feed.feed_is_active = true
	_on_format_changed()
	_set_status("Camera on (%s). Show your hand!" % _feed.get_name())


func _on_format_changed() -> void:
	_display_ready = false


## Hooks the camera picture up to the hidden viewport. Returns false until the camera
## has told us its picture size.
func _setup_display() -> bool:
	var frame_size := Vector2i.ZERO
	match _feed.get_datatype():
		CameraFeed.FEED_RGB:
			var tex := CameraTexture.new()
			tex.camera_feed_id = _feed.get_id()
			tex.which_feed = CameraServer.FEED_RGBA_IMAGE
			frame_size = tex.get_size()
			_camera_rect.material = null
			_camera_rect.texture = tex
		CameraFeed.FEED_YCBCR:
			var tex := CameraTexture.new()
			tex.camera_feed_id = _feed.get_id()
			tex.which_feed = CameraServer.FEED_YCBCR_IMAGE
			frame_size = tex.get_size()
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://scripts/hand_tracking/yuy2_to_rgb.gdshader")
			mat.set_shader_parameter("texture_yuy2", tex)
			_camera_rect.material = mat
			_camera_rect.texture = _blank_texture(frame_size)
		CameraFeed.FEED_YCBCR_SEP:
			var tex_y := CameraTexture.new()
			var tex_uv := CameraTexture.new()
			tex_y.camera_feed_id = _feed.get_id()
			tex_uv.camera_feed_id = _feed.get_id()
			tex_y.which_feed = CameraServer.FEED_Y_IMAGE
			tex_uv.which_feed = CameraServer.FEED_CBCR_IMAGE
			frame_size = tex_y.get_size()
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://scripts/hand_tracking/yuv420_to_rgb.gdshader")
			mat.set_shader_parameter("texture_y", tex_y)
			mat.set_shader_parameter("texture_uv", tex_uv)
			_camera_rect.material = mat
			_camera_rect.texture = _blank_texture(frame_size)
		_:
			return false
	if frame_size.x <= 0 or frame_size.y <= 0:
		return false

	var feed_rotation: float = _feed.feed_transform.get_rotation()
	if _camera_rect.flip_h:
		feed_rotation *= -1
	var rotated := Vector2(frame_size).rotated(feed_rotation)
	_camera_rect.rotation = feed_rotation
	_camera_rect.position = -Vector2(minf(rotated.x, 0), minf(rotated.y, 0))
	var out_size := Vector2i(absi(roundi(rotated.x)), absi(roundi(rotated.y)))
	_viewport.size = out_size
	camera_aspect = float(out_size.x) / float(out_size.y)
	return true


func _blank_texture(frame_size: Vector2i) -> ImageTexture:
	var image := Image.create_empty(maxi(frame_size.x, 1), maxi(frame_size.y, 1), false, Image.FORMAT_RGB8)
	return ImageTexture.create_from_image(image)


func _process(delta: float) -> void:
	# Older Godot versions have no frame_changed signal, so poll about 30 times a second.
	if _feed != null and not _feed.has_signal("frame_changed"):
		_poll_timer += delta
		if _poll_timer >= 1.0 / 30.0:
			_poll_timer = 0.0
			_on_frame_changed()


func _on_frame_changed() -> void:
	if _task == null or _feed == null or _waiting_for_frame:
		return
	if not _display_ready:
		_display_ready = _setup_display()
		return
	_waiting_for_frame = true
	await RenderingServer.frame_post_draw
	_waiting_for_frame = false
	if _task == null:
		return
	var image := _viewport.get_texture().get_image()
	if image == null or image.is_empty():
		return
	image.convert(Image.FORMAT_RGB8)
	var mp_image = ClassDB.instantiate("MediaPipeImage")
	mp_image.set_image(image)
	var timestamp := Time.get_ticks_msec()
	if timestamp <= _last_timestamp:
		timestamp = _last_timestamp + 1
	_last_timestamp = timestamp
	_task.detect_async(mp_image, timestamp)


# ---------------------------------------------------------------------------
# Results (MediaPipe calls this from its own thread)
# ---------------------------------------------------------------------------

func _on_result(result, _image, _timestamp_ms: int) -> void:
	var points := PackedVector2Array()
	var hands: Array = result.hand_landmarks
	if hands.size() > 0:
		for point in hands[0].landmarks:
			points.append(Vector2(point.x, point.y))
	_apply_landmarks.call_deferred(points)


func _apply_landmarks(points: PackedVector2Array) -> void:
	landmarks = points
	if points.size() < 21:
		hand_visible = false
		if is_pinching:
			is_pinching = false
			pinch_ended.emit()
		return

	# Measure in real proportions (camera x is stretched by the aspect ratio).
	var aspect := Vector2(camera_aspect, 1.0)
	var thumb := points[THUMB_TIP]
	var index := points[INDEX_TIP]
	var hand_size := ((points[WRIST] - points[MIDDLE_BASE]) * aspect).length()
	var gap := ((thumb - index) * aspect).length()
	pinch_ratio = gap / maxf(hand_size, 0.0001)

	var pinch_point := (thumb + index) * 0.5
	if hand_visible:
		hand_position = hand_position.lerp(pinch_point, 1.0 - smoothing)
	else:
		hand_position = pinch_point
	hand_visible = true

	if not is_pinching and pinch_ratio < pinch_on_ratio:
		is_pinching = true
		pinch_started.emit()
	elif is_pinching and pinch_ratio > pinch_off_ratio:
		is_pinching = false
		pinch_ended.emit()


func _set_status(text: String) -> void:
	status = text
	status_changed.emit(text)
	print("[HandTracker] ", text)
