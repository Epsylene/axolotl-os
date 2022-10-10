[bits 64]

print_64:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rdx, VIDEO_MEMORY ; Set RDX to the start of the VGA
    shl rdi, 8            ; memory, shift RDI 1 byte left
                          ; to give room to the char data

    mov rbx, [CURRENT_LINE_64] ; Set RBX to the current line
    mov rcx, SCREEN_WIDTH*2    ; and RCX to the screen width
    imul rbx, rcx              ; in bytes, so that each time     
    add rdx, rbx               ; the string is printed on the
                               ; correct line      

    .loop:
    cmp byte[rsi], 0 ; Check if we have reached
    je .end          ; the end of the string

    mov rax, rdi      ; Move style from RDI to RAX, then
    mov al, byte[rsi] ; character at [RSI] into AL, and
    mov word[rdx], ax ; finally the whole (AX) to the VGA
                      ; memory at [RDX]

    add rsi, 1 ; Iterate one character...
    add rdx, 2 ; ...and two VGA memory bytes further.

    jmp .loop

    .end:
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

printn_64:
    call print_64
    inc byte[CURRENT_LINE_64]
    ret

CURRENT_LINE_64: dq 0