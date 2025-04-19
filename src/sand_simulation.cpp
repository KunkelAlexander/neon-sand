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

int SandSimulation::get_width() const {
    return simulation_width;
}

int SandSimulation::get_height() const {
    return simulation_height;
}

int SandSimulation::chunk_index_from_pos(int pos) const {
    const int x = pos % simulation_width;
    const int y = pos / simulation_width;
    return (y / CHUNK_SIZE) * chunks_x + (x / CHUNK_SIZE);
}

void SandSimulation::add_to_chunk(int grid, int pos) {
    const int ci = chunk_index_from_pos(pos);
    is_chunk_active[grid][ci] |= true;
}


void SandSimulation::remove_from_chunk(int grid, int pos) {
    const int ci = chunk_index_from_pos(pos);
}



void SandSimulation::_ready() {
    active_grid = 0;
    simulation_height = 0;
    simulation_width = 0;
}

void SandSimulation::resize_simulation(int width, int height) {
    simulation_width  = width;
    simulation_height = height;

    // ----- chunk geometry -----
    chunks_x = (width + CHUNK_SIZE - 1) / CHUNK_SIZE;
    chunks_y = (height + CHUNK_SIZE - 1) / CHUNK_SIZE;

    // Initialize sand grids
    for (int i = 0; i < 2; i++) {
        sand_grids[i].resize(width * height);
        sand_grids[i].fill(SAND_EMPTY);
        is_chunk_active[i].resize(chunks_x * chunks_y);
        is_chunk_active[i].fill(0);
    }

}

void SandSimulation::_process(double delta) {
    update_sand();

    // Emit signal to notify renderer - use StringName instead of Signal
    emit_signal("grid_updated", sand_grids[active_grid]);
}


void SandSimulation::update_sand() {
    int width  = get_width();
    int height = get_height();


    // Add any new sand pixels to the active grid
    for (int i = 0; i < active_pixels.size(); i++) {
        const Array pos_type = active_pixels[i];
        const int pos        = pos_type[0];
        const int sand_type  = pos_type[1];
        sand_grids[active_grid].set(pos, sand_type);
        // increase number of active cells in chunk pos
        add_to_chunk(active_grid, pos);
    }
    active_pixels.clear();


    // Instead of using active cells, we'll process the entire grid
    PackedByteArray& grid_old  = sand_grids[    active_grid];
    PackedByteArray& grid_new  = sand_grids[1 - active_grid];
    grid_new = grid_old.duplicate();


    PackedByteArray& chunk_old  = is_chunk_active[    active_grid];
    PackedByteArray& chunk_new  = is_chunk_active[1 - active_grid];
    chunk_new.fill(0);


    int num_active_chunks = 0;
    int active_cells = 0;
    int cells = 0;
    for (auto chunk : chunk_old) {if (chunk) num_active_chunks++; active_cells+=chunk;}
    for (auto cell : grid_old) cells += (cell != SAND_EMPTY);

    //if (cells)
    //UtilityFunctions::print(num_active_chunks, "/", chunk_old.size(), " active chunks  -- ", active_cells, " active cells ", cells, "/", grid_new.size(), " total cells");


    /* ----  2) iterate chunks bottom‑up ---- */
    for (int cy = chunks_y - 1; cy >= 0; --cy) {
        int y0 = cy * CHUNK_SIZE;
        int y1 = MIN(y0 + CHUNK_SIZE, height) - 1;
        if (y1 == height - 1) --y1; // drop bottom row
        if (y1 < y0) continue;


        for (int y = y1; y >= y0; --y) {
            const int ro  = y * width;
            const int rob = ro + width;
            const int roa = ro - width;


            for (int cx = 0; cx < chunks_x; ++cx) {
                const int chunk_id = cy * chunks_x + cx;
                if (chunk_old[chunk_id] == 0) continue;   // skip empty

                int x0 = cx * CHUNK_SIZE;
                int x1 = MIN(x0 + CHUNK_SIZE, width) - 1;


                for (int x = x0; x <= x1; ++x) {

                    if (((x + y) & 1) != 0)  // Skip non-red cells in this pass.
                    continue;

                    const int pos = ro + x;
                    const uint8_t t = grid_old[pos];
                    if (t == SAND_EMPTY) continue;

                    // check possible sand movement
                    int dest = pos;
                    const int below = rob + x;
                    if (grid_old[below] == SAND_EMPTY) {
                        dest = below;
                    } else {
                        bool left_empty  = (x > 0)         && (grid_new[rob + x - 1] == SAND_EMPTY);
                        bool right_empty = (x < width - 1) && (grid_new[rob + x + 1] == SAND_EMPTY);
                        if (left_empty && right_empty)
                            dest = (UtilityFunctions::randi() & 1) ? (rob + x - 1) : (rob + x + 1);
                        else if (left_empty)
                            dest = rob + x - 1;
                        else if (right_empty)
                            dest = rob + x + 1;
                        else
                            dest = pos;
                    }

                    if (pos != dest) {
                        // sand moves
                        grid_new.set(pos, SAND_EMPTY);
                        grid_new.set(dest, t);
                        const int above = roa + x;
                        if (above >= 0)    add_to_chunk     (1 - active_grid, above);
                        if (x > 0)         add_to_chunk     (1 - active_grid, x + ro - 1);
                        if (x < width - 1) add_to_chunk     (1 - active_grid, x + ro + 1);
                        add_to_chunk     (1 - active_grid, pos);
                        add_to_chunk     (1 - active_grid, dest);
                    }
                }
            }
        }
    }


    for (int cy = chunks_y - 1; cy >= 0; --cy) {
        int y0 = cy * CHUNK_SIZE;
        int y1 = MIN(y0 + CHUNK_SIZE, height) - 1;
        if (y1 == height - 1) --y1; // drop bottom row
        if (y1 < y0) continue;


        for (int y = y1; y >= y0; --y) {
            const int ro  = y * width;
            const int rob = ro + width;
            const int roa = ro - width;


            for (int cx = 0; cx < chunks_x; ++cx) {
                const int chunk_id = cy * chunks_x + cx;
                if (chunk_old[chunk_id] == 0) continue;   // skip empty

                int x0 = cx * CHUNK_SIZE;
                int x1 = MIN(x0 + CHUNK_SIZE, width) - 1;


                for (int x = x0; x <= x1; ++x) {

                    if (((x + y) & 1) == 0)  // Skip non-red cells in this pass.
                    continue;

                    const int pos = ro + x;
                    const uint8_t t = grid_old[pos];
                    if (t == SAND_EMPTY) continue;

                    // check possible sand movement
                    int dest = pos;
                    const int below = rob + x;
                    if (grid_old[below] == SAND_EMPTY) {
                        dest = below;
                    } else {
                        bool left_empty  = (x > 0)         && (grid_new[rob + x - 1] == SAND_EMPTY);
                        bool right_empty = (x < width - 1) && (grid_new[rob + x + 1] == SAND_EMPTY);
                        if (left_empty && right_empty)
                            dest = (UtilityFunctions::randi() & 1) ? (rob + x - 1) : (rob + x + 1);
                        else if (left_empty)
                            dest = rob + x - 1;
                        else if (right_empty)
                            dest = rob + x + 1;
                        else
                            dest = pos;
                    }

                    if (pos != dest) {
                        // sand moves
                        grid_new.set(pos, SAND_EMPTY);
                        grid_new.set(dest, t);
                        const int above = roa + x;
                        if (above >= 0)
                        add_to_chunk     (1 - active_grid, above);
                        add_to_chunk     (1 - active_grid, pos);
                        add_to_chunk     (1 - active_grid, dest);
                    }
                }
            }
        }
    }

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