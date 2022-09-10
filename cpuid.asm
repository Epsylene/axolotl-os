detect_cpuid:
    ; The first step in setting up long mode is checking
    ; that it is present in the processor via the CPUID
    ; instruction, which we have to check itself if it is
    ; present on the CPU; this will be done by attempting to
    ; flip the CPUID bit in the FLAGS register (EFLAGS on 32
    ; bits, RFLAGS on 64, where various CPU-related info
    ; bits are stored), which is not possible if the
    ; instruction is not available.
    pushfd ; retrieve the FLAGS register 
    pop eax
    mov ecx, eax
    xor eax, 1 << 21 ; the 21th bit of the EFLAGS register
        ; is the one corresponding to the CPUID instruction
    push eax
    popfd ; copy the stack, where EAX (which has FLAGS with 
        ; the inverted bit) has been moved to, into the
        ; FLAGS register

    ; Now we have to check if the bit has actually been
    ; inverted
    pushfd ; retrieve FLAGS
    pop eax ; store FLAGS in eax
    push ecx ; store ECX (inverted FLAGS) in stack
    popfd ; copy to FLAGS
    xor eax, ecx ; check if the bit has been inverted
    jz no_cpuid ; jump if zero (that is, if the ZF flag in the
        ; status register is set), which is the case if EAX
        ; and ECX are equal

    ret

detect_long_mode:
    ; Now we can check if long mode is available, using the
    ; CPUID instruction; this instruction takes no arguments,
    ; as it uses the EAX register to determine the category
    ; of information returned.
    mov eax, 0x80000001 ; value for the "Extended Processor
        ; Info and Feature Bits" info
    cpuid
    test edx, 1 << 29 ; the TEST instruction performs a
        ; bitwise AND between its two operands; the 29th bit
        ; tells if long mode is available.
    jz no_long_mode

    ret

no_long_mode:
    hlt ; HALT instruction that tells the CPU to hang on until
        ; the next interrupt

no_cpuid:
    ret