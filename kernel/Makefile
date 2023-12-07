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

# Note on Makefile sintax I will most surely have forgotten by
# the next time I read this file: $@ means the current target
# (e.g. "kernel"), $^ means all dependencies (e.g. "${OBJ}")
# and $< means the first dependency (e.g. "${ASM_SRC:.asm=.o}")
# (more at https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html).

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