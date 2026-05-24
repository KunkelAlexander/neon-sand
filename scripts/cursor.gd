extends Node2D

@onready var sand_sim = $"../SandSimulation"

var sand_type = 0
var time_passed := 0.0
var brush_size: float = 30.0
var paint_mode: bool = true

# Track touch points' positions and previous distances
var last_touch_distance := 0.0

# Track touch points for pinch-to-zoom
var touch_positions = {}
var min_brush_size = 1.0
var max_brush_size = 50.0
var pinch_sensitivity = 0.5  # Adjust this to control sensitivity
var density = 0.5


# Double-tap detection
var last_tap_time := 0.0
var last_tap_pos := Vector2.ZERO
var double_tap_max_time := 1.0      # seconds
var double_tap_max_distance := 30.0 # pixels

var double_tap_active := false

# Initialize variables for pinch gesture handling
var last_gesture_scale := 1.0

# Draw title
var startup_drawing := true
var startup_points: Array[Vector2] = []
var startup_point_index := 0
var startup_progress := 0.0

var startup_title_width := 360.0
var startup_brush_size := 1.0
var startup_steps_per_frame := 200

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)  # Hide default cursor
	build_startup_title_points()
	
		
func build_startup_title_points():
	startup_points = [
		# NEON
		Vector2(0, 50), Vector2(0, 0), Vector2(45, 50), Vector2(45, 0), # N

		Vector2(70, 50), Vector2(110, 50),
		Vector2(70, 25), Vector2(105, 25),
		Vector2(70, 0), Vector2(110, 0), # E

		Vector2(150, 0), Vector2(190, 0), Vector2(205, 25),
		Vector2(190, 50), Vector2(150, 50), Vector2(135, 25),
		Vector2(150, 0), # O

		Vector2(235, 50), Vector2(235, 0), Vector2(280, 50), Vector2(280, 0), # N

		# SAND, second line
		Vector2(0, 125), Vector2(40, 125),
		Vector2(40, 100), Vector2(0, 100),
		Vector2(0, 75), Vector2(40, 75), # S

		Vector2(70, 125), Vector2(90, 75), Vector2(110, 125),
		Vector2(80, 105), Vector2(105, 105), # A

		Vector2(140, 125), Vector2(140, 75), Vector2(185, 125), Vector2(185, 75), # N

		Vector2(220, 75), Vector2(220, 125),
		Vector2(260, 120), Vector2(275, 100),
		Vector2(260, 80), Vector2(220, 75) # D
	]
		
func _process(delta):
	time_passed += delta

	if startup_drawing:
		draw_startup_title(delta)
		return
		
	# Smooth cycle from 0 to 254 (adjust speed as needed)
	sand_type = int(time_passed * 10) % 252 + 2

	# Update cursor position
	# This is screen space, but the sand simulation wants world-space
	position = get_global_mouse_position()

	# Adjust cursor size with mouse wheel
	if Input.is_action_just_pressed("scroll_up"):
		brush_size = min(brush_size + 2, max_brush_size)
		queue_redraw()
	elif Input.is_action_just_pressed("scroll_down"):
		brush_size = max(brush_size - 2, min_brush_size)
		queue_redraw()
		
		
	# Create sand particles when left mouse button is pressed

	if Input.is_action_pressed("right_click") or double_tap_active:
		sand_sim.spawn_sand(position/Global.SIM_SCALE, brush_size, Global.SAND_EMPTY, density)
	elif Input.is_action_pressed("left_click"):
		sand_sim.spawn_sand(position/Global.SIM_SCALE, brush_size, sand_type, density)


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
		var now := Time.get_ticks_msec() / 1000.0

		# --- Double tap detection ---
		if (
			now - last_tap_time <= double_tap_max_time
			and event.position.distance_to(last_tap_pos) <= double_tap_max_distance
		):
			double_tap_active = true
		else:
			double_tap_active = false

		last_tap_time = now
		last_tap_pos = event.position

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


		# Stop double-tap action on release
		double_tap_active = false
func _draw():
	draw_circle(Vector2.ZERO, brush_size*Global.SIM_SCALE, Color(1, 1, 1), false)

func draw_startup_title(delta):
	if startup_point_index >= startup_points.size() - 1:
		startup_drawing = false
		return

	var screen_width := get_viewport_rect().size.x
	var center_offset := Vector2((screen_width - startup_title_width) * 0.6, 0)

	for i in startup_steps_per_frame:
		if startup_point_index >= startup_points.size() - 1:
			startup_drawing = false
			return

		var from := startup_points[startup_point_index]
		var to := startup_points[startup_point_index + 1]

		var segment_length := from.distance_to(to)

		if segment_length <= 0.01:
			startup_point_index += 1
			startup_progress = 0.0
			continue

		# Lower number = denser line.
		# Higher number = fewer particles.
		startup_progress += 3.0 / segment_length

		var draw_pos := from.lerp(to, startup_progress)

		# Center the whole 360px title.
		draw_pos += center_offset

		var startup_sand_type := int((time_passed * 20.0) + i) % 252 + 2

		sand_sim.spawn_sand(
			draw_pos / Global.SIM_SCALE,
			startup_brush_size,
			startup_sand_type,
			1.0
		)

		if startup_progress >= 1.0:
			startup_point_index += 1
			startup_progress = 0.0
