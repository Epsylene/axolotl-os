[bits 16]

extern _start
extern SECOND_STAGE_LENGTH

global boot

; In a conventional x86 architecture, the layout of the "lower
; memory" (that is, the layout of the first bytes of the
; computer memory, going from 0x0 to 0x9FFFF) looks like this:
;   1) IVT (Interrupt Vector Table, 1 KB): this is where the
;      adresses of a number of different low-level
;      operations (interrupt vectors) are stored;
;   2) BDA (BIOS Data Area, 256 bytes): sector containing
;      data relevant to the BIOS;
;   3) Conventional memory (from 0x500 to 0x7E00): free
;      memory, except for a 512-byte sector located at
;      0x7c00; when searching for an OS to boot, the BIOS
;      reads this section of memory, containing our
;      bootloader and known as the MBR (Master Boot Record);
;   4) EBDA (Extended BIOS Data Area, 128 KB): same as BDA;
;
; From there, the following bytes up until 0xFFFFF are known as
; the "upper memory":
;   5) Video display memory (128 KB): VGA mode pixel data;
;   6) Video BIOS (typically 16 KB): graphics processor
;      BIOS code;
;   6) BIOS expansions (160 KB): self-explanatory;
;   7) Motherboard BIOS (64 KB): main BIOS code.

; Section label, used by the linker script to place this
; section at 0x7c00, since that is where the bootloader is
; supposed to start in memory.
section .boot.initial

; Start of the bootloader. At this point, the CPU is in real
; mode, which is the mode that the BIOS uses to boot the
; system. In real mode, the CPU can only access up to 1 MB of
; memory and can only use 16-bit instructions. The bootloader
; is first responsible for setting up the system so it can
; reach protected (32-bit) mode, then long (64-bit) mode, and
; finally the kernel.
boot:
    mov bx, HELLO_WORLD ; Print a welcome message
    call printn         ; to the screen

    mov byte[BOOT_DISK], dl ; the BIOS stores the boot disk in DL
    mov bx, 2 ; Read from sector 2 (sector 1 is this very bootloader)...
    mov cx, SECOND_STAGE_LENGTH ; ...and load enough sectors from there.
    mov dx, 0x7e00 ; 0x7e00 is 512 bytes further than 0x7c00, 
        ; just at the end of the main body of the bootloader
    call disk_load

    jmp elevate_pm ; Elevate to protected mode

%include "real_mode/load.asm"
%include "real_mode/print.asm"
%include "real_mode/gdt.asm"
%include "real_mode/elevate.asm"

BOOT_DISK: db 0
HELLO_WORLD: db "Hello world from the bootloader", 0

times 510 - ($-$$) db 0 ; Fill all but two of the remaining 
    ; bytes with 0s: times x OP repeats OP x times, and $-$$
    ; returns the space used by the program ($ evaluates to the
    ; current line and $$ to the start of the current section,
    ; so $-$$ gives the space used to that point)
dw 0xaa55 ; "Magic number" that tells the BIOS that this is
    ; indeed a bootloader. Maybe used because 1010 1010 0101
    ; 0101 has a pretty pattern?

[bits 32]

; Label for the second stage of the bootloader. The "bootloader
; section" in memory, the MBR, is specified to be 512 bytes
; long, which is not enough to contain our bootloader. One
; solution is to split the bootloader in two parts: the first
; part, or "first stage", is the one that is 512 bytes long and
; does two things: first, load enough sectors from the disk for
; the rest of the bootloader, and second, jump to the second
; stage. The two stages are placed one right after the other,
; so the second one starts at 0x7e00, 512 bytes further than
; the first one.
section .boot.extended
extended_program:
    call clear_32           ; Clear the screen and
    mov esi, PROTECTED_MODE ; print a welcome message
    call printn_32          ; to the user

    jmp elevate_lm         ; Elevate to long mode

%include "protected_mode/clear.asm"
%include "protected_mode/print.asm"
%include "protected_mode/elevate.asm"
%include "protected_mode/gdt.asm"

PROTECTED_MODE: db "Now in protected mode", 0

[bits 64]

extended_program_64:
    mov rdi, WHITE_ON_BLUE
    call clear_64
    mov rsi, LONG_MODE
    call printn_64

    jmp _start

%include "long_mode/clear.asm"
%include "long_mode/print.asm"

LONG_MODE: db "Long mode up and running", 0