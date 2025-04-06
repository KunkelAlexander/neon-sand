extends Node

signal grid_updated(old_grid, new_grid)  # Signal to notify renderer

# Sand type definitions
const SAND_EMPTY = 0
const SAND_TYPE1 = 1  # e.g. white sand
const SAND_TYPE2 = 2  # e.g. red sand
const SAND_TYPE3 = 3  # e.g. green sand
# (Add more types as needed)

# Colors for each sand type
var sand_colors = {
	SAND_EMPTY: Color(0, 0, 0, 0),
	SAND_TYPE1: Color(1, 1, 1, 1),
	SAND_TYPE2: Color(1, 0, 0, 1),
	SAND_TYPE3: Color(0, 1, 0, 1)
}

# The grid stores an integer per pixel (0 = empty, otherwise the sand type)
var sand_grids = [PackedByteArray(), PackedByteArray()]
var active_grid = 0 

# List of indices (in the grid) that where added
var active_pixels = []

	
func _ready():
	for grid in sand_grids:
		grid.resize(Global.WIDTH * Global.HEIGHT)
		grid.fill(SAND_EMPTY)
	active_grid = 0 
	
func _process(delta):
	update_sand()
	grid_updated.emit(sand_grids, active_grid)  # Notify renderer


func update_sand():
	# We'll read from the "active_grid" buffer,
	# and write into the other buffer.
	var read_grid = sand_grids[active_grid]
	var write_grid = sand_grids[1 - active_grid]

	# 1) Clear the next frame's buffer so everything is empty initially.
	for i in range(write_grid.size()):
		write_grid[i] = SAND_EMPTY

	# 2) If you just placed new pixels this frame, put them in the *read* buffer
	#    so the simulation sees them immediately.
	for pos_type in active_pixels:
		var index        = pos_type[0]
		var sand_type    = pos_type[1]
		read_grid[index] = sand_type
	active_pixels.clear()

			
	# 3) Simulation: read from the old buffer, write results into the new.
	for y in range(Global.HEIGHT - 1, -1, -1): # from bottom up or second-to-last row is also common
		for x in range(Global.WIDTH):
			var pos = x + y * Global.WIDTH
			var current_type = read_grid[pos]
			if current_type == SAND_EMPTY:
				continue

			# Check the cell below in the old (read_grid)
			if y < Global.HEIGHT - 1:
				var below_idx = x + (y + 1) * Global.WIDTH
				if read_grid[below_idx] == SAND_EMPTY:
					# Move down
					write_grid[below_idx] = current_type
					continue
				else:
					# Check diagonals
					var can_move = false
					var left_idx = -1
					var right_idx = -1

					if x > 0:
						left_idx = (x - 1) + (y + 1) * Global.WIDTH
						if read_grid[left_idx] == SAND_EMPTY:
							can_move = true
					if x < Global.WIDTH - 1:
						right_idx = (x + 1) + (y + 1) * Global.WIDTH
						if read_grid[right_idx] == SAND_EMPTY:
							can_move = true

					if can_move:
						if left_idx != -1 and right_idx != -1 and \
								read_grid[left_idx] == SAND_EMPTY and \
								read_grid[right_idx] == SAND_EMPTY:
							# Both diagonals open, pick randomly
							if randi() % 2 == 0:
								write_grid[left_idx] = current_type
							else:
								write_grid[right_idx] = current_type
						elif left_idx != -1 and read_grid[left_idx] == SAND_EMPTY:
							write_grid[left_idx] = current_type
						elif right_idx != -1 and read_grid[right_idx] == SAND_EMPTY:
							write_grid[right_idx] = current_type
						# Note: no need to write to pos, because the particle moved
						continue
					# If we reach here, the particle cannot move
					write_grid[pos] = current_type
			else:
				# Bottom row: can't fall further
				write_grid[pos] = current_type

	# 4) Swap: the new buffer becomes "active" (next frame's old buffer),
	#    and the old buffer becomes the "write buffer."
	active_grid = 1 - active_grid

	
	
# Spawn sand into the simulation.
# mouse_pos: the position in pixels,
# cursor_size: the diameter of the brush,
# sand_type: which type of sand to spawn (defaults to SAND_TYPE1).
func spawn_sand(coords, radius, sand_type = SAND_TYPE1):
	var grid_x = coords.x
	var grid_y = coords.y
	
	
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			# Only consider points within the circle.
			var distance_sq = dx * dx + dy * dy
			if distance_sq > radius * radius:
				continue
			
			var new_x = grid_x + dx
			var new_y = grid_y + dy
			
			# Skip if outside the grid.
			if new_x < 0 or new_x >= Global.WIDTH or new_y < 0 or new_y >= Global.HEIGHT:
				continue

			# Introduce randomness for a more natural look.
			var distance_factor = 1.0 - float(distance_sq) / float(radius * radius)  # Closer to center = higher density
			var spawn_probability = 0.2 + 0.05 * distance_factor  # Probability decreases toward the edges

			if randf() < spawn_probability:  # Random chance to place sand
				var pos = new_x + new_y * Global.WIDTH
				if sand_grids[active_grid][pos] == SAND_EMPTY or sand_type == SAND_EMPTY:
					active_pixels.append([pos, sand_type])
