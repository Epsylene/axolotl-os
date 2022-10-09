
[bits 32]

WHITE_ON_BLACK equ 0x0f
SCREEN_WIDTH equ 80

print_32:
    ; In real mode, we used interrupt instructions to print
    ; characters to the screen because it was simple,
    ; although not the fastest. However, in protected mode
    ; we are not able to access BIOS (because it is written
    ; in 16 bits), so we have to print in a slightly more
    ; complex manner, by accessing the video memory
    ; directly.
    ;
    ; The display device in a computer can be configured in
    ; one of two different modes: graphics mode (classic
    ; pixel-by-pixel screen manipulation) and text mode,
    ; where the screen is divided in "character cells", each
    ; of which displays a character from a fixed font set;
    ; by default, the graphics hardware used is VGA (Video
    ; Graphics Array) colour text mode with 80x25
    ; characters. To print some string, one simply needs to
    ; access the video memory, which is located at 0xb8000,
    ; and change the value of the cell corresponding to each
    ; character's position on screen.
    
    pusha

    mov edx, VIDEO_MEMORY   ; store the VGA start adress,
    mov ebx, [CURRENT_LINE] ; move into EBX and ECX the current
    mov ecx, SCREEN_WIDTH*2 ; line and double the screen width
    imul ebx, ecx           ; (because 2 bytes have to be
    add edx, ebx            ; written each time), then 
                            ; multiply the current line by
                            ; the width, and add that to the
                            ; VGA adress: this will make the
                            ; text print on the next line
                            ; each time the function is
                            ; called in 'printn_32', which
                            ; increases CURRENT_LINE by 1.

    .loop:
    cmp byte[esi], 0 ; check if we have reached
    je .done         ; the end of the string

    mov al, [esi] ; the string is located at ESI (Extended 
        ; Source Index, which has special uses with several
        ; string instructions), so this stores its first
        ; character in AL
    mov ah, WHITE_ON_BLACK ; text mode memory takes two bytes
        ; per character on screen: one for the actual
        ; character, and one that carries the foreground
        ; colour in its lowest 4 bits and the background
        ; colours in the upper 3 bits (the last bit
        ; interpretation depending on hardware
        ; configuration). For example, 0x1f = 0001'1111b
        ; would correspond to white (1111) on blue (001)
        ; (yes, the Blue Screen of Death !).
    
    mov word[edx], ax ; store the character (AL) and attributes
        ; (AH) combined (AX) at current character cell (EDX)
    
    add esi, 1 ; move the string iterator by one character
    add edx, 2 ; move the video memory iterator by two bytes
        ; (one for the character and one for the attributes)

    jmp .loop

    .done:
    popa
    ret

printn_32:
    call print_32
    inc byte[CURRENT_LINE]
    ret

CURRENT_LINE: dd 0