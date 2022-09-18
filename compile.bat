nasm -f bin bootloader.asm -o bin\base.bin
nasm -f bin extended_program.asm -o bin\extended.bin
cat bin/base.bin bin/extended.bin > bin/bootloader.bin
qemu-system-x86_64 bin\bootloader.bin