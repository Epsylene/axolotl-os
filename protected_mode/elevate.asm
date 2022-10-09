[bits 32]

%include "protected_mode/cpuid.asm"
%include "protected_mode/paging.asm"

elevate_lm:
    ; Stepping up to 64 bits requires entering what is called
    ; "long mode", where 64 bit programs are run in a sub-mode
    ; called "64-bit mode", and protected mode programs run in
    ; another sub-mode called "compatibility mode"; real mode
    ; programs are not allowed to run in long mode, however.
    ; Before entering long mode, we have to check if it is
    ; actually available on our CPU :
    call detect_cpuid
    call detect_long_mode
    mov esi, LM_AVAILABLE
    call printn_32

    ; Next, we have to set up paging:
    call set_up_identity_paging

    ; We can then finally enable long mode...
    mov ecx, 0xC0000080 ; EFER (Extended Feature Enable 
        ; Register) register, where the long mode enable bit
        ; is placed
    rdmsr ; read MSR (Model-Specific Register, like the 
        ; EFER, which are various control registers used for
        ; debugging and toggling certain CPU features)
    or eax, 1 << 8
    wrmsr ; write to MSR (like RDMSR, things to be written
        ; are taken from EAX)

    ; ...enable paging...
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ; ...and change the GDT to long mode:
    call edit_gdt

    jmp CODE_SEG:start_long_mode

LM_AVAILABLE: db "64-bit long mode is supported", 0

[bits 64]

start_long_mode:
    cli

    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    jmp extended_program_64