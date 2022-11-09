#pragma once

#include "types.hpp"

namespace axlt
{
    void byte_out(u16_t port, u8_t val);
    u8_t byte_in(u16_t port);
}