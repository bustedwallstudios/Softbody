extends RigidBody2D

# Set by the spring every frame
var totalSpringForce:Vector2

var gravityForce:Vector2

func _physics_process(delta):
	
	# The force we will apply to the point. The springs should not have as much of an effect on 
	# the points if there is a high mass (F = ma -> a = F/m). The gravity is unaffected by the
	# mass, and so is added on outside of the division.
	var finalForce = ((totalSpringForce)/mass) + gravityForce
	
	self.linear_velocity += finalForce
	
	# Prevent rotation, so the points cannot roll.
	# This results in better friction.
	self.angular_velocity = 0
	self.rotation_degrees = 0
	
	# Reset this to 0 for next frame
	totalSpringForce = Vector2.ZERO
