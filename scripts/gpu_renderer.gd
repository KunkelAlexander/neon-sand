extends Node2D

# Colors for each sand type
var sand_colors = {
	Global.SAND_EMPTY: Color(0, 0, 0, 0),
	Global.SAND_TYPE1: Color(1, 1, 1, 1),
	Global.SAND_TYPE2: Color(1, 0, 0, 1),
	Global.SAND_TYPE3: Color(0, 1, 0, 1)
}

# Shader materials
var shader_material = ShaderMaterial.new()
var type_texture = ImageTexture.new()
var color_palette_texture = ImageTexture.new()
var texture_rect: TextureRect
var type_image: Image
var width: int
var height: int 

# For tracking performance
var profiler_enabled = true

func _ready():
	# Load the shadergodo
	var shader = load("res://shaders/sand_shader.gdshader")
	if shader == null:
		push_error("Failed to load sand shader!")
		return
	
	shader_material.shader = shader
	
	var size = get_viewport_rect().size
	width  = size.x
	height = size.y 
	
	# Recreate image and texture and rebind it
	type_image   = Image.create(width, height, false, Image.FORMAT_R8)
	type_texture = ImageTexture.create_from_image(type_image)
	shader_material.set_shader_parameter("sand_texture", type_texture)
	
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
	texture_rect.size = size
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
	print("Pardur")
	var new_size = get_viewport().get_visible_rect().size
	var new_width = int(new_size.x)
	var new_height = int(new_size.y)
	width  = new_width
	height = new_height

	print("Resizing simulation to ", new_width, "x", new_height)

	# Recreate image and texture and rebind it
	type_image   = Image.create(new_width, new_height, false, Image.FORMAT_R8)
	type_texture = ImageTexture.create_from_image(type_image)
	shader_material.set_shader_parameter("sand_texture", type_texture)

	# Resize the display rect
	texture_rect.size = new_size
	texture_rect.texture = type_texture

	# Notify simulation
	var simulation = get_parent().get_node("SandSimulation")
	simulation.resize_simulation(new_width, new_height)


func create_color_palette_texture():
	var palette_size = 255
	var base_colors := []
	var num_base = 8  # Number of control colors

	# Generate base pastel/neon colors
	for i in range(num_base):
		var hue = randf()
		var sat = randf_range(0.4, 1.0)
		var val = randf_range(0.8, 1.0)
		base_colors.append(Color.from_hsv(hue, sat, val))
	base_colors[0].a = 0.0
	
	var palette_image = Image.create(palette_size, 1, false, Image.FORMAT_RGBA8)

	for i in range(palette_size):
		var t = float(i) / (palette_size - 1) * (num_base - 1)
		var index = int(t)
		var frac = t - index

		var c1 = base_colors[index]
		var c2 = base_colors[min(index + 1, num_base - 1)]

		var interpolated = c1.lerp(c2, frac)
		palette_image.set_pixel(i, 0, interpolated)

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
	
func create_fixed_color_palette_texture():
	var max_type = 0
	for type in sand_colors.keys():
		max_type = max(max_type, type)

	var palette_image = Image.create(max_type + 1, 1, false, Image.FORMAT_RGBA8)

	for type in sand_colors:
		palette_image.set_pixel(type, 0, sand_colors[type])
		
	for x in range(palette_image.get_width()):
		var c = palette_image.get_pixel(x, 0)
		print("Palette index %d: %s" % [x, c])
	
	color_palette_texture = ImageTexture.create_from_image(palette_image)


func _on_grid_updated(grid):
	type_image.set_data(width, height, false, Image.FORMAT_R8, grid)
	type_texture.update(type_image)
