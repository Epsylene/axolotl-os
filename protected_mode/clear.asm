
[bits 32]

VIDEO_MEMORY equ 0xb8000

clear_32:
    pushad

    mov edi, VIDEO_MEMORY ; text screen video memory adress 
        ; for colour monitors
    mov eax, 0x0f200f20 ; Move hexcode for two white
        ; spaces with black background (0x0f is white on
        ; black -cf print.asm-, 20 is ASCII for a space)
    mov ecx, 1000 ; we will want to repeat the instruction
        ; to repeat 1000 times (80*25/2: the VGA screen is
        ; 80x25 pixels, and each time we repeat the loop
        ; two are drawn)
    rep stosd ; the REP instruction performs like the LOOP
        ; instruction, by repeating [ecx] times, but only
        ; with a certain set of string instructions, like
        ; STOSD, which copies EAX at [EDI].
    
    popad
    ret