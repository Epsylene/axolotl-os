
#include "text_print.hpp"

using namespace axlt;

extern "C" int main() 
{
    clear();
    set_cursor_pos(0, 0);
    print(0xcafe, BGD_BLUE | FGD_WHITE);

    return 0;
}