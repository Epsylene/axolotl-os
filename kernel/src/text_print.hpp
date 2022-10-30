#pragma once

#include "typedefs.hpp"

inline constexpr u32_t VGA_WIDTH = 80;
inline constexpr u32_t VGA_HEIGHT = 25;

void set_cursor_pos(u8_t x, u8_t y);
