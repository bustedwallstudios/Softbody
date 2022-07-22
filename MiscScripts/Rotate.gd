extends StaticBody2D

export (float) var degreesPerFrame = 0.1

func _process(delta):
	rotation_degrees += degreesPerFrame
