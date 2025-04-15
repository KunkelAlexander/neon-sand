// sand_simulation.cpp
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

SandSimulation::SandSimulation() {
}

SandSimulation::~SandSimulation() {
    // Cleanup if necessary
}

void SandSimulation::_bind_methods() {
    ClassDB::bind_method(D_METHOD("resize_simulation"), &SandSimulation::resize_simulation);
    ClassDB::bind_method(D_METHOD("spawn_sand"), &SandSimulation::spawn_sand);

    // Register the signal with its parameters
    ADD_SIGNAL(MethodInfo("grid_updated",
        PropertyInfo(Variant::PACKED_BYTE_ARRAY, "sand_grid")));
}

/*
int SandSimulation::get_width() {
    // Access the global WIDTH constant from GDScript
    Object* global = Engine::get_singleton()->get_singleton("Global");
    if (!global) {
        ERR_PRINT("Failed to get Global singleton. Is it registered as an autoload?");
        return 0; // Return default value in case of failure
    }

    Variant width = global->get("WIDTH");
    if (width.get_type() != Variant::INT) {
        ERR_PRINT("Global.WIDTH is not an integer or doesn't exist");
        return 0; // Return default value if WIDTH is not valid
    }

    return width;
}

int SandSimulation::get_height() {

    // Print all available singletons
    Array singletons = Engine::get_singleton()->get_singleton_list();
    for (int i = 0; i < singletons.size(); i++) {
        String singleton_name = singletons[i];
        UtilityFunctions::print("Available singleton: ", singleton_name);
    }

    // Access the global HEIGHT constant from GDScript
    Object* global = Engine::get_singleton()->get_singleton("Global");
    if (!global) {
        ERR_PRINT("Failed to get Global singleton. Is it registered as an autoload?");
        return 0; // Return default value in case of failure
    }

    Variant height = global->get("HEIGHT");
    if (height.get_type() != Variant::INT) {
        ERR_PRINT("Global.HEIGHT is not an integer or doesn't exist");
        return 0; // Return default value if HEIGHT is not valid
    }

    return height;
}

void SandSimulation::debug_list_all_nodes() {
    // Get the SceneTree
    SceneTree* scene_tree = Object::cast_to<SceneTree>(Engine::get_singleton()->get_main_loop());
    if (!scene_tree) {
        ERR_PRINT("Failed to get scene tree");
        return;
    }

    // Get the root node
    Node* root = scene_tree->get_root();
    if (!root) {
        ERR_PRINT("Failed to get root node");
        return;
    }

    // Print root name
    UtilityFunctions::print("Root node: ", root->get_name());

    // List all direct children of root
    UtilityFunctions::print("Direct children of root:");
    for (int i = 0; i < root->get_child_count(); i++) {
        Node* child = root->get_child(i);
        UtilityFunctions::print(" - ", child->get_name(), " (", child->get_class(), ")");
    }

}

int SandSimulation::get_width() {
    // Access the global WIDTH constant from GDScript
    SceneTree* scene_tree = get_tree();
    if (!scene_tree) {
        ERR_PRINT("Failed to get scene tree");
        return 0;
    }

    Node* root = scene_tree->get_root();
    if (!root) {
        ERR_PRINT("Failed to get root node");
        return 0;
    }

    // Try different ways to get the Global node
    Node* global = nullptr;

    // Option 1: Use get_node_internal with an explicit cast
    global = root->get_node_internal(NodePath("Global"));


    // If that fails, try option 2: Get child by name
    if (!global) {
        for (int i = 0; i < root->get_child_count(); i++) {
            Node* child = root->get_child(i);
            if (child->get_name() == godot::StringName("Global")) {
                global = child;
                break;
            }
        }
    }

    // Check if we found the node
    if (!global) {
        ERR_PRINT("Failed to get Global autoload node. Is it registered as an autoload?");
        return 0;
    }

    Variant width = global->get("WIDTH");
    if (width.get_type() != Variant::INT) {
        ERR_PRINT("Global.WIDTH is not an integer or doesn't exist");
        return 0; // Return default value if WIDTH is not valid
    }

    return width;
}

int SandSimulation::get_height() {
    // Access the global HEIGHT constant from GDScript
  // Access the global WIDTH constant from GDScript
    SceneTree* scene_tree = get_tree();
    if (!scene_tree) {
        ERR_PRINT("Failed to get scene tree");
        return 0;
    }

    Node* root = scene_tree->get_root();
    if (!root) {
        ERR_PRINT("Failed to get root node");
        return 0;
    }

    // Try different ways to get the Global node
    Node* global = nullptr;

    // Option 1: Use get_node_internal with an explicit cast
    global = Object::cast_to<Node>(root->get_node_internal(NodePath("Global")));

    // If that fails, try option 2: Get child by name
    if (!global) {
        for (int i = 0; i < root->get_child_count(); i++) {
            Node* child = root->get_child(i);
            if (child->get_name() == godot::StringName("Global")) {
                global = child;
                break;
            }
        }
    }

    // Check if we found the node
    if (!global) {
        ERR_PRINT("Failed to get Global autoload node. Is it registered as an autoload?");
        return 0;
    }

    Variant height = global->get("HEIGHT");
    if (height.get_type() != Variant::INT) {
        ERR_PRINT("Global.HEIGHT is not an integer or doesn't exist");
        return 0; // Return default value if HEIGHT is not valid
    }

    return height;
}*/

int SandSimulation::get_width() const {
    return simulation_width;
}

int SandSimulation::get_height() const {
    return simulation_height;
}




void SandSimulation::_ready() {
    active_grid = 0;
    simulation_height = 0;
    simulation_width = 0;
}

void SandSimulation::resize_simulation(int width, int height) {

    simulation_width  = width;
    simulation_height = height;

    // Initialize sand grids
    for (int i = 0; i < 2; i++) {
        sand_grids[i].resize(width * height);
        sand_grids[i].fill(SAND_EMPTY);
    }
}

void SandSimulation::_process(double delta) {
    update_sand();

    // Emit signal to notify renderer - use StringName instead of Signal
    emit_signal("grid_updated", sand_grids[active_grid]);
}


void SandSimulation::update_sand() {
    int width = get_width();
    int height = get_height();

    // Add any new sand pixels to the active grid
    for (int i = 0; i < active_pixels.size(); i++) {
        const Array pos_type = active_pixels[i];
        const int pos        = pos_type[0];
        const int sand_type  = pos_type[1];
        sand_grids[active_grid].set(pos, sand_type);
    }
    active_pixels.clear();


    // Instead of using active cells, we'll process the entire grid
    const PackedByteArray& grid_old  = sand_grids[    active_grid];
          PackedByteArray& grid_new  = sand_grids[1 - active_grid];
    grid_new.fill(SAND_EMPTY);


    // Process bottom row (can't move further down)
    const int bottom_row = height - 1;
    const int bottom_row_offset = bottom_row * width;
    for (int x = 0; x < width; x++) {
        const int pos = x + bottom_row_offset;
        grid_new.set(pos, grid_old[pos]);
    }


    // --- First Pass: Update "Red" Cells where (x+y) % 2 == 0 ---
    for (int y = height - 2; y >= 0; y--) {
        const int row_offset       = y * width;
        const int row_below_offset = (y + 1) * width;
        for (int x = 0; x < width; x++) {
            if (((x + y) & 1) != 0)  // Skip non-red cells in this pass.
                continue;

            const int pos = row_offset + x;
            const int sand_type = grid_old[pos];

            // If the current cell is empty, nothing to do.
            if (sand_type == SAND_EMPTY)
                continue;

            // Try to move down if possible.
            int below = x + row_below_offset;
            if (grid_old[below] == SAND_EMPTY) {
                grid_new.set(below, sand_type);
                continue;
            }

            // Determine the status of the diagonals.
            bool left_empty  = (x > 0)         && (grid_new[row_below_offset + (x - 1)] == SAND_EMPTY);
            bool right_empty = (x < width - 1)   && (grid_new[row_below_offset + (x + 1)] == SAND_EMPTY);

            // When both directions are possible, pick randomly.
            if (left_empty && right_empty) {
                if (UtilityFunctions::randi() & 1)
                    grid_new.set(row_below_offset + (x - 1), sand_type);
                else
                    grid_new.set(row_below_offset + (x + 1), sand_type);
            } else if (left_empty) {
                grid_new.set(row_below_offset + (x - 1), sand_type);
            } else if (right_empty) {
                grid_new.set(row_below_offset + (x + 1), sand_type);
            } else {
                // No movement; keep the sand in its original place.
                grid_new.set(pos, sand_type);
            }
        }
    }

    // --- Second Pass: Update "Black" Cells where (x+y) % 2 == 1 ---
    // In this pass, we now read any red-cell updates that have been written into grid_new.
    for (int y = height - 2; y >= 0; y--) {
        const int row_offset       = y * width;
        const int row_below_offset = (y + 1) * width;
        for (int x = 0; x < width; x++) {
            if (((x + y) & 1) == 0)  // Skip the red cells in this pass.
                continue;

            const int pos = row_offset + x;
            const int sand_type = grid_old[pos];

            if (sand_type == SAND_EMPTY)
                continue;

            // Try to move down.
            int below = x + row_below_offset;
            if (grid_old[below] == SAND_EMPTY) {
                grid_new.set(below, sand_type);
                continue;
            }

            // Check diagonal movements.
            bool left_empty  = (x > 0)         && (grid_new[row_below_offset + (x - 1)] == SAND_EMPTY);
            bool right_empty = (x < width - 1) && (grid_new[row_below_offset + (x + 1)] == SAND_EMPTY);

            if (left_empty && right_empty) {
                if (UtilityFunctions::randi() & 1)
                    grid_new.set(row_below_offset + (x - 1), sand_type);
                else
                    grid_new.set(row_below_offset + (x + 1), sand_type);
            } else if (left_empty) {
                grid_new.set(row_below_offset + (x - 1), sand_type);
            } else if (right_empty) {
                grid_new.set(row_below_offset + (x + 1), sand_type);
            } else {
                grid_new.set(pos, sand_type);
            }
        }
    }

    // Swap grids
    active_grid = 1 - active_grid;
}

void SandSimulation::spawn_sand(const Vector2& coords, int radius, int sand_type) {

    int grid_x = coords.x;
    int grid_y = coords.y;
    int width = get_width();
    int height = get_height();

    for (int dx = -radius; dx <= radius; dx++) {
        for (int dy = -radius; dy <= radius; dy++) {
            // Only consider points within the circle
            int distance_sq = dx * dx + dy * dy;
            if (distance_sq > radius * radius) {
                continue;
            }

            int new_x = grid_x + dx;
            int new_y = grid_y + dy;

            // Skip if outside the grid
            if (new_x < 0 || new_x >= width || new_y < 0 || new_y >= height) {
                continue;
            }

            // Introduce randomness for a more natural look
            float distance_factor = 1.0f - static_cast<float>(distance_sq) / static_cast<float>(radius * radius);
            float spawn_probability = 0.2f + 0.05f * distance_factor;

            // Use UtilityFunctions instead of Math for random
            if (UtilityFunctions::randf() < spawn_probability) {
                int pos = new_x + new_y * width;
                if (sand_grids[active_grid][pos] == SAND_EMPTY || sand_type == SAND_EMPTY) {
                    Array pos_type;
                    pos_type.push_back(pos);
                    pos_type.push_back(sand_type);
                    active_pixels.push_back(pos_type);
                }
            }
        }
    }
}