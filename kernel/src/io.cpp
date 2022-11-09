
#include "io.hpp"

namespace axlt
{
    void byte_out(u16_t port, u8_t val)
    {
        // We are using inline assembly to write to a port some
        // value. The sintax is "asm(template : output : input :
        // clobbered registers)", where the last parameter
        // stands for the registers we are modifying in the ASM
        // code, so that GCC knows they are not usable. The
        // 'volatile' keyword simply indicates to the compiler
        // that this inline ASM code is important and shouldn't
        // be optimized away.
        //
        // In our case, we call the 'outb' command, the byte
        // version of OUT, which copies the value from the first
        // operand to the I/O port at the adress specified in
        // the second operand (note that online documentation
        // might say the opposite; this is because GCC uses AT&T
        // syntax, where source and destination operands are
        // inverted with respect to Intel sintax). The first
        // operand, %0, expands in the first parameter of the
        // asm statement, which is part of the input section:
        // "a"(val), where the string "a" is called a
        // "constraint" on the parameter, means that 'val' is to
        // be stored in the A register (that is, AL, AX or EAX,
        // depending on the value size; even on 64-bits, it is
        // not possible to send more than 32 bits at once). The
        // %1 operand is expanded as "Nd"(port): the constraint
        // "Nd" is actually comprised of two different
        // modifiers, "N" (which takes the value as an unsigned
        // 8-bit integer value; it is specific to in/out
        // instructions) and "d" (the D register). This is
        // because the destination operand of OUT is either an
        // immediate byte-operand (that is, a byte constant) or
        // the DX register.
        asm volatile ("out %0, %1" : : "a"(val), "Nd"(port));
    }

    u8_t byte_in(u16_t port)
    {
        u8_t val;

        // Same as before, except this time we take an ouput
        // parameter, 'val': the constraint "=a" tells, on one
        // hand, the inline assembly to expand it as the A
        // register, and on the other hand, to put the value
        // that this register will have at the end of the
        // operation into the parameter the constraint is given
        // (in our case 'val'). This is because INB takes a byte
        // from the port at [DX] and moves it to either AL, AX
        // or EAX, depending on the size of the port being
        // accessed.
        asm volatile ("inb %1, %0" : "=a"(val) : "Nd"(port));

        return val;
    }
}