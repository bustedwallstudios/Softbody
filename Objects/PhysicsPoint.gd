extends RigidBody2D

# Set by the spring every frame
var springForce:Vector2

func integrateForceFromOneSpring(F:Vector2):
	self.linear_velocity += (F)/mass
