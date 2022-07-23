extends RigidBody2D

# Set by the spring every frame
var totalSpringForce:Vector2

# This is used by the spring to determine if the point has moved since last frame.
# If it hasn't moved, no gravity will be applied, because it must be at rest.
var posLastFrame:Vector2

func _ready():
	# We don't want it to be the same on the first frame, 
	# so we just make it a little bit different
	posLastFrame = position + Vector2(10, 10)

func _physics_process(delta):
	self.linear_velocity += (totalSpringForce)/mass
	
	totalSpringForce = Vector2(0, 2)

func integrateForceFromOneSpring(F:Vector2):
	# Add the force to our velocity, but less force if the point is more massive
	linear_velocity += (F)/mass
	
	# If the point's linear_velocity is high, but it hasn't moved since last frame,
	# the linear_velocity is obviously wrong. Here, we set it to correctly reflect
	# the actual speed of the point.
	#if linear_velocity.length() > 400 and posLastFrame == position:
	#	linear_velocity = Vector2(0, 0)
	
	#print(linear_velocity)
	# Update this at the end of the function, so that next time we run through 
	# it will be the place we were at LAST frame
	posLastFrame = position
