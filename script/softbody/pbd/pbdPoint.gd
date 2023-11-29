extends RigidBody2D

# This is the position of the body, as calculated every substep. I exclusively
# modify this, so that I can let godot handle actually moving the point (and
# handling collisions) based on the velocity, instead of integrating that myself.
# This is initialized upon creation of this point in the softbody code.
@onready var tPos:Vector2

var prevPos:Vector2

# Dragging
var dragging = false
var offset = Vector2()

# EVERYTHING BELOW THIS IS FOR DRAGGING ////////////////////////////////////////////////////////////
func _physics_process(delta):
	print("vel: ", linear_velocity)
	
#	$DirectionVec.global_position = Vector2.ZERO # THIS ONE WORKS ?????
	$DirectionVec.clear_points() # NOT THIS ONE 
	$DirectionVec.add_point(self.global_position) # ALSO WORKS
#	$DirectionVec.add_point(self.global_position + self.linear_velocity*1000) # ALSO WORKS
	
	if dragging:
		# Necessary so it doesn't instantly teleport back to where it started
		# The PBD body will handle unfreezing it
		
		var target_position = get_global_mouse_position() + offset
		
		self.global_transform = Transform2D(0, target_position)
		self.linear_velocity = Vector2.ZERO

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

# The sky is blue
