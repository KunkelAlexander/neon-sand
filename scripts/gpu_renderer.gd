extends Node2D
# Shader materials
var shader_material = ShaderMaterial.new()
var type_texture = ImageTexture.new()
var color_palette_texture = ImageTexture.new()
var texture_rect: TextureRect
var type_image: Image
var width: int
var height: int 


func _ready():
	# Load the shadergodo
	var shader = load("res://shaders/glowing_sand_shader.gdshader")
	if shader == null:
		push_error("Failed to load sand shader!")
		return
	
	shader_material.shader = shader
	
	var screen_size = get_viewport_rect().size
	width = int(screen_size.x / Global.SIM_SCALE)
	height = int(screen_size.y / Global.SIM_SCALE)
	
	# Recreate image and texture and rebind it
	type_image   = Image.create(width, height, false, Image.FORMAT_R8)
	type_texture = ImageTexture.create_from_image(type_image)
	shader_material.set_shader_parameter("sand_texture", type_texture)
	shader_material.set_shader_parameter("simulation_resolution", Vector2(width, height))
	
	# Create color palette texture
	create_color_palette_texture()
	shader_material.set_shader_parameter("sand_colors", color_palette_texture)
	
	
	# Set up the TextureRect
	texture_rect = TextureRect.new()
	texture_rect.expand = true
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.texture = type_texture
	texture_rect.material = shader_material
	texture_rect.z_index = 0  # Any value higher than other siblings
	texture_rect.size = screen_size
	add_child(texture_rect)
	
	
	var simulation = get_parent().get_node("SandSimulation")
	# Notify it of size
	simulation.resize_simulation(width, height)
	
	_resize_simulation()
	
	# Connect to simulation for updates
	simulation.grid_updated.connect(_on_grid_updated)
	
	# Connect viewport resize event
	get_viewport().size_changed.connect(_resize_simulation)


func _resize_simulation():
	var screen_size = get_viewport_rect().size
	width = int(screen_size.x / Global.SIM_SCALE)
	height = int(screen_size.y / Global.SIM_SCALE)
	
	print("New simulation size: %dx%d" % [width, height])

	# Create low-res R8 image
	type_image = Image.create(width, height, false, Image.FORMAT_R8)

	# Create texture with nearest-neighbor filtering
	type_texture = ImageTexture.create_from_image(type_image)	
	shader_material.set_shader_parameter("sand_texture", type_texture)
	shader_material.set_shader_parameter("simulation_resolution", Vector2(width, height))

	# Update TextureRect
	texture_rect.texture = type_texture

	# Resize simulation grid
	var simulation = get_parent().get_node("SandSimulation")
	simulation.resize_simulation(width, height)

func create_color_palette_texture():
	var palette_size = 255
	var base_colors := []
	var num_base = 9
	
	randomize()
	var themes = ["sunset", "forest", "ocean", "night", "desert", "space", "random"]
	var theme = themes.pick_random()

	match theme:
		"sunset":
			base_colors = [
				Color.from_hsv(0.02, 0.8, 0.9),  # Warm orange
				Color.from_hsv(0.05, 0.9, 0.9),
				Color.from_hsv(0.08, 0.7, 0.95),
				Color.from_hsv(0.12, 0.5, 1.0),
				Color.from_hsv(0.65, 0.7, 0.9),
				Color.from_hsv(0.7, 0.8, 0.8),
				Color.from_hsv(0.75, 0.9, 0.6),
				Color.from_hsv(0.8, 1.0, 0.5),
				Color.from_hsv(0.02, 0.8, 0.9),  # Warm orange
			]
		"forest":
			base_colors = [
				Color.from_hsv(0.3, 0.8, 0.6),
				Color.from_hsv(0.33, 0.9, 0.4),
				Color.from_hsv(0.35, 0.7, 0.7),
				Color.from_hsv(0.1, 0.6, 0.5),
				Color.from_hsv(0.12, 0.5, 0.8),
				Color.from_hsv(0.58, 0.7, 0.7),
				Color.from_hsv(0.6, 0.6, 0.5),
				Color.from_hsv(0.15, 0.4, 0.3),
				Color.from_hsv(0.3, 0.8, 0.6),
			]
		"ocean":
			base_colors = [
				Color.from_hsv(0.5, 0.7, 0.9),
				Color.from_hsv(0.55, 0.8, 0.8),
				Color.from_hsv(0.6, 0.9, 0.7),
				Color.from_hsv(0.63, 1.0, 0.5),
				Color.from_hsv(0.58, 0.6, 0.8),
				Color.from_hsv(0.52, 0.7, 0.7),
				Color.from_hsv(0.6, 0.4, 0.9),
				Color.from_hsv(0.5, 0.8, 0.6),
				Color.from_hsv(0.5, 0.7, 0.9)
			]
		"night":
			base_colors = [
				Color.from_hsv(0.67, 0.9, 0.3),  # Deep blue
				Color.from_hsv(0.72, 0.8, 0.2),
				Color.from_hsv(0.75, 0.7, 0.4),
				Color.from_hsv(0.8, 0.6, 0.15),
				Color.from_hsv(0.85, 0.5, 0.1),
				Color.from_hsv(0.9, 0.3, 0.5),   # Purple
				Color.from_hsv(0.1, 0.9, 0.9),   # Stars (yellow)
				Color.from_hsv(0.65, 0.2, 0.8),  # Light blue
				Color.from_hsv(0.67, 0.9, 0.3)   # Deep blue (closing loop)
			]
		"desert":
			base_colors = [
				Color.from_hsv(0.08, 0.7, 0.8),  # Sandy orange
				Color.from_hsv(0.1, 0.8, 0.7),
				Color.from_hsv(0.05, 0.6, 0.9),
				Color.from_hsv(0.07, 0.5, 0.5),
				Color.from_hsv(0.09, 0.4, 0.4),
				Color.from_hsv(0.11, 0.3, 0.95), # Light tan
				Color.from_hsv(0.02, 0.8, 0.6),  # Terracotta
				Color.from_hsv(0.58, 0.7, 0.8),  # Sky blue
				Color.from_hsv(0.08, 0.7, 0.8)   # Sandy orange (closing loop)
			]
		"space":
			base_colors = [
				Color.from_hsv(0.7, 0.9, 0.1),   # Deep space blue
				Color.from_hsv(0.75, 0.8, 0.15),
				Color.from_hsv(0.8, 0.7, 0.2),   # Purple space
				Color.from_hsv(0.05, 0.9, 0.9),  # Star yellow
				Color.from_hsv(0.3, 0.8, 0.7),   # Nebula green
				Color.from_hsv(0.95, 0.7, 0.6),  # Nebula pink
				Color.from_hsv(0.6, 0.9, 0.3),   # Cosmic blue
				Color.from_hsv(0.15, 0.9, 0.9),  # Cosmic orange
				Color.from_hsv(0.7, 0.9, 0.1)    # Deep space blue (closing loop)
			]
		"random":
			# Create a completely random color palette
			base_colors = []
			var first_color = Color.from_hsv(randf(), randf_range(0.5, 1.0), randf_range(0.5, 1.0))
			base_colors.append(first_color)
			
			# Generate 7 more random colors
			for i in range(7):
				base_colors.append(Color.from_hsv(randf(), randf_range(0.5, 1.0), randf_range(0.5, 1.0)))
			
			# Close the loop with the first color
			base_colors.append(first_color)
		
	# Apply slight random variations to colors
	for i in range(num_base):
		var color = base_colors[i]
		var hue_shift = randf_range(-0.02, 0.02)
		var sat_shift = randf_range(-0.1, 0.1)
		var val_shift = randf_range(-0.1, 0.1)
		var h = clamp(color.h + hue_shift, 0.0, 1.0)
		var s = clamp(color.s + sat_shift, 0.0, 1.0)
		var v = clamp(color.v + val_shift, 0.0, 1.0)
		base_colors[i] = Color.from_hsv(h, s, v)

	var palette_image = Image.create(palette_size, 1, false, Image.FORMAT_RGBA8)
	for i in range(palette_size):
		var t = float(i) / (palette_size - 1) * (num_base - 1)
		var index = int(t)
		var frac = t - index

		var c1 = base_colors[index]
		var c2 = base_colors[min(index + 1, num_base - 1)]

		var interpolated = c1.lerp(c2, frac)
		palette_image.set_pixel(i, 0, interpolated)
	# Bloom will mix with this
	palette_image.set_pixel(0, 0, Color(1, 0, 0, 0))
	color_palette_texture = ImageTexture.create_from_image(palette_image)

func create_random_color_palette_texture():
	var palette_size = 255
	var palette_image = Image.create(palette_size, 1, false, Image.FORMAT_RGBA8)

	for i in range(palette_size):
		var t = float(i) / palette_size
		var color : Color

		# Randomize between pastel or neon
		if randi() % 2 == 0:
			# Pastel: hue + high lightness + low saturation
			var hue = randf()
			var sat = randf_range(0.2, 0.5)
			var val = randf_range(0.85, 1.0)
			color = Color.from_hsv(hue, sat, val)
		else:
			# Neon: bright + saturated colors
			var hue = randf()
			var sat = randf_range(0.9, 1.0)
			var val = randf_range(0.9, 1.0)
			color = Color.from_hsv(hue, sat, val)

		palette_image.set_pixel(i, 0, color)

	# Debug output
	for x in range(palette_size):
		var c = palette_image.get_pixel(x, 0)
		print("Palette index %d: %s" % [x, c])

	color_palette_texture = ImageTexture.create_from_image(palette_image)
	
func _on_grid_updated(grid):
	type_image.set_data(width, height, false, Image.FORMAT_R8, grid)
	type_texture.update(type_image)
