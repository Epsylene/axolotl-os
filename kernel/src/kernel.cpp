
#include "text_print.hpp"

using namespace axlt;

extern "C" int main() 
{
    set_cursor_pos(0, 0);
    print("Hello world");

    return 0;
}