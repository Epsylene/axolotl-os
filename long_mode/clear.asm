[bits 64]

SPACE_CHAR equ 0x20

clear_64:
    ; Manually push registers (there is no PUSHA in x86_64,
    ; because it was deemed not useful, and thus removed
    ; alongside a bunch of other instructions with a meagre
    ; number of use cases)
    push rdi
    push rax
    push rcx

    shl rdi, 8         ; The "style" byte (that is, the 1-byte
    mov rax, rdi       ; hexadecimal value commanding the
    mov al, SPACE_CHAR ; foreground and background colors) is 
                       ; in RDI; we shift it by 8 bits (aka
                       ; 1 byte) when putting it in RAX, so
                       ; that we can fill the next byte with
                       ; the character data, here a space.

    mov rdi, VIDEO_MEMORY ; Loop starting at VIDEO_MEMORY
    mov rcx, 80*25        ; 80x25 times writing at each
    rep stosw             ; iteration what is contained in
                          ; AX (not in EAX or RAX, because
                          ; we are only interested in those
                          ; two bytes, hence why we use
                          ; STOSW)

    pop rcx
    pop rax
    pop rdi
    ret