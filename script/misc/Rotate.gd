extends RigidBody2D

@export var rotationalForce:float = 5

var t = 0

# warning-ignore:unused_argument
func _physics_process(delta):
	t += delta*5
	self.angular_velocity = sin(t) * 2

