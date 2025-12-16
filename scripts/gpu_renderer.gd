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
	var shader = load("res://shaders/sand_shader.gdshader")
	if shader == null:
		push_error("Failed to load sand shader!")
		return
	
	shader_material.shader = shader
	
	var screen_size = get_tree().get_root().size
	
	print("Reading screen size: ", screen_size)
	width  = int(screen_size.x / Global.SIM_SCALE)
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
	
	
	# Notify the simulation of its size
	var simulation = get_tree().current_scene.get_node("SandSimulation")
	simulation.resize_simulation(width, height)

	# Connect to simulation for updates
	simulation.grid_updated.connect(_on_grid_updated)
	# Connect viewport resize event
	_resize_simulation()
	get_tree().get_root().size_changed.connect(_resize_simulation)
	


func _resize_simulation():
	var screen_size = get_tree().get_root().size
	width = int(screen_size.x / Global.SIM_SCALE)
	height = int(screen_size.y / Global.SIM_SCALE)
	print("Changed size to ", screen_size)

	# Create low-res R8 image
	type_image = Image.create(width, height, false, Image.FORMAT_R8)

	# Create texture with nearest-neighbor filtering
	type_texture = ImageTexture.create_from_image(type_image)	
	shader_material.set_shader_parameter("sand_texture", type_texture)
	shader_material.set_shader_parameter("simulation_resolution", Vector2(width, height))

	# Update TextureRect
	texture_rect.texture = type_texture
	texture_rect.size    = screen_size

	# Resize simulation grid
	var simulation = get_tree().current_scene.get_node("SandSimulation")
	simulation.resize_simulation(width, height)
	
func create_color_palette_texture():
	var palette_size := 256

	const COLORMAPS := {
		# --- Perceptual / scientific ---
		"viridis": [
			Color8(68, 1, 84),
			Color8(59, 82, 139),
			Color8(33, 145, 140),
			Color8(94, 201, 97),
			Color8(253, 231, 37),
		],
		"plasma": [
			Color8(13, 8, 135),
			Color8(84, 3, 160),
			Color8(139, 10, 165),
			Color8(191, 53, 131),
			Color8(249, 140, 10),
			Color8(252, 253, 191),
		],
		"inferno": [
			Color8(0, 0, 4),
			Color8(31, 12, 72),
			Color8(85, 15, 109),
			Color8(136, 34, 106),
			Color8(186, 54, 85),
			Color8(227, 89, 51),
			Color8(249, 140, 10),
			Color8(252, 255, 164),
		],
		"magma": [
			Color8(0, 0, 4),
			Color8(28, 16, 68),
			Color8(79, 18, 123),
			Color8(129, 37, 129),
			Color8(181, 54, 122),
			Color8(229, 80, 100),
			Color8(251, 135, 97),
			Color8(252, 253, 191),
		],
		"cividis": [
			Color8(0, 32, 76),
			Color8(0, 64, 128),
			Color8(64, 96, 128),
			Color8(128, 128, 128),
			Color8(192, 160, 96),
			Color8(255, 224, 128),
		],

		# --- Game / thermal / material ---
		"hot": [
			Color8(10, 0, 0),
			Color8(120, 0, 0),
			Color8(255, 80, 0),
			Color8(255, 200, 0),
			Color8(255, 255, 255),
		],
		"afmhot": [
			Color8(0, 0, 0),
			Color8(120, 0, 0),
			Color8(255, 60, 0),
			Color8(255, 200, 0),
			Color8(255, 255, 255),
		],
		"copper": [
			Color8(0, 0, 0),
			Color8(60, 30, 10),
			Color8(120, 70, 30),
			Color8(180, 120, 60),
			Color8(255, 200, 140),
		],
		"coolwarm": [
			Color8(59, 76, 192),
			Color8(120, 160, 220),
			Color8(220, 220, 220),
			Color8(240, 140, 120),
			Color8(180, 4, 38),
		],
		"berlin": [
			Color8(10, 10, 20),
			Color8(40, 60, 90),
			Color8(80, 120, 140),
			Color8(150, 170, 150),
			Color8(230, 220, 200),
		]
	}

	randomize()
	var map_name: String = COLORMAPS.keys().pick_random() as String
	var anchors: Array = COLORMAPS[map_name]
	var num_anchors := anchors.size()

	var palette_image := Image.create(palette_size, 1, false, Image.FORMAT_RGBA8)

	# Index 0: transparent black (empty cell / air)
	palette_image.set_pixel(0, 0, Color(0, 0, 0, 0))

	for i in range(1, palette_size):
		var t := float(i) / float(palette_size - 1)
		var scaled := t * (num_anchors - 1)
		var index := int(scaled)
		var frac := scaled - index

		var c1: Color = anchors[index]
		var c2: Color = anchors[min(index + 1, num_anchors - 1)]

		var color := c1.lerp(c2, frac)
		palette_image.set_pixel(i, 0, color)

	color_palette_texture = ImageTexture.create_from_image(palette_image)

func _on_grid_updated(grid):
	type_image.set_data(width, height, false, Image.FORMAT_R8, grid)
	type_texture.update(type_image)
