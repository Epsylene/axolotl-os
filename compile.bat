nasm -f bin bootloader.asm -o bin\bootloader.bin
qemu-system-x86_64 bin\bootloader.bin