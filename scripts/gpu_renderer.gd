extends Node2D

# Shader materials
var shader_material = ShaderMaterial.new()
var type_texture = ImageTexture.new()
var color_palette_texture = ImageTexture.new()
var texture_rect: TextureRect
var type_image: Image
var simu_width: int
var simu_height: int 
var palette_names: Array[String] = []
var current_palette_index := 0
var current_palette_name := "magma"

@onready var palette_button: Button = get_tree().current_scene.get_node("UI/HUD/PaletteControls/PaletteButton")
@onready var palette_preview: TextureRect = get_tree().current_scene.get_node("UI/HUD/PaletteControls/PaletteButton/PalettePreview")

const COLORMAPS := {
	# --- Perceptual / scientific ---
	"viridis": [
		Color8(253, 231, 37),
		Color8(94, 201, 97),
		Color8(33, 145, 140),
		Color8(59, 82, 139),
		Color8(68, 1, 84),
	],
	"plasma": [
		Color8(252, 253, 191),
		Color8(249, 140, 10),
		Color8(191, 53, 131),
		Color8(139, 10, 165),
		Color8(84, 3, 160),
		Color8(13, 8, 135),
	],
	"inferno": [
		Color8(252, 255, 164),
		Color8(249, 140, 10),
		Color8(227, 89, 51),
		Color8(186, 54, 85),
		Color8(136, 34, 106),
		Color8(85, 15, 109),
		Color8(31, 12, 72),
		Color8(0, 0, 4),
	],
	"magma": [
		Color8(252, 253, 191),
		Color8(251, 135, 97),
		Color8(229, 80, 100),
		Color8(181, 54, 122),
		Color8(129, 37, 129),
		Color8(79, 18, 123),
		Color8(28, 16, 68),
		Color8(0, 0, 4),
	],
	"cividis": [
		Color8(255, 224, 128),
		Color8(192, 160, 96),
		Color8(128, 128, 128),
		Color8(64, 96, 128),
		Color8(0, 64, 128),
		Color8(0, 32, 76),
	],

	# --- Game / thermal / material ---
	"hot": [
		Color8(255, 255, 255),
		Color8(255, 200, 0),
		Color8(255, 80, 0),
		Color8(120, 0, 0),
		Color8(10, 0, 0),
	],
	"afmhot": [
		Color8(255, 255, 255),
		Color8(255, 200, 0),
		Color8(255, 60, 0),
		Color8(120, 0, 0),
		Color8(0, 0, 0),
	],
	"copper": [
		Color8(255, 200, 140),
		Color8(180, 120, 60),
		Color8(120, 70, 30),
		Color8(60, 30, 10),
		Color8(0, 0, 0),
	],
	"coolwarm": [
		Color8(180, 4, 38),
		Color8(240, 140, 120),
		Color8(220, 220, 220),
		Color8(120, 160, 220),
		Color8(59, 76, 192),
	],
	"berlin": [
		Color8(230, 220, 200),
		Color8(150, 170, 150),
		Color8(80, 120, 140),
		Color8(40, 60, 90),
		Color8(10, 10, 20),
	],
}


func _ready():
	# Load the shadergodo
	var shader = load("res://shaders/regular.gdshader")
	if shader == null:
		push_error("Failed to load sand shader!")
		return
	
	shader_material.shader = shader
	
	
	# Set up the TextureRect
	texture_rect              = TextureRect.new()
	texture_rect.expand       = true
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.material     = shader_material
	texture_rect.z_index      = 0  # Any value higher than other siblings0
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture_rect)
	
	_resize_simulation()
	
	# Create color palette texture
	setup_palette_button()
	create_color_palette_texture(current_palette_name)
	
	
	# Connect to simulation for updates
	var simulation = get_tree().current_scene.get_node("SandSimulation")
	simulation.grid_updated.connect(_on_grid_updated)
	
	# Connect viewport resize event
	get_tree().get_root().size_changed.connect(_resize_simulation)
	


func _resize_simulation():
	var screen_size = get_tree().get_root().size
	
	if screen_size.x >= 3000:
		Global.SIM_SCALE = 8
	elif screen_size.x >= 1800:
		Global.SIM_SCALE = 6
	else:
		Global.SIM_SCALE = 4

	print("SIM_SCALE is now ", Global.SIM_SCALE)

	print("Sand renderer updated with screen size ", screen_size)
	simu_width  = int(screen_size.x / Global.SIM_SCALE)
	simu_height = int(screen_size.y / Global.SIM_SCALE)
	print("Sand renderer updated with simu size ", simu_width, "x", simu_height)

	# Create low-res R8 image
	type_image = Image.create(simu_width, simu_height, false, Image.FORMAT_R8)

	# Create texture with nearest-neighbor filtering
	type_texture = ImageTexture.create_from_image(type_image)	
	shader_material.set_shader_parameter("sand_texture", type_texture)
	shader_material.set_shader_parameter("simulation_resolution", Vector2(simu_width, simu_height))

	# Update TextureRect
	texture_rect.texture = type_texture
	texture_rect.size    = screen_size

	# Resize simulation grid
	print("Simulation resized to ", simu_width, "x", simu_height)
	var simulation = get_tree().current_scene.get_node("SandSimulation")
	simulation.resize_simulation(simu_width, simu_height)
	
func create_color_palette_texture(map_name: String):
	var palette_size := 256


	if not COLORMAPS.has(map_name):
		push_warning("Unknown palette '%s', falling back to magma." % map_name)
		map_name = "magma"
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
	shader_material.set_shader_parameter("sand_colors", color_palette_texture)
	
	current_palette_name = map_name
	update_palette_preview()
	
func _on_grid_updated(grid):
	type_image.set_data(simu_width, simu_height, false, Image.FORMAT_R8, grid)
	type_texture.update(type_image)

func setup_palette_button():
	print("setup palette button")
	palette_names.assign(COLORMAPS.keys())
	palette_names.sort()

	current_palette_index = palette_names.find(current_palette_name)

	if current_palette_index == -1:
		current_palette_index = 0
		current_palette_name = palette_names[current_palette_index]

	palette_button.pressed.connect(_on_palette_button_pressed)
	update_palette_preview()
	
func _on_palette_button_pressed():

	if palette_names.is_empty():
		push_error("No palettes found.")
		return

	current_palette_index = wrapi(current_palette_index + 1, 0, palette_names.size())
	create_color_palette_texture(palette_names[current_palette_index])
	
func update_palette_preview():
	palette_preview.texture = create_palette_preview_texture(current_palette_name)

	
	
func create_palette_preview_texture(map_name: String, width := 160, height := 40) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)

	for x in range(width):
		var t := float(x) / float(width - 1)
		var base_color := sample_palette_color(map_name, t)

		for y in range(height):
			var y_t := float(y) / float(height - 1)
			var color := base_color

			# Soft top highlight.
			if y_t < 0.35:
				color = color.lerp(Color.WHITE, 0.16 * (1.0 - y_t / 0.35))

			# Soft bottom shade.
			if y_t > 0.65:
				color = color.lerp(Color.BLACK, 0.14 * ((y_t - 0.65) / 0.35))

			image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)

func sample_palette_color(map_name: String, t: float) -> Color:
	if not COLORMAPS.has(map_name):
		map_name = "magma"

	var anchors: Array = COLORMAPS[map_name]
	var num_anchors := anchors.size()

	var scaled = clamp(t, 0.0, 1.0) * float(num_anchors - 1)
	var index := int(scaled)
	var frac = scaled - float(index)

	var c1: Color = anchors[index]
	var c2: Color = anchors[min(index + 1, num_anchors - 1)]

	return c1.lerp(c2, frac)
