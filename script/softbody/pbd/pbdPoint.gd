extends RigidBody2D

#var mass:float = 0
var wass:float = 0

var velocity:Vector2

var prevPos:Vector2

# Dragging
var dragging = false
var offset = Vector2()

# EVERYTHING BELOW THIS IS FOR DRAGGING ////////////////////////////////////////////////////////////
func _physics_process(delta):
	self.freeze = true
	if dragging:
		# Necessary so it doesn't instantly teleport back to where it started
		# The PBD body will handle unfreezing it
		
		var target_position = get_global_mouse_position() + offset
		
		self.global_transform = Transform2D(0, target_position)
		self.velocity = Vector2.ZERO

func inputEvent(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			
			#print("left mouse button registered!")
			
			if event.is_pressed() and not dragging:
				#print("dragging begun!\n")
				dragging = true
				
				var mouse_pos = get_global_mouse_position()
				offset = global_position - mouse_pos

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed:
				dragging = false
