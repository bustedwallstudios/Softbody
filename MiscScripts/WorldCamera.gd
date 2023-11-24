extends Camera2D

var is_panning: bool = false
var initial_mouse_pos: Vector2
var current_zoom: float = 1.0
var target_zoom: float = 1.0
var lerpSpeed          = 20

@export var initial_zoom: float = 0.25
@export var zoom_speed: float = 0.25
@export var min_zoom: float = 0.1
@export var max_zoom: float = 5.0

func _ready():
	self.target_zoom  = initial_zoom
	self.current_zoom = initial_zoom

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.is_pressed():
				is_panning = true
				initial_mouse_pos = event.position
			else:
				is_panning = false
		
		# Depending on the direction of scroll, zoom in or out.
		if event.button_index   == MOUSE_BUTTON_WHEEL_UP:   target_zoom *= 1.0 + zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: target_zoom /= 1.0 + zoom_speed
		
		
		target_zoom = clamp(target_zoom, min_zoom, max_zoom) # current_zoom - zoomDelta

func _process(delta: float):
	if is_panning:
		var current_mouse_pos = get_viewport().get_mouse_position()
		var delta_pos = (initial_mouse_pos - current_mouse_pos) / zoom.x
		
		offset += delta_pos
		initial_mouse_pos = current_mouse_pos
	
	# Smoothly interpolate the zoom
	current_zoom = lerp(current_zoom, target_zoom, delta * lerpSpeed)
	zoom = Vector2(current_zoom, current_zoom)
