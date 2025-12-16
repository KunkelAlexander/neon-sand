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

- *SandSimulation*:
	- **C++ script**
	- Contains the core logic for the sand simulation, including methods for spawning sand, updating the grid, and managing sand types.
	- Stores a 2D grid of sand IDs (0…255) in a low-resolution array.
	- Grid size (derived from screen size / Global.SIM_SCALE) is updated from the Godot code via the grid_updated signal.
- *Input:*
	- **cursor.gd**
	- Controls the user input for interacting with the simulation, including adjusting the cursor size and placing sand particles.
- *SandRenderer*:
	- Handles the visual representation of the simulation.
	- Converts the low-res simulation array into a texture (type_texture).
	- Uses a shader to convert sand IDs into colors via a palette texture (sand_colors).
	- Scales the low-res texture to fit the screen using a TextureRect

- **show_fps.gd**: Displays the FPS in the corner of the screen.
- **title.gd**: Displays the title screen with a fadeout animation.

## Controls

- **Left mouse button**: Spawn sand at the cursor position with a dynamic sand type (color changes over time).
- **Right mouse button or double-tap**: Remove sand from the simulation at the cursor position.
- **Mouse wheel or pinch gesture**: Adjust the cursor size for sand placement.
- **Escape Key**: Quit the simulation.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

This project makes use of the Dynalight font (https://fontlibrary.org/en/font/dynalight) released under the [SIL Open Font License](https://openfontlicense.org/open-font-license-official-text/).
