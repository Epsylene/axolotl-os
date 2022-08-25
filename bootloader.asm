
jmp $

times 510 - ($-$$) db 0 ; fill 510 bytes with 0s: times x OP 
    ; repeats OP x times, and $-$$ returns the space used by
    ; the program ($ evaluates to the current line and $$ to
    ; the start of the current section, so $-$$ gives the
    ; space used to that point)
dw 0xaa55 ; "magic number" that tells the BIOS that this is
    ; indeed a bootloader

; N.B.: when searching for an OS to boot, the BIOS reads the
; first 512 bytes of data from the bootable disk (this is
; known as the MBR, for Master Boot Record) ; this NASM
; program indeed compiles to a 512-byte file.