extends RigidBody2D

# Set by the springs every frame
var totalSpringForce:Vector2

var gravityForce:Vector2

# If this is true, each point will be colored based on the forces being applied to it.
var doTint:bool
# This is the TOTAL FORCE applied by EVERY spring attached to this point.
# If there are two springs connected to this point, which are applying equal and
# opposite forces, the NET force will be 0. However, here I am interested in the 
# total absolute force, so instead of adding the vectors, I instead add the scalar
# length of all spring forces acting on this point.
var absoluteForce:float = 0.01

func _physics_process(_delta):
	
	# The force we will apply to the point. The springs should not have as much of an effect on 
	# the points if there is a high mass (F = ma -> a = F/m). The gravity is unaffected by the
	# mass, and so is added on outside of the division.
	var finalForce = ((totalSpringForce)/mass) + gravityForce
	
	if doTint:
		# The color range: the higher absoluteForce, the closer to 0 the result is, and the closer to red
		# the point becomes.
		var tint = 1/(absoluteForce/100)
		
		$Marker.color = Color(1, tint, tint)
	
	self.linear_velocity += finalForce
	
	# Prevent rotation, so the points cannot roll.
	# This results in better friction.
	self.angular_velocity = 0
	self.rotation_degrees = 0
	
	# Reset this to 0 for next frame
	totalSpringForce = Vector2.ZERO
	absoluteForce = 0.01

func applySpringForce(f):
	# For the tint
	absoluteForce += f.length()
	
	totalSpringForce += f
