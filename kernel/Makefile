# Set the C++ compiler and debugger
CXX = clang++
GDB = gdb 

LD = ld.lld
ASM = nasm

INC = -Iinc/
SRC = $(shell find . -type f -name "*.cpp")
ASM_SRC = $(shell find . -type f -name "*.asm")

OBJ = ${ASM_SRC:.asm=.o} ${SRC:.cpp=.o} 

CCFLAGS = -ggdb -c -ffreestanding -target x86_64-none-elf
LDFLAGS = -Ttext 0x8200
LDFLAGS_BIN = ${LDFLAGS} --oformat binary
ASFLAGS = -f elf64

all: kernel kernel.elf
	@mkdir -p bin
	$(shell find . \( -name "*.o" -o -name "kernel" -o -name "kernel.elf" \) -type f | xargs -i mv {} bin)

kernel: ${OBJ}
	${LD} -o $@ ${LDFLAGS_BIN} $^

kernel.elf: ${OBJ}
	${LD} -o $@ ${LDFLAGS} $^

%.o: %.cpp
	${CXX} ${CCFLAGS} ${INC} -o $@ $^

%.o: %.asm
	${ASM} $< ${ASFLAGS} -o $@

clean:
	rm -f bin/*