extends Node2D

# Colors for each sand type
var sand_colors = {
	Global.SAND_EMPTY: Color(0, 0, 0, 0),
	Global.SAND_TYPE1: Color(1, 1, 1, 1),
	Global.SAND_TYPE2: Color(1, 0, 0, 1),
	Global.SAND_TYPE3: Color(0, 1, 0, 1)
}


# The image/texture used to display the simulation
var sand_texture = ImageTexture.new()
var sand_image = Image.create(Global.WIDTH, Global.HEIGHT, false, Image.FORMAT_RGBA8)

var image_data = PackedByteArray()
	
func _ready():
	image_data.resize(Global.WIDTH * Global.HEIGHT * 4)  # RGBA8 format: 4 bytes per pixel
	image_data.fill(0); 
	sand_texture.set_image(sand_image)

	var simulation = get_parent().get_node("SandSimulation")
	simulation.grid_updated.connect(_on_grid_updated)  # Listen for updates


func _draw():
	var screen_size = get_viewport_rect().size  # Get the screen resolution
	var texture_rect = Rect2(Vector2.ZERO, screen_size)  # Scale to full screen

	draw_texture_rect(sand_texture, texture_rect, false)  # "false" disables filtering
	
func _on_grid_updated(grids, active_grid):
	var updated_grid = grids[active_grid]
	for i in range(Global.WIDTH * Global.HEIGHT):
			
		var type = updated_grid[i]
		var color = Color(0, 0, 0, 0)#sand_colors.get(type, Color(0, 0, 0, 0))  # Default to transparent

		# Convert Color to byte format (RGBA)
		var r = int(color.r * 255)
		var g = int(color.g * 255)
		var b = int(color.b * 255)
		var a = int(color.a * 255)

		var index = i * 4
		image_data[index] = r
		image_data[index + 1] = g
		image_data[index + 2] = b
		image_data[index + 3] = a

	# Set the image data in one go
	sand_image.set_data(Global.WIDTH, Global.HEIGHT, false, Image.FORMAT_RGBA8, image_data)
	sand_texture.set_image(sand_image)
