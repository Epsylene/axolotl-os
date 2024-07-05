boot.o:
	nasm bootloader.asm -f elf64 -o boot.o

os.img: boot.o
	ld -T link.ld --oformat binary -o os.img

clean:
	rm -f boot.o os.img

run: os.img
	qemu-system-x86_64 -drive format=raw,file=os.img