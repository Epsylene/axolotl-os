CC = clang
CXX = clang++
GDB = gdb 

LD = ld.lld
ASM = nasm

ASM_SRC = $(shell find . -type f -name "*.asm")
SRC = $(shell find . -type f -name "*.cpp")

OBJ = ${ASM_SRC:.asm=.o} ${SRC:.cpp=.o} 

INC = -Iinc/
ASMFLAGS = -f elf64
CXXFLAGS = -Iinc -ggdb -c -ffreestanding -target x86_64-none-elf -std=c++17
LDFLAGS = -Ttext 0x8200
LDFLAGS_BIN = ${LDFLAGS} --oformat binary

all: kernel kernel.elf

kernel: ${OBJ}
	${LD} -o $@ ${LDFLAGS_BIN} $^

kernel.elf: ${OBJ}
	${LD} -o $@ ${LDFLAGS} $^

%.o: %.cpp
	${CXX} ${CXXFLAGS} ${INC} -o $@ $^

%.o: %.asm
	${ASM} $< ${ASMFLAGS} -o $@

clean:
	rm -f kernel kernel.elf *.o **/*.o