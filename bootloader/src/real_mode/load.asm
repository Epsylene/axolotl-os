disk_load:
    ; Disk reading is done using the Cylinder-Head-Sector (CHS)
    ; adressing; this is because in reality, hard disk drives
    ; are made of several metal tracks paired with two magnetic
    ; head arms to read and write data onto them (one for each
    ; side of the plate). The CHS adressing thus is a
    ; representation of the spatial position of the data in the
    ; disk, where in cylindrical coordinates, the cylinder
    ; corresponds to r, the sector to theta, and the head to z
    ; (head 0 is the first side of the first platter, 1 the
    ; other side, 2 the first side of the second platter, etc).

    ; Always first save the registers
    push ax
    push bx
    push cx
    push dx

    push cx

    mov al, cl ; read CL sectors
    mov cl, bl ; start reading from sector BL
    mov bx, dx ; destination adress of the load
    mov ch, 0x00 ; select cylinder 0
    mov dh, 0x00 ; select head 0 (first side of the
        ; first platter)
    mov dl, [BOOT_DISK] ; read disk BOOT_DISK (provided by
        ; the BIOS)
    
    mov ah, 0x02 ; BIOS read sector function
    int 0x13 ; interrupt call 0x13, for hard disk and floppy
        ; disk read and write services
    jc disk_error ; if there is an error, the carry flag
        ; will be set, and a jump will be performed

    pop bx
    cmp al, bl ; if the number of sectors actually read (AL)
        ; is not the same as the expected number of sectors
        ; to be read (DH)...
    jne disk_error ; ...jump to the error function.

    mov bx, LOADED_DISK
    call printn

    pop dx
    pop cx
    pop bx
    pop ax
    ret

disk_error:
    mov bx, DISK_ERR_STR
    call print

    shr ax, 8
    mov bx, ax
    call print_hex
    call print_nwl

    jmp $

DISK_ERR_STR: db "Disk read error, code ", 0
LOADED_DISK: db "New sectors loaded", 0