extends RigidBody2D

# Set by the springs every frame
var totalSpringForce:Vector2
var gravityForce:Vector2

# Dragging
var dragging = false
var offset = Vector2()

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
	var finalForce = totalSpringForce + gravityForce
	
	self.linear_velocity += finalForce
	
	if doTint:
		# The color range: the higher absoluteForce, the closer to 0 the result is, and the closer to red
		# the point becomes.
		var tint = 1/(absoluteForce/100)
		
		$Marker.color = Color(1, tint, tint)
	
	# Reset this to 0 for next frame
	totalSpringForce = Vector2.ZERO
	absoluteForce = 0.01
	
	if dragging:
		self.freeze = true # Necessary so it doesn't instantly teleport back to
		# where it started
		var target_position = get_global_mouse_position() + offset
		
		self.global_transform = Transform2D(0, target_position)
		
		self.linear_velocity = Vector2.ZERO
	else:
		self.freeze = false

# Called by the spring
func applySpringForce(f):
	# For the tint
	absoluteForce += f.length()
	
	totalSpringForce += f

# EVERYTHING BELOW THIS IS FOR DRAGGING ////////////////////////////////////////////////////////////

func inputEvent(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			
			if event.is_pressed() and not dragging:
				dragging = true
				
				var mouse_pos = get_global_mouse_position()
				offset = global_position - mouse_pos

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed:
				dragging = false
