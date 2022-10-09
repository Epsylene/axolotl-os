nasm -f bin bootloader.asm -o bin/boot.bin
qemu-system-x86_64.exe -drive format=raw,file=bin/boot.bin