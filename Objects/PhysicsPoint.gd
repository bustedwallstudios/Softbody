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
	
	self.angular_velocity = 0
	self.rotation_degrees = 0
	
	totalSpringForce = Vector2(0, 2)
