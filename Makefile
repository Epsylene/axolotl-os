# Rules that do not correspond to files are called phony
# targets. Marking them as such prevents make from confusing
# them with files of the same name.
.PHONY: all clean run

# Source files
ASM = $(shell find . -type f -name "*.asm")
SRC = $(shell find . -type f -name "*.rs")

# First rule: the default target called when make is run with
# no arguments.
all: build/os.img

# The assembly source files are set as dependencies of the
# rule. Even if they are not used in the recipe, they ensure
# that the rule is re-run if any of the source files change.
build/boot.o: ${ASM}
	cd bootloader; \
	nasm boot.asm -f elf64 -o boot.o; \
	mv boot.o ../build/boot.o

# Same for the kernel source files.
build/kern.o: ${SRC}
	cd kernel; \
	cargo +nightly rustc --release -- --emit obj=kern.o; \
	mv kern.o ../build/kern.o

# Marking two files as dependencies of the target both ensures
# that the target is re-run if either of the files change, and
# calling the rules of the same name that produce these files
# in the first place.
build/os.img: build/boot.o build/kern.o
	ld -T link.ld --oformat binary -o build/os.img

clean:
	rm -f build/**

run: all
	qemu-system-x86_64 -drive format=raw,file=build/os.img