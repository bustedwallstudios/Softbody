extends Camera2D

@export (float, 5, 50) var spd = 20

func _physics_process(delta):
	if Input.is_action_pressed("camUp"):
		self.position.y -= spd
	if Input.is_action_pressed("camDown"):
		self.position.y += spd
	if Input.is_action_pressed("camRight"):
		self.position.x += spd
	if Input.is_action_pressed("camLeft"):
		self.position.x -= spd
