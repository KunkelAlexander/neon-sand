# Neon Sand Simulation

Neon Sand is a falling sand simulation built with the Godot Engine. The sand logic is implemented using a C++ GDExtension to handle simulation updates and the interaction of different sand types. The simulation can be run in the Godot editor or exported for the web.

![gameplay](assets/ingame.gif)


## Features
- Sand simulation with various sand types.
- Dynamic sand spawning with a smooth, random distribution.
- Multiple types of sand particles with different behaviors.
- User interaction via mouse input to control sand placement.
- Optimized for performance using grid-based simulation and active cell tracking.

## Setup

### Requirements
- Godot Engine 4.0+ (for GDExtension compatibility)
- C++ compiler for building the GDExtension (e.g., GCC, Clang)

### How to compile for Web
Follow the official Godot documentation on compiling for the web:
[Compiling for Web](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_web.html)

For release version:
```bash
scons platform=web target=template_release threads=no
```

For debug version:
```bash
scons platform=web target=template_debug threads=no
```

### Exporting for Web
Refer to the official guide for exporting to web platforms:
[Exporting for Web](https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_web.html#export-options)

### Sand Simulation Logic (C++ GDExtension)

This is the primary C++ code for the `SandSimulation` class that handles the sand logic. It uses a grid-based approach to simulate the behavior of sand particles and their interactions.

```cpp
#include "sand_simulation.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/window.hpp>

using namespace godot;

// Class constructor and destructor
SandSimulation::SandSimulation() {}
SandSimulation::~SandSimulation() {}

// Method to bind methods for the GDExtension
void SandSimulation::_bind_methods() {
    ClassDB::bind_method(D_METHOD("spawn_sand"), &SandSimulation::spawn_sand);
    ADD_SIGNAL(MethodInfo("grid_updated", PropertyInfo(Variant::PACKED_BYTE_ARRAY, "sand_grid")));
}

// Sand simulation logic for updating the grid and managing sand movement
void SandSimulation::update_sand() {
    int width = get_width();
    int height = get_height();
    // Update logic here...
}
```

## User Input (GDScript)

The user interacts with the simulation through a `cursor.gd` script, which is responsible for controlling the mouse cursor, spawning sand, and adjusting the cursor size. The script also listens for mouse clicks to place sand particles in the simulation.

```gd
extends Node2D

var cursor_size: float = 10.0
@onready var sand_sim = $"../SandSimulation"  # Reference the sand simulation node
var sand_type = 0
var time_passed := 0.0

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)  # Hide default cursor

func _process(delta):
    time_passed += delta
    sand_type = int(time_passed * 25.5) % 255
    position = get_global_mouse_position()

    if Input.is_action_pressed("left_click"):
        var grid_pos = screen_to_grid(position)
        var radius = grid_to_screen(cursor_size)
        sand_sim.spawn_sand(grid_pos, radius, sand_type)

    if Input.is_action_pressed("right_click"):
        var grid_pos = screen_to_grid(position)
        var radius = grid_to_screen(cursor_size)
        sand_sim.spawn_sand(grid_pos, radius, Global.SAND_EMPTY)

func _draw():
    draw_circle(Vector2.ZERO, cursor_size, Color(1, 1, 1), false)
```

## Key Classes and Scripts

- **SandSimulation (C++)**: Contains the core logic for the sand simulation, including methods for spawning sand, updating the grid, and managing sand types.
- **cursor.gd**: Controls the user input for interacting with the simulation, including adjusting the cursor size and placing sand particles.
- **cpu_renderer.gd**: Handles rendering the simulation using the CPU.
- **gpu_renderer.gd**: Handles rendering the simulation using the GPU (optional, for optimization).
- **show_fps.gd**: Displays the FPS in the corner of the screen.
- **title.gd**: Displays the title screen with a fadeout animation.

## Performance Optimization

The simulation uses several performance optimization techniques, such as:
- **Grid-based simulation**: Divides the simulation into a 2D grid to efficiently manage sand movement and placement.
- **Active cell tracking**: Only updates cells that are actively interacting with other cells, reducing unnecessary calculations.

## Controls

- **Left Mouse Button**: Spawn sand at the cursor position with a dynamic sand type (color changes over time).
- **Right Mouse Button**: Remove sand from the simulation at the cursor position.
- **Mouse Wheel**: Adjust the cursor size for sand placement.
- **Escape Key**: Quit the simulation.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
