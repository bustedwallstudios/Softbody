extends RigidBody2D

# Set by the spring every frame
var totalSpringForce:Vector2

var gravityForce:Vector2

func _physics_process(delta):
	# Add the force from the springs to this point, adjusting for mass
	self.linear_velocity += (totalSpringForce)/mass
	
	# Prevent rotation, so the points cannot roll.
	# This results in better friction.
	self.angular_velocity = 0
	self.rotation_degrees = 0
	
	# In the meantime, do the gravity amount
	totalSpringForce = gravityForce
