build/boot.o:
	cd bootloader; \
	nasm boot.asm -f elf64 -o boot.o; \
	mv boot.o ../build/boot.o

build/kern.o:
	cd kernel; \
	cargo +nightly rustc --release -- --emit obj=kern.o; \
	mv kern.o ../build/kern.o

build/os.img: build/boot.o build/kern.o
	ld -T link.ld --oformat binary -o build/os.img

clean:
	rm -f build/**

run: build/os.img
	qemu-system-x86_64 -drive format=raw,file=build/os.img