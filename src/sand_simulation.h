// sand_simulation.h
#ifndef SAND_SIMULATION_H
#define SAND_SIMULATION_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/array.hpp>
#include <unordered_map>
#include <vector>

namespace godot {

class SandSimulation : public Node {
    GDCLASS(SandSimulation, Node)

private:
    // Sand type definitions
    static const uint8_t SAND_EMPTY = 0;

    // The grid stores an integer per pixel (0 = empty, otherwise the sand type)
    PackedByteArray sand_grids[2];
    int active_grid = 0;

    // List of indices (in the grid) that were added this frame
    Array active_pixels;

    // Dictionary used as a set for cells that need to be updated.
    Dictionary active_cells;  // keys are cell indices; values are true

    // Helper functions
    int get_width();
    int get_height();
    bool has_zero_byte(uint64_t x);

protected:
    static void _bind_methods();

public:
    SandSimulation();
    ~SandSimulation();

    // Called when the node enters the scene tree
    void _ready() override;

    // Called every frame
	void _process(double delta) override;

    // Update sand simulation
    void update_sand();
    void update_active_sand();

    void debug_list_all_nodes();

    // Spawn sand into the simulation
    void spawn_sand(const Vector2& coords, int radius, int sand_type);

};

}

#endif // SAND_SIMULATION_H