extends Bouncer

var alarm := 0.0
var hood_open = preload("res://assets/graphics/unorganized/car-2-off.png")
var lights_on = preload("res://assets/graphics/unorganized/car-2-on.png")


func hit():
	super()
	$Alarm.play()
	alarm = 1.5


func _process(delta):
	if alarm <= 0:
		return
	alarm -= delta
	$Sprite2D.texture = lights_on if int(alarm * 6) % 2 else hood_open
	if alarm <= 0:
		$Alarm.stop()
		$Sprite2D.texture = hood_open
