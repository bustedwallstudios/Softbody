extends RigidBody2D

func _integrate_forces(state):
	if Input.is_action_just_pressed("bigBall"): # If the player should go back to the start
		state.transform = Transform2D(self.rotation_degrees, get_global_mouse_position())
		self.linear_velocity  = Vector2()
		self.angular_velocity = 0
	
	if Input.is_action_just_pressed("ui_left"): # If the player should go back to the start
		self.linear_velocity += Vector2(-100, 0)
	
	if Input.is_action_just_pressed("ui_right"): # If the player should go back to the start
		self.linear_velocity += Vector2(100, 0)
