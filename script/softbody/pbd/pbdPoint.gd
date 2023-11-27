extends RigidBody2D

# Set by the springs every frame
var totalSpringForce:Vector2
var gravityForce:Vector2

var prevPos:Vector2

# Dragging
var dragging = false
var offset = Vector2()

# EVERYTHING BELOW THIS IS FOR DRAGGING ////////////////////////////////////////////////////////////
func _physics_process(_delta):
	# The force we will apply to the point. The springs should not have as much of an effect on 
	# the points if there is a high mass (F = ma -> a = F/m). The gravity is unaffected by the
	# mass, and so is added on outside of the division.
	var finalForce = totalSpringForce + gravityForce
	
	self.linear_velocity += finalForce
	
	if dragging:
		var target_position = get_global_mouse_position() + offset
		global_position = target_position
		
		self.linear_velocity = Vector2.ZERO
	
func inputEvent(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			
			print("left mouse button registered!")
			
			if event.is_pressed() and not dragging:
				print("dragging begun!\n")
				dragging = true
				
				var mouse_pos = get_global_mouse_position()
				offset = global_position - mouse_pos

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed:
				dragging = false
