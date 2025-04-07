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

# For tracking performance
var profiler_enabled = true

func _ready():
	# Load the shader
	var shader = load("res://shaders/sand_shader.gdshader")
	if shader == null:
		push_error("Failed to load sand shader!")
		return
		
	shader_material.shader = shader
	
	# Create initial type texture (this will store sand types)
	var type_image = Image.create(Global.WIDTH, Global.HEIGHT, false, Image.FORMAT_R8)
	type_texture = ImageTexture.create_from_image(type_image)
	
	# Create color palette texture
	create_color_palette_texture()
	
	# Pass textures to shader
	shader_material.set_shader_parameter("sand_texture", type_texture)
	shader_material.set_shader_parameter("sand_colors", color_palette_texture)
	
	# Set up the TextureRect
	texture_rect = TextureRect.new()
	texture_rect.expand = true
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.texture = type_texture
	texture_rect.material = shader_material
	texture_rect.z_index = 100  # Any value higher than other siblings
	texture_rect.size = Vector2(1200, 800)
	add_child(texture_rect)

	
	# Connect to simulation for updates
	var simulation = get_parent().get_node("SandSimulation")
	simulation.grid_updated.connect(_on_grid_updated)

func create_color_palette_texture():
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


func _on_grid_updated(grids, active_grid):
	var updated_grid = grids[active_grid]

	var type_image = Image.create(Global.WIDTH, Global.HEIGHT, false, Image.FORMAT_R8)

	var data = PackedByteArray()
	data.resize(Global.WIDTH * Global.HEIGHT)

	for i in range(Global.WIDTH * Global.HEIGHT):
		data[i] = int(updated_grid[i] / 3.0 * 255)

	type_image.set_data(Global.WIDTH, Global.HEIGHT, false, Image.FORMAT_R8, data)
	type_texture.update(type_image)
