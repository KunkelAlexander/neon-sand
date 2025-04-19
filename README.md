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
