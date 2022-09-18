PROGRAM_SPACE equ 0x7e00 ; 'equ' does the same as '#define',
    ; that is, replacing all ocurrences of "PROGRAM_SPACE"
    ; with "0x7e00", without actually allocating any data;
    ; note that 0x7e00 is exactly 512 bytes away from 0x7c00,
    ; which is the starting adress of our bootloader.

disk_load:
    ; Disk reading is done using the Cylinder-Head-Sector
    ; (CHS) adressing; this is because in reality, hard disk
    ; drives are made of several metal tracks paired with
    ; two magnetic head arms to read and write data onto 
    ; them (one for each side of the plate). The CHS 
    ; adressing thus is a representation of the spatial
    ; position of the data in the disk, where in cylindrical
    ; coordinates, the cylinder corresponds to r, the sector
    ; to theta, and the head to z (head 0 is the first side
    ; of the first platter, 1 the other side, 2 the first side
    ; of the second platter, etc).

    push dx ; we will need it later

    mov dl, [BOOT_DISK] ; read disk BOOT_DISK (provided by
        ; the BIOS)
    mov ch, 0x00 ; select cylinder 0
    mov al, dh ; read DH sectors
    mov dh, 0x00 ; select head 0 (first side of the first
        ; platter)
    mov cl, 0x02 ; start reading from sector 2

    mov ah, 0x02 ; BIOS read sector function
    int 0x13 ; interrupt call 0x13, for hard disk and floppy
        ; disk read and write services
    jc disk_error ; if there is an error, the carry flag
        ; will be set, and a jump will be performed

    pop dx
    cmp dh, al ; if the number of sectors actually read (AL)
        ; is not the same as the expected number of sectors
        ; to be read (DH)...
    jne disk_error ; ...jump to the error function.

    ret

%include "print.asm"

disk_error:
    mov bx, DISK_ERR_STR
    call print
    jmp $

BOOT_DISK: db 0
DISK_ERR_STR: db "Disk read error", 0