extends RigidBody2D

var prevPos = Vector2()
var pos = Vector2()

func _process(delta):
	pos = self.position
	print(delta)
	print(pos - prevPos)
	prevPos = self.position
	
