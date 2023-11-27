extends RigidBody2D

func _ready():
	self.linear_velocity.x = 100

func _physics_process(delta):
	print(self.get_parent().get_node("Timer").time_left)
