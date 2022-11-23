
#include "text_print.hpp"

using namespace axlt;

extern "C" int main() 
{
    set_cursor_pos(0, 0);
    print("\n");
    print(0xcafe);

    return 0;
}