
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

    char output[128];
    template<typename T>
    const char* hex_to_string(T value)
    {
        u8_t count = sizeof(T) - 1;

        u8_t* car, temp;
        for (u8_t i = 0; i < count; i++)
        {
            car = (u8_t*)(&value) + i;
            
            // Each byte contains two hexadecimal numbers (0-F
            // is 16 = 2^4 values, so 4 bits), so we use masks
            // to set one and then the other, in reverse order
            // (because of the endianess). Then, using the ASCII
            // table, we can transform those numbers into their
            // corresponding characters: if the number is 0-9,
            // we shift it by 48 (where number characters start
            // in the table), if it is A-F, we shift it by 55
            // (where uppercase letters start).
            temp = (*car & 0xF0) >> 4;
            output[count - (i*2 + 1)] = temp + (temp > 9 ? 55 : 48);
            temp = (*car & 0x0F);
            output[count - i*2] = temp + (temp > 9 ? 55 : 48);
        }

        output[count + 1] = '\0';

        return output;
    }

    template const char* hex_to_string<s32_t>(s32_t);

    void print(const char* str)
    {
        // Start at the cursor position, iterating character by
        // character until we reach the null terminator.
        u16_t index = cursor_pos;
        for (size_t i = 0; str[i] != '\0'; i++)
        {
            if(str[i] == '\n')
            {
                // If the character is a line return, move one
                // screen width to the right (which will wrap
                // around and continue at the next line), then
                // trim that to the first column (index %
                // VGA_WIDTH is the new "cursor position",
                // modulo the screen width; in other words, it's
                // the space between the cursor and the left of
                // the screen on the line it's writing on).
                index += VGA_WIDTH;
                index -= index % VGA_WIDTH;
            }
            else
            {
                // Else, just write the character at the VGA
                // memory, and move the cursor by one position.
                *(VGA_MEMORY + index*2) = str[i];
                index++;
            }
        }

        set_cursor_pos(index);
    }
    
    void print(u32_t value)
    {
        print(hex_to_string(value));
    }
}