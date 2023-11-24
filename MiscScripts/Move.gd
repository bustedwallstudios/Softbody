extends StaticBody2D

@export var moveSpeed:float    = 5
@export var moveDistance:float = 10

@export var sinCos:bool = true

var t = 0

# warning-ignore:unused_argument
func _physics_process(delta):
	t += delta*moveSpeed
	
	if sinCos:
		self.position.y += sin(t) * moveDistance
	
	else:
		self.position.y += cos(t) * moveDistance

