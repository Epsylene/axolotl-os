
#include "text_print.hpp"

#include "io.hpp"

namespace axlt
{
    u16_t cursor_pos;

    void set_cursor_pos(u16_t position)
    {
        // In text mode, the cursor doesn't do all those fancy
        // things like being positioned at the end of the text
        // or wrapping around the edge of the screen: it is
        // simply a blanking underline (in the most common case;
        // note that the cursor shape too can be manipulated),
        // which we can place wherever we want on the screen. To
        // do so, we have to tell the VGA hardware by sending
        // data over two specific I/O ports, the "CRT Controller
        // Registers" (where "CRT" -"Cathode Ray Tube"- refers
        // to the screen, which at the time indeed used CRTs).
        // These two ports are respectively the "CRTC Adress
        // Register" (located at 0x3d4), which controls the
        // specific graphics item we want to manipulate, and the
        // "CRTC Data Register" (located at 0x3d5), where we
        // send the data for the register corresponding to the
        // item we selected in the access register.
        //
        // We want to tell the VGA hardware about where to put
        // the cursor on the screen, by modifying the cursor
        // location register. Because the position is 16-bit but
        // the registers are 8-bit, this register is split in
        // two parts. The high cursor location register is the
        // 14th (0x0f) register in the CRTC register index, so
        // we send that to port 0x3d4 (access register) and then
        // the first 8 bits of the position to port 0x3d5 (data
        // register). Then we do the same for the low register,
        // which is at index 13, or 0x0e.
        byte_out(0x3d4, 0x0f);
        byte_out(0x3d5, (u8_t)(position & 0xff));
        byte_out(0x3d4, 0x0e);
        byte_out(0x3d5, (u8_t)((position >> 8) & 0xff));

        cursor_pos = position;
    }

    void set_cursor_pos(u8_t x, u8_t y)
    {
        u16_t position = x + VGA_WIDTH*y;
        position %= VGA_WIDTH*VGA_HEIGHT;

        set_cursor_pos(position);
    }

    // template<typename T>
    // string hex_to_string(T value)
    // {
    //     u8_t count = syzeof(T)*2 - 1;
    //     string output {count};

    //     u8_t* car, temp;
    //     for (u8_t i = 0; i < count; i++)
    //     {
    //         car = (u8_t*)(&value) + 1;
            
    //         temp = (*car & 0xF0) >> 4;
    //         output[count - (i*2 + 1)] = temp + (temp > 9 ? 55 : 48);
    //         temp = (*car & 0x0F);
    //         output[count - (i*2 + 1)] = temp + (temp > 9 ? 55 : 48);
    //     }

    //     return output;
    // }

    void print(string str)
    {
        u16_t index = cursor_pos;

        for (size_t i = 0; str[i] != '\0'; i++)
        {
            if(str[i] == '\n')
            {
                index += VGA_WIDTH;
                index -= index % VGA_WIDTH;
            }
            else
            {
                *(VGA_MEMORY + index*2) = str[i];
                index++;
            }
        }

        set_cursor_pos(index);
    }
}