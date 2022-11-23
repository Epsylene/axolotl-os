#pragma once

namespace axlt
{
    using u8_t = unsigned char;
    using u16_t = unsigned short;
    using u32_t = unsigned int;
    using u64_t = unsigned long;

    using s8_t = signed char;
    using s16_t = signed short;
    using s32_t = signed int;
    using s64_t = signed long;

    using size_t = u16_t;

    // Put on hold until we have dynamic memory
    //
    // class string
    // {
    //     public:

    //         char* str;

    //         string(char* str): str(str) {}

    //         string(size_t size, char c = ' ')
    //         {
    //             str = new char[size];

    //             for (size_t i = 0; i < size; i++)
    //             {
    //                 str[i] = c;
    //             }
    //         }

    //         char& operator[](size_t index) { return str[index]; }
    //         char operator[](size_t index) const { return str[index]; }
    // };
}