[bits 32]

edit_gdt:
    ; When entering long mode, we need to edit the GDT to set
    ; the 64-bit flags.
    mov dword [gdt_code + 6], 10101111b ; Change the flag bits of
    mov dword [gdt_data + 6], 10101111b ; the GDT so that the 
        ; "long-mode" bit is set and "size" (16 or 32-bit
        ; segments) is clear (this is required when setting the
        ; long-mode bit), for both the code and data segments.

    ret