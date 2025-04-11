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
    // Initialize sand colors
    sand_colors[SAND_EMPTY] = Color(0, 0, 0, 0);
    sand_colors[SAND_TYPE1] = Color(1, 1, 1, 1);
    sand_colors[SAND_TYPE2] = Color(1, 0, 0, 1);
    sand_colors[SAND_TYPE3] = Color(0, 1, 0, 1);
}

SandSimulation::~SandSimulation() {
    // Cleanup if necessary
}

void SandSimulation::_bind_methods() {
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
}*/

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
}

void SandSimulation::_ready() {
    int width = get_width();
    int height = get_height();

    UtilityFunctions::print("Width: ", width, " Height: ", height);

    // Initialize sand grids
    for (int i = 0; i < 2; i++) {
        sand_grids[i].resize(width * height);
        for (int j = 0; j < width * height; j++) {
            sand_grids[i].set(j, SAND_EMPTY);
        }
    }

    active_grid = 0;
}

void SandSimulation::_process(double delta) {
    update_sand();

    // Emit signal to notify renderer - use StringName instead of Signal
    emit_signal("grid_updated", sand_grids[active_grid]);
}

void SandSimulation::update_sand() {

    int width = get_width();
    int height = get_height();
    PackedByteArray& read_grid = sand_grids[active_grid];

    // Instead of clearing the write grid completely, copy the read grid so that cells not processed remain unchanged
    PackedByteArray write_grid = read_grid.duplicate();

    // Add any new sand pixels to the read grid and mark them as active
    for (int i = 0; i < active_pixels.size(); i++) {
        Array pos_type = active_pixels[i];
        int pos = pos_type[0];
        int sand_type = pos_type[1];
        read_grid.set(pos, sand_type);
        active_cells[pos] = true;
    }
    active_pixels.clear();

    Dictionary new_active_cells;

    // Process only cells in the active set
    Array active_cell_keys = active_cells.keys();
    for (int i = 0; i < active_cell_keys.size(); i++) {
        int pos = active_cell_keys[i];
        int x = pos % width;
        int y = pos / width;
        int sand_type = read_grid[pos];

        if (sand_type == SAND_EMPTY) {
            continue;  // Skip if nothing is in this cell
        }

        bool moved = false;

        // Check if the cell can move down (if not in the bottom row)
        if (y < height - 1) {
            int below = x + (y + 1) * width;
            if (read_grid[below] == SAND_EMPTY) {
                // Move down: clear the old position in write grid and write to the new one
                write_grid.set(below, sand_type);
                write_grid.set(pos, SAND_EMPTY);
                moved = true;
                new_active_cells[below] = true;

                // Activate cells above the new position
                if (y > 0) {
                    new_active_cells[x + (y - 1) * width] = true;
                    if (x > 0) {
                        new_active_cells[(x - 1) + (y - 1) * width] = true;
                    }
                    if (x < width - 1) {
                        new_active_cells[(x + 1) + (y - 1) * width] = true;
                    }
                }
                // Keep current cell active so any changes can be re-evaluated
                new_active_cells[pos] = true;
            } else {
                // Check diagonal movement
                int left = -1;
                int right = -1;
                bool left_empty = false;
                bool right_empty = false;

                if (x > 0) {
                    left = (x - 1) + (y + 1) * width;
                    left_empty = read_grid[left] == SAND_EMPTY;
                }
                if (x < width - 1) {
                    right = (x + 1) + (y + 1) * width;
                    right_empty = read_grid[right] == SAND_EMPTY;
                }

                if (left_empty || right_empty) {
                    if (left_empty && right_empty) {
                        // Use UtilityFunctions instead of Math for random
                        if (UtilityFunctions::randi() % 2 == 0) {
                            write_grid.set(left, sand_type);
                            write_grid.set(pos, SAND_EMPTY);
                            new_active_cells[left] = true;
                        } else {
                            write_grid.set(right, sand_type);
                            write_grid.set(pos, SAND_EMPTY);
                            new_active_cells[right] = true;
                        }
                    } else if (left_empty) {
                        write_grid.set(left, sand_type);
                        write_grid.set(pos, SAND_EMPTY);
                        new_active_cells[left] = true;
                    } else if (right_empty) {
                        write_grid.set(right, sand_type);
                        write_grid.set(pos, SAND_EMPTY);
                        new_active_cells[right] = true;
                    }

                    moved = true;
                    // Activate cells above the new position
                    if (y > 0) {
                        new_active_cells[x + (y - 1) * width] = true;
                        if (x > 0) {
                            new_active_cells[(x - 1) + (y - 1) * width] = true;
                        }
                        if (x < width - 1) {
                            new_active_cells[(x + 1) + (y - 1) * width] = true;
                        }
                    }
                    new_active_cells[pos] = true;
                }
                // Else: the cell is settled. Do nothing, so its value remains in write_grid.
            }
        }
        // Bottom row: the particle cannot move further.
        // Its value was already copied over by the duplicate, so we don't change it.
    }

    // Swap grids
    int next_active_grid = 1 - active_grid;
    sand_grids[next_active_grid] = write_grid;
    active_grid = next_active_grid;
    active_cells = new_active_cells;

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