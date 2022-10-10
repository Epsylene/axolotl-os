int main()
{
    char* vga = (char*)0xb8000;
    *vga = 'P';
    *(vga + 1) = 0x4f;

    return 0;
}