elevate_pm:
    ; When starting the computer, the CPU first boots in what
    ; is called the "16-bit real mode". This mode emulates the
    ; functionning of the Intel 8086 CPU (the oldest one in the
    ; family), which had support for 16-bit instructions only,
    ; and no memory protection, to allow backwards
    ; compatibility. The OS is then required to explicitly
    ; enter the more advanced "32-bit protected mode", with
    ; 32-bit instructions and memory protection (hence the
    ; "protected").
    call enable_A20 ; to enable the A20 line
    cli ; command to clear the interrup flag, which is the
        ; flag bit in the CPU FLAGS register (register that
        ; contains the state of the CPU) corresponding to
        ; interrup instructions (there is also `sti` to set the
        ; interrupt flag); in other words, we are telling the
        ; CPU to ignore interrupts, which is necessary while
        ; setting up the GDT, because we don't know how to
        ; handle them yet.
    lgdt [gdt_descriptor] ; tell the CPU about our beautiful new GDT

    mov eax, cr0 ; These 3 instructions simply set the first
    or eax, 0x1  ; bit of the CR0 register to 1, which is what
    mov cr0, eax ; tells the CPU that we want to switch.
    
    jmp CODE_SEG:start_protected_mode ; The reason for doing
        ; a far jump here (segment:offset) instead of a near
        ; jump is CPU pipelining. When instructions arrive to
        ; the CPU, they go through different stages (fetching
        ; from memory, decoding into microcode instructions,
        ; executing, storing back to memory), and since those
        ; are semi-independent, a modern CPU will frequently do
        ; all within a single cicle by -for example- fetching
        ; another instruction when the first one is being
        ; processed. But that is a dangerous thing for us when
        ; switching from 16-bit to 32-bit mode, because there
        ; is a risk the CPU might process some stages of the
        ; instructions in the wrong mode. What we need is to
        ; switch the pipeline right after the switch has been
        ; made: this is why we do a far jump, because the CPU
        ; doesn't know beforehand what instructions come after
        ; a `call` or `jmp` instruction.

enable_A20:
    ; When two different components of a computer need to
    ; transfer data, they do it through what is called a "bus".
    ; The CPU has acces to physical adresses in the memory
    ; through an "address bus" ; each bit of this bus is called
    ; a "line", and named Ax, where x is the bit number. The
    ; A20 line thus corresponds to the adress line for the 21st
    ; bit. The Intel 8086 could access up to 1 Mb of memory, so
    ; it had adress lines A0 to A19. This meant that when
    ; adresses went past the 1 Mb limit, they wrapped around
    ; and started again at 0x0. Then, the Intel 80286 was
    ; introduced, which could adress up to 16 Mb of memory; to
    ; maintain backwards compatibility with the 8086, on top of
    ; booting in 16-bit real mode, it had to disable the A20
    ; line on the adress bus, so adresses still worked the same
    ; way they did in the 8086 (because there were indeed
    ; programs relying on that memory wraparound quirk). To
    ; enter the 32-bit protected mode, system developpers then
    ; have first to enable back the A20 line. The following
    ; instructions work with the FAST A20 option, which is part
    ; of the chipset on most newer computers.

    in al, 0x92  ; On x86 CPUs, I/O devices share the adress
    or al, 2     ; space with the memory (not the physical
    out 0x92, al ; space, but data labelling). To distinguish
                 ; between whether the CPU is talking to memory
                 ; or to I/O, the data manipulation
                 ; instructions differ: the `in` instruction
                 ; tells the CPU to read data from a position
                 ; in I/O space, and the `out` tells it to
                 ; write in there.

    ret

[bits 32]

start_protected_mode:
    ; Now in protected mode, the old segments are meaningless,
    ; so we point them to the new data segment descriptor.
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000 ; Update our stack position so it is
    mov esp, ebp     ; right at the top of the free space

    jmp extended_program ; jump back to the bootloader, now
        ; in protected mode