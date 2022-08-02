extends Node2D

var currentCamera:int = 1

func _process(delta):
	if Input.is_action_just_pressed("enterKey"):
		currentCamera += 1
	
	if currentCamera % 2 == 0:
		$SquishyBody.enableThisCamera()
	elif currentCamera % 2 == 1:
		$WorldCamera.current = true
