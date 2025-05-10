extends Node2D

@onready var sand_sim = $"../SandSimulation"  # Reference the sand simulation node
@onready var ui_root = $"../CanvasLayer/UI"
@onready var base_resolution = Vector2(800, 600)  # Your designed reference size

var sand_type = 0
var time_passed := 0.0
var brush_size: float = 30.0
var paint_mode: bool = true

# Track touch points' positions and previous distances
var last_touch_distance := 0.0

# Track touch points for pinch-to-zoom
var touch_positions = {}
var min_brush_size = 5.0
var max_brush_size = 50.0
var pinch_sensitivity = 0.5  # Adjust this to control sensitivity

# Initialize variables for pinch gesture handling
var last_gesture_scale := 1.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)  # Hide default cursor

	var viewport = get_viewport()
	viewport.connect("size_changed", Callable(self, "_on_viewport_resized"))
	_on_viewport_resized()  # Trigger once initially

			
func _on_viewport_resized():
	var new_size = get_viewport().size
	var scale = min(new_size.x / base_resolution.x, new_size.y / base_resolution.y)
	ui_root.scale = Vector2(scale, scale)


func _process(delta):
	time_passed += delta

	# Smooth cycle from 0 to 254 over 10 seconds (adjust speed as needed)
	sand_type = int(time_passed * 25) % 252 + 2

	# Update cursor position
	position = get_global_mouse_position()

	# Adjust cursor size with mouse wheel
	if Input.is_action_just_pressed("scroll_up"):
		brush_size = min(brush_size + 2, 50)
		queue_redraw()
	elif Input.is_action_just_pressed("scroll_down"):
		brush_size = max(brush_size - 2, 5)
		queue_redraw()

	# Create sand particles when left mouse button is pressed
	if Input.is_action_pressed("left_click"):
		sand_sim.spawn_sand(position/Global.SIM_SCALE, brush_size, sand_type)

	if Input.is_action_pressed("right_click"):
		sand_sim.spawn_sand(position/Global.SIM_SCALE, brush_size, Global.SAND_EMPTY)

	if Input.is_action_pressed("key_exit"):
		get_tree().quit()

func _input(event):
	# Handle mouse wheel for brush size adjustment
	if event is InputEventScreenTouch:
		handle_touch(event)


func adjust_brush_size(amount):
	brush_size = clamp(brush_size + amount, min_brush_size, max_brush_size)
	queue_redraw()

func handle_touch(event: InputEventScreenTouch):
	if event.pressed:
		# Store the touch position when pressed
		touch_positions[event.index] = event.position
		
		# If we have exactly 2 touches after adding this touch, capture initial distance
		if touch_positions.size() == 2:
			var positions = touch_positions.values()
			last_touch_distance = positions[0].distance_to(positions[1])
	else:
		touch_positions[event.index] = event.position
		# Before removing the touch position
		# If we have exactly 2 touches before removal and we're releasing one of them
		if touch_positions.size() == 2:
			var positions = touch_positions.values()
			var current_distance = positions[0].distance_to(positions[1])
			
			# Calculate pinch scale and adjust brush size
			if last_touch_distance > 0:
				var distance_delta = current_distance - last_touch_distance
			
				var size_change = distance_delta * pinch_sensitivity
				adjust_brush_size(size_change)
		
		# Remove the touch position when released
		touch_positions.erase(event.index)
		
		# Reset last distance if we don't have 2 touches anymore
		if touch_positions.size() != 2:
			last_touch_distance = 0.0
func _draw():
	draw_circle(Vector2.ZERO, brush_size*Global.SIM_SCALE, Color(1, 1, 1), false)
