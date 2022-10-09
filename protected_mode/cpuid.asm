detect_cpuid:
    pushad

    ; The first step in setting up long mode is checking
    ; that it is present in the processor via the CPUID
    ; instruction, which we have to check itself if it is
    ; present on the CPU; this will be done by attempting to
    ; flip the CPUID bit in the FLAGS register (EFLAGS on 32
    ; bits, RFLAGS on 64, where various CPU-related info
    ; bits are stored), which is not possible if the
    ; instruction is not available.
    pushfd  ; retrieve the FLAGS register
    pop eax ; and put it into EAX
    mov ecx, eax ; backup EAX (thus FLAGS) in ECX
    xor eax, 1 << 21 ; the 21th bit of the EFLAGS register
        ; is the one corresponding to the CPUID instruction
    push eax ; push EAX (inverted FLAGS) to the
    popfd    ; stack and copy that into FLAGS

    ; Now we have to check if the bit has actually been
    ; inverted
    pushfd ; retrieve FLAGS
    pop eax ; store FLAGS in eax
    push ecx ; store ECX (original FLAGS) in stack
    popfd ; copy to FLAGS
    xor eax, ecx ; check if the bit has been inverted (if
        ; it hasn't, EAX and ECX will be the same, and xor'ing
        ; the two will return 0)
    jz no_cpuid ; jump if zero (that is, if the ZF flag in the
        ; status register is set), which is the case if EAX
        ; and ECX are equal

    ; Finally, we have have to check if the "extended
    ; features" set of the CPUID is available, because that
    ; is where is located the bit telling us if long mode is
    ; available.
    mov eax, 0x80000000 ; value for the "Highest Extended
    cpuid               ; Function Implemented" info; CPUID
                        ; will return in EAX the value of the
                        ; highest calling parameter
    cmp eax, 0x80000001  ; if the highest function available
    jb cpuid_no_extended ; is less than 0x80000001 (that is,
                         ; if the extended features are not
                         ; available), return.

    popad
    ret

detect_long_mode:
    ; Now we can check if long mode is available, using the
    ; CPUID instruction; this instruction takes no
    ; arguments, as it uses the EAX register to determine
    ; the category of information returned.
    

    ; Now that we checked that extended features were 
    ; available, we can see if long mode is too:
    mov eax, 0x80000001 ; "Extended Processor Info and Feature
    cpuid               ; Bits" info; CPUID will return the
                        ; flag bits in EDX and ECX. The one we
                        ; are interested in is the info in EDX
                        ; about the 29th bit, "long mode".
    test edx, 1 << 29 ; the TEST instruction performs a
        ; bitwise AND between its two operands; the 29th bit
        ; tells if long mode is available.
    jz no_long_mode

    ret

no_cpuid:
    mov esi, CPUID_NOT_FOUND
    call printn_32
    ret

cpuid_no_extended:
    call no_cpuid
    ret

no_long_mode:
    mov esi, NO_LONG_MODE
    call print_32
    hlt ; HALT instruction that tells the CPU to 
        ; hang on until the next interrupt

CPUID_NOT_FOUND: db "ERROR: CPUID unsupported, but necessary for long mode", 0
NO_LONG_MODE: db "ERROR: long mode not supported", 0