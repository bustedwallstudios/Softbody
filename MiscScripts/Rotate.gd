extends StaticBody2D

@export (float) var degreesPerFrame = 0.1

# warning-ignore:unused_argument
func _process(delta):
	rotation_degrees += degreesPerFrame
