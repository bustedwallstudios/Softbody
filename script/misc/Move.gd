extends Node2D

@export var moveSpeed:float    = 5
@export var moveDistance:float = 10

@export var sinCos:bool = true

var t = 0

# warning-ignore:unused_argument
func _physics_process(delta):
	t += delta*moveSpeed
	
	if sinCos:
		$Body.position.y += sin(t) * (moveDistance*(moveSpeed/5))
	
	else:
		$Body.position.y += cos(t) * (moveDistance*(moveSpeed/5))

