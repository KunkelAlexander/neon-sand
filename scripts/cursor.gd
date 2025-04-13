extends Node2D

var cursor_size: float = 30.0
@onready var sand_sim = $"../SandSimulation"  # Reference the sand simulation node
var sand_type = 0
var time_passed := 0.0

# Track touch points' positions and previous distances
var touch_positions := {}
var last_touch_distance := 0.0

# Initialize variables for pinch gesture handling
var last_gesture_scale := 1.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)  # Hide default cursor


func grid_to_screen(coordinate: float) -> float:
	var screen_size = get_viewport_rect().size
	var scale_x = float(Global.WIDTH) / screen_size.x
	return int(coordinate*scale_x)

func screen_to_grid(mouse_pos: Vector2) -> Vector2i:
	var screen_size = get_viewport_rect().size
	var scale_x = float(Global.WIDTH) / screen_size.x
	var scale_y = float(Global.HEIGHT) / screen_size.y
	return Vector2i(int(mouse_pos.x * scale_x), int(mouse_pos.y * scale_y))

func _process(delta):
	time_passed += delta

	# Smooth cycle from 0 to 254 over 10 seconds (adjust speed as needed)
	sand_type = int(time_passed * 25.5) % 255

	# Update cursor position
	position = get_global_mouse_position()

	# Adjust cursor size with mouse wheel
	if Input.is_action_just_pressed("scroll_up"):
		cursor_size = min(cursor_size + 2, 50)
		queue_redraw()
	elif Input.is_action_just_pressed("scroll_down"):
		cursor_size = max(cursor_size - 2, 5)
		queue_redraw()

	# Create sand particles when left mouse button is pressed
	if Input.is_action_pressed("left_click"):
		var grid_pos = screen_to_grid(position)
		var radius = grid_to_screen(cursor_size)
		sand_sim.spawn_sand(grid_pos, radius, sand_type)

	if Input.is_action_pressed("right_click"):
		var grid_pos = screen_to_grid(position)
		var radius = grid_to_screen(cursor_size)
		sand_sim.spawn_sand(grid_pos, radius, Global.SAND_EMPTY)

	if Input.is_action_pressed("key_exit"):
		get_tree().quit()

			


func _draw():
	draw_circle(Vector2.ZERO, cursor_size, Color(1, 1, 1), false)


func _on_sand_simulation_grid_updated(old_grid: Variant, new_grid: Variant) -> void:
	pass # Replace with function body.
