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


uint32_t rng_state = 0x12345678u;

inline uint32_t fast_rand() {
    rng_state ^= rng_state << 13;
    rng_state ^= rng_state >> 17;
    rng_state ^= rng_state << 5;
    return rng_state;
}

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

// Add 3x3 region around added pixel to dirty chunks
void SandSimulation::wake_spawn_area(int grid, int pos) {
    const int x  = pos % simulation_width;
    const int y  = pos / simulation_width;
    const int cx = x / CHUNK_SIZE;
    const int cy = y / CHUNK_SIZE;

    for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
            const int ncx = cx + dx;
            const int ncy = cy + dy;
            if (ncx < 0 || ncy < 0 || ncx >= chunks_x || ncy >= chunks_y) continue;
            const int nci = ncy * chunks_x + ncx;
            is_chunk_active[grid].set(nci, 1);
        }
    }
}

// Wake wide column above deleted sand
void SandSimulation::wake_deleted_area(int grid, int pos) {
    const int wake_chunks_x = 4;
    const int x = pos % simulation_width;
    const int y = pos / simulation_width;

    const int cx = x / CHUNK_SIZE;
    const int cy = y / CHUNK_SIZE;

    for (int wake_cy = cy; wake_cy >= 0; --wake_cy) {
        for (int dcx = -wake_chunks_x; dcx <= wake_chunks_x; ++dcx) {
            const int wake_cx = cx + dcx;
            if (wake_cx < 0 || wake_cx >= chunks_x) continue;

            is_chunk_active[grid].set(wake_cy * chunks_x + wake_cx, 1);
        }
    }
}


void SandSimulation::_ready() {
    active_grid = 0;
    simulation_height = 0;
    simulation_width = 0;
}

void SandSimulation::resize_simulation(int new_width, int new_height) {
    // Store old dimensions
    int old_width = simulation_width;
    int old_height = simulation_height;

    // Only save sand if we had a previous simulation
    bool has_previous_data = (old_width > 0 && old_height > 0);

    // Create a temporary copy of the current grid if needed
    PackedByteArray old_grid;
    if (has_previous_data) {
        old_grid = sand_grids[active_grid].duplicate();
    }

    // Update dimensions
    simulation_width = new_width;
    simulation_height = new_height;

    // Recalculate chunk geometry
    chunks_x = (new_width + CHUNK_SIZE - 1) / CHUNK_SIZE;
    chunks_y = (new_height + CHUNK_SIZE - 1) / CHUNK_SIZE;

    // Initialize sand grids
    for (int i = 0; i < 2; i++) {
        sand_grids[i].resize(new_width * new_height);
        sand_grids[i].fill(SAND_EMPTY);

        is_chunk_active[i].resize(chunks_x * chunks_y);
        is_chunk_active[i].fill(1);
    }


    // Update chunks in different x-permutations to avoid directional bias
    // The result still looks a bit odd at times, but I am generally happy with the feel of the simulation
    // Performance is good with this solution
    for (int k = 0; k < N_PERMUTATIONS; ++k) {
        for (int l = 0; l < 2; ++l) {

            int chunk_size = CHUNK_SIZE;
            if (l == 1) chunk_size = new_width % CHUNK_SIZE;

            chunk_size_permutations[l][k].resize(MAX(chunk_size, chunk_size_permutations[l][k].size()));

            // set up the permutation array
            for (int i = 0; i < chunk_size; ++i) {
                chunk_size_permutations[l][k].set(i, i);
            }

            // shuffle the permutation array
            for (int i = chunk_size - 1; i > 0; --i) {
                int j = fast_rand() % (i + 1);
                int temp = chunk_size_permutations[l][k][i];
                chunk_size_permutations[l][k].set(i, chunk_size_permutations[l][k][j]);
                chunk_size_permutations[l][k].set(j, temp);
            }
        }
    }


    // Restore previous sand data where it fits
    if (has_previous_data) {
        int copy_width = MIN(old_width, new_width);
        int copy_height = MIN(old_height, new_height);

        for (int y = 0; y < copy_height; y++) {
            for (int x = 0; x < copy_width; x++) {
                int old_pos = y * old_width + x;
                int new_pos = y * new_width + x;

                uint8_t sand_type = old_grid[old_pos];
                sand_grids[active_grid].set(new_pos, sand_type);
            }
        }
    }

    // Clear the inactive grid
    int inactive_grid = 1 - active_grid;
    sand_grids[inactive_grid] = sand_grids[active_grid].duplicate();
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
    for (const PendingPixel &p : active_pixels) {
        sand_grids[active_grid].set(p.pos, p.type);
        // increase number of active cells in chunk pos
        if (p.type == SAND_EMPTY) {
            wake_deleted_area(active_grid, p.pos);
        } else {
            wake_spawn_area(active_grid, p.pos);
        }
    }
    active_pixels.clear();


    // Instead of using active cells, we'll process the entire grid
    PackedByteArray& grid_old  = sand_grids[    active_grid];
    PackedByteArray& grid_new  = sand_grids[1 - active_grid];
    grid_new = grid_old;


    PackedByteArray& chunk_old  = is_chunk_active[    active_grid];
    PackedByteArray& chunk_new  = is_chunk_active[1 - active_grid];
    chunk_new.fill(0);


    // Iterate chunks bottom‑up
    for (int cy = chunks_y - 1; cy >= 0; --cy) {
        int y0 = cy * CHUNK_SIZE;
        int y1 = MIN(y0 + CHUNK_SIZE, height) - 1;
        if (y1 == height - 1) --y1; // drop bottom row
        if (y1 < y0) continue;


        for (int y = y1; y >= y0; --y) {
            const int ro  = y * width;
            const int rob = ro + width;
            const int roa = ro - width;

            // Randomise x-update order to counter directional bias
            bool flip = (fast_rand() & 1);          // per-row, or per-frame
            int cx_start = flip ? (chunks_x - 1) : 0;
            int cx_end   = flip ? -1 : chunks_x;                  // stop when cx == cx_end
            int cx_step  = flip ? -1 : 1;

            for (int cx = cx_start; cx != cx_end; cx += cx_step) {
                const int chunk_id = cy * chunks_x + cx;
                if (chunk_old[chunk_id] == 0) continue;

                int x0 = cx * CHUNK_SIZE;
                int x1 = MIN(x0 + CHUNK_SIZE, width);

                const int chunk_width       = x1 - x0;
                const int chunk_width_index = (chunk_width == CHUNK_SIZE) ? 0 : 1;

                int k = fast_rand() % N_PERMUTATIONS;

                for (int i = 0; i < chunk_width; ++i) {
                    const int x   = x0 + chunk_size_permutations[chunk_width_index][k][i];
                    const int pos = ro + x;
                    const uint8_t t = grid_old[pos];
                    if (t == SAND_EMPTY) continue;

                    int dest = pos;
                    const int below = rob + x;

                    if (grid_new[below] == SAND_EMPTY) {
                        dest = below;
                    } else {
                        bool left_empty  = (x > 0)         && (grid_new[rob + x - 1] == SAND_EMPTY);
                        bool right_empty = (x < width - 1) && (grid_new[rob + x + 1] == SAND_EMPTY);

                        if (left_empty && right_empty)
                            dest = (fast_rand() & 1) ? (rob + x - 1) : (rob + x + 1);
                        else if (left_empty)
                            dest = rob + x - 1;
                        else if (right_empty)
                            dest = rob + x + 1;
                    }

                    if (pos != dest && grid_new[dest] == SAND_EMPTY) {
                        grid_new.set(pos, SAND_EMPTY);
                        grid_new.set(dest, t);

                        const int above = roa + x;
                        if (above >= 0)    wake_spawn_area(1 - active_grid, above);
                        if (x > 0)         wake_spawn_area(1 - active_grid, x + ro - 1);
                        if (x < width - 1) wake_spawn_area(1 - active_grid, x + ro + 1);
                        wake_spawn_area(1 - active_grid, pos);
                        wake_spawn_area(1 - active_grid, dest);
                    }
                }
            }

        }
    }

    active_grid = 1 - active_grid;


}

void SandSimulation::spawn_sand(const Vector2& coords, int radius, int sand_type, float density) {

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

            // Use UtilityFunctions instead of Math for random
            if (UtilityFunctions::randf() < density) {
                int pos = new_x + new_y * width;

                // Check both active and non-active grid for empty particles to avoid overwriting falling particles
                int g0 = sand_grids[0][pos];
                int g1 = sand_grids[1][pos];
                // Add sand
                if (g0 == SAND_EMPTY && g1 == SAND_EMPTY) {
                    Array pos_type;
                    pos_type.push_back(pos);
                    pos_type.push_back(sand_type);
                    active_pixels.push_back({pos, static_cast<uint8_t>(sand_type)});
                // Delete sand
                } else if (sand_type == SAND_EMPTY) {
                    Array pos_type;
                    pos_type.push_back(pos);
                    pos_type.push_back(sand_type);
                    active_pixels.push_back({pos, static_cast<uint8_t>(sand_type)});
                }
            }
        }
    }
}