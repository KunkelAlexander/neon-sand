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

# List of indices (in the grid) that were added this frame
var active_pixels = []

# Dictionary used as a set for cells that need to be updated.
var active_cells = {}  # keys are cell indices; values are true

	
func _ready():
	for grid in sand_grids:
		grid.resize(Global.WIDTH * Global.HEIGHT)
		grid.fill(SAND_EMPTY)
	active_grid = 0 
	
func _process(delta):
	update_sand()
	grid_updated.emit(sand_grids[active_grid])  # Notify renderer


func update_sand():
	var width = Global.WIDTH
	var height = Global.HEIGHT
	var read_grid = sand_grids[active_grid]
	
	# Instead of clearing the write grid completely, copy the read grid so that cells not processed remain unchanged.
	var write_grid = read_grid.duplicate()
	
	# Add any new sand pixels to the read grid and mark them as active.
	for pos_type in active_pixels:
		var pos = pos_type[0]
		var sand_type = pos_type[1]
		read_grid[pos] = sand_type
		active_cells[pos] = true
	active_pixels.clear()
	
	var new_active_cells = {}  # New set for the next frame
	
	# Process only cells in the active set.
	for pos in active_cells.keys():
		var x = pos % width
		var y = pos / width
		var sand_type = read_grid[pos]
		if sand_type == SAND_EMPTY:
			continue  # Skip if nothing is in this cell
		
		var moved = false
		
		# Check if the cell can move down (if not in the bottom row)
		if y < height - 1:
			var below = x + (y + 1) * width
			if read_grid[below] == SAND_EMPTY:
				# Move down: clear the old position in write grid and write to the new one.
				write_grid[below] = sand_type
				write_grid[pos] = SAND_EMPTY
				moved = true
				new_active_cells[below] = true
				
				# Activate cells above the new position.
				if y > 0:
					new_active_cells[x + (y - 1) * width] = true
					if x > 0:
						new_active_cells[(x - 1) + (y - 1) * width] = true
					if x < width - 1:
						new_active_cells[(x + 1) + (y - 1) * width] = true
				# Keep current cell active so any changes can be re-evaluated.
				new_active_cells[pos] = true
				
			else:
				# Check diagonal movement.
				var left = -1
				var right = -1
				var left_empty = false
				var right_empty = false
				
				if x > 0:
					left = (x - 1) + (y + 1) * width
					left_empty = read_grid[left] == SAND_EMPTY
				if x < width - 1:
					right = (x + 1) + (y + 1) * width
					right_empty = read_grid[right] == SAND_EMPTY
				
				if left_empty or right_empty:
					if left_empty and right_empty:
						if randi() % 2 == 0:
							write_grid[left] = sand_type
							write_grid[pos] = SAND_EMPTY
							new_active_cells[left] = true
						else:
							write_grid[right] = sand_type
							write_grid[pos] = SAND_EMPTY
							new_active_cells[right] = true
					elif left_empty:
						write_grid[left] = sand_type
						write_grid[pos] = SAND_EMPTY
						new_active_cells[left] = true
					elif right_empty:
						write_grid[right] = sand_type
						write_grid[pos] = SAND_EMPTY
						new_active_cells[right] = true
						
					moved = true
					# Activate cells above the new position.
					if y > 0:
						new_active_cells[x + (y - 1) * width] = true
						if x > 0:
							new_active_cells[(x - 1) + (y - 1) * width] = true
						if x < width - 1:
							new_active_cells[(x + 1) + (y - 1) * width] = true
					new_active_cells[pos] = true
				# Else: the cell is settled. Do nothing, so its value remains in write_grid.
		# Bottom row: the particle cannot move further.
		# Its value was already copied over by the duplicate, so we don't change it.
		
		# Optionally, you could add logic here to remove cells that have been settled for many frames.
	
	# Swap grids.
	var next_active_grid = 1 - active_grid
	sand_grids[next_active_grid] = write_grid
	active_grid = next_active_grid
	active_cells = new_active_cells
	
	
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
