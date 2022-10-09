
[org 0x7c00] ; assembler instrution (as in compiler) that
    ; specifies the base adress of the section of the file.
    ; This is needed because jmp instructions cannot always
    ; operate on relative adresses ("near" or "short" jumps);
    ; if the adress called is sufficiently distant, a "far
    ; jump" is performed, that takes an adress specified as a
    ; segment:offset pair. By default, this offset is 0x0, but
    ; our program is loaded on 0x7c00; the org directive adds
    ; 0x7c00 to the offset of the far jump so it can work as
    ; intended.

; The "lower memory" layout (that is, the layout of the
; first bytes of the computer memory, going from 0x0 to
; 0x9FFFF) is like so:
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
; From there, the following bytes up until 0xFFFFF are known
; as the "upper memory":
;   5) Video display memory (128 KB): VGA mode pixel data;
;   6) Video BIOS (typically 16 KB): graphics processor
;      BIOS code;
;   6) BIOS expansions (160 KB): self-explanatory;
;   7) Motherboard BIOS (64 KB): main BIOS code.

mov bp, 0x0500
mov sp, bp

mov bx, HELLO_WORLD
call printn

mov byte[BOOT_DISK], dl ; the BIOS stores the boot disk in DL
mov bx, 2 ; Read from sector 2 (sector 1 is this very bootloader)...
mov cx, 2 ; ...and load 2 sectors from there.
mov dx, 0x7e00 ; 0x7e00 is 512 bytes further than 0x7c00, 
    ; just at the end of the main body of the bootloader
call disk_load

call elevate_pm

jmp $

%include "real_mode/load.asm"
%include "real_mode/print.asm"
%include "real_mode/gdt.asm"
%include "real_mode/elevate.asm"

BOOT_DISK: db 0
HELLO_WORLD: db "Hello world from the bootloader", 0

times 510 - ($-$$) db 0 ; fill all but two of the remaining 
    ; bytes with 0s: times x OP repeats OP x times, and $-$$
    ; returns the space used by the program ($ evaluates to
    ; the current line and $$ to the start of the current
    ; section, so $-$$ gives the space used to that point)
dw 0xaa55 ; "magic number" that tells the BIOS that this is
    ; indeed a bootloader. Maybe used because 1010 1010 0101 
    ; 0101 is pretty, idk.

extended_program:

[bits 32]

call clear_32

mov esi, PROTECTED_MODE
call printn_32

call elevate_lm

jmp $

%include "protected_mode/clear.asm"
%include "protected_mode/print.asm"
%include "protected_mode/elevate.asm"

PROTECTED_MODE: db "Now in protected mode", 0

times 512 - ($ - extended_program) db 0

extended_program_64:

[bits 64]

mov rdi, WHITE_ON_BLUE
call clear_64

mov rsi, LONG_MODE
call printn_64

jmp $

%include "long_mode/clear.asm"
%include "long_mode/print.asm"

WHITE_ON_BLUE equ 0x1f
LONG_MODE: db "Long mode up and running", 0

times 512 - ($ - extended_program_64) db 0