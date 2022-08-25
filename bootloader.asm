
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

; To write "Hello" to the standard output, we can use the
; interrupt vector 0x10, which handles generic video
; services; when the interrupt request is issued, it will
; look up in the AH register the number of the desired
; subfunction to perform (in our case, teletype output, or
; TTY, which prints one character and advances the cursor).
; Finally, the AL register contains the character to be
; printed.
mov ah, 0x0e

mov al, 'H'
int 0x10
mov al, 'e'
int 0x10
mov al, 'l'
int 0x10
int 0x10
mov al, 'o'
int 0x10

jmp $ ; jumps to the current adress, which performs an
    ; infinite loop (note that this doesn't mean that the
    ; code in the next lines won't be executed, as it only
    ; declares bytes in memory).

times 510 - ($-$$) db 0 ; fill all but two of the remaining 
    ; bytes with 0s: times x OP repeats OP x times, and $-$$
    ; returns the space used by the program ($ evaluates to
    ; the current line and $$ to the start of the current
    ; section, so $-$$ gives the space used to that point)
dw 0xaa55 ; "magic number" that tells the BIOS that this is
    ; indeed a bootloader. Maybe used because 1010 1010 0101 
    ; 0101 is pretty, idk.