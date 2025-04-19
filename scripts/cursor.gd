extends Node2D

@onready var sand_sim = $"../SandSimulation"  # Reference the sand simulation node
@onready var ui_root = $"../CanvasLayer/UI"
@onready var base_resolution = Vector2(800, 600)  # Your designed reference size

var sand_type = 0
var time_passed := 0.0
var brush_size: float = 30.0
var paint_mode: bool = true

# Track touch points' positions and previous distances
var touch_positions := {}
var last_touch_distance := 0.0

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
	sand_type = int(time_passed * 50) % 252 + 2

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

func _draw():
	draw_circle(Vector2.ZERO, brush_size*Global.SIM_SCALE, Color(1, 1, 1), false)
