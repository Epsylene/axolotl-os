; Soon after appearing, 16-bits computers were confronted with
; the memory adressing problem: how could the OS process an
; adress which lied beyond the limit of what is inputable in a
; single word (16 bits, which make 2^16=64 KB maximum)? The
; solution used was segment-based adressing : a special
; register, termed "segment register", could be given a "base
; adress", which would be shifted 4 bits to the left and then
; added to an offset to end up at the correct adress. For
; example, to access 0x4fe56, one would write the following
; assembly:
;
;   mov bx, 0x4000 
;   mov es, bx 
;   mov [es:0xfe56], ax
;
; Although the general idea of segmentation has remained the
; same, the way that it is implemented in protected mode is
; more elaborate; rather than taking a base adress, multiplying
; it by 16 and then adding an offset, a segment register
; becomes an index to a particular segment descriptor (SD) in
; the GDT (Global Descriptor Table). We first need to define
; the GDT descriptor, which is the structure that contains the
; size and adress of the GDT:

align 4 ; this will make data align in memory on a 4-byte
    ; basis, which is the most efficient way to access memory
    ; on 32-bit systems (up to 8 dwords reads at once, assuming
    ; a 32-bit wide memory bus); data aligned this way is often
    ; said to be "naturally aligned".

gdt_start: ; label used for calculating the GDT size in the
    ; GDT descriptor later on

gdt_null:
    ; The first entry in the GDT is the null descriptor, which
    ; is an invalid segment (in other words, when ES is 0x0):
    ; the CPU will raise an exception (interrupt) if an
    ; adressing attempt is made within it.
    
    dd 0 ; declare two double words
    dd 0 ; (2*4 bytes) of 0s

gdt_code:
    ; The second entry is the code segment descriptor, which
    ; points to where the kernel code lives. It is comprised of
    ; a segment limit (20 bits), which defines the size of the
    ; segment, a base adress, which defines were the segment
    ; begins in physical memory (32 bits), and several flags
    ; which affect to tell the CPU how to interpret the
    ; segment.
    
    dw 0xFFFF ; first part of the segment limit
    dw 0x0 ; first part of the
    db 0x0 ; base adress
    db 10011010b ; access byte: this contains various flags 
        ; for the CPU, from left to right: 
        ;   - "present": 1 (the segment is present in memory)
        ;   - "privilege": 00 (highest privilege)
        ;   - "descriptor type": 1 (code or data segments; 0 is
        ;     for system segments)
        ;   - "code": 1 (code segment)
        ;   - "conforming": 0 (code in a segment with a lower
        ;     privilege may not call code in this segment),
        ;   - "readable": 1 (it is publicly readable; 0 is for
        ;     execute-only)
        ;   - "accessed": 0 (the CPU sets the bit when it
        ;     accesses the segment, which is useful for
        ;     debugging purposes).
    db 11001111b ; First bits are, from left to right:
        ;   - "granularity": 1 (instead of calculating the
        ;     segment limit byte by byte, which would allow a
        ;     size up to 1 MB, the calculation is made on a
        ;     "page-granular" basis, that goes up to 4 GB of
        ;     memory in 4 KB jumps)
        ;   - "size": 1 (adresses used by the segment register
        ;     ESP and the instruction pointer EIP are to be
        ;     32-bit, not 16-bit)
        ;   - 64-bit indicator: 0 (we are defining a 32-bit OS
        ;     for now)
        ;   - AVL (for "available"): left to be used by the
        ;     software as wished. 
        ;
        ; The rest is used to define the second part of the
        ; segment limit. The reason for this bizarre structure
        ; is that when Intel introduced the 32-bit 80386, they
        ; needed one more byte for the new 32-bit base and two
        ; more bytes for the 32-bit limit, but had only two
        ; bytes to spare. However, they realized that when
        ; dealing with large segments, being able to set the
        ; memory size with bit precision wasn't needed; a
        ; page-granular (4 KB) segment limit would suffice, and
        ; because the size was now 32-12 = 20 bits long (at
        ; this granularity, the memory is at least 4 KB, which
        ; is 12 bits wide; the segment limit being 20 bits long
        ; is the reason why with byte granularity, memory could
        ; go from 1 byte to 1 MB = 2^20 bits. With page
        ; granularity, the segment limit bits are shifted left
        ; by 12 bits, so to end up being 32 bits wide), they
        ; could fit in a single extra byte (the other one being
        ; used for the base adress) the remaining bits of the
        ; segment limit plus two more flags.
    db 0x0 ; second part of the base adress

gdt_data:
    ; The data descriptor is used for all writing purposes,
    ; which the code segment forbids. Note that apart from the
    ; corresponding flag in the access byte, nothing changes
    ; from one to the other; this is because we are using the
    ; so-called "basic flat model", where the two segments
    ; overlap each other; this is the simplest workable
    ; configuration of segment descriptors, that we may alter
    ; later, once we have booted into a higher-level language.
    dw 0xFFFF
    dw 0x0
    db 0x0
    db 10010010b ; the executable bit (fift one) is set to
        ; 0, because this is the data segment
    db 11001111b
    db 0x0

gdt_end: ; label used for calculating the size of the GDT
    ; in the GDT descriptor

gdt_descriptor:
    ; Because the CPU needs to know how long the GDT is, we
    ; give it first the adress of the GDT descriptor, which is
    ; a simple structure containing the size and the adress of
    ; the actual GDT.
    gdt_size: 
        dw gdt_end - gdt_start - 1 ; The size is substracted
            ; by 1 because the number of entries (given by
            ; gdt_end - gdt start) is 1 + the maximum numerical
            ; value in the given bits (for example, in this
            ; case size is a short, which means 16 bits so 2^16
            ; = 65536 entries but values in the range 0-65535).
        dq gdt_start ; Start adress of the GDT

CODE_SEG equ gdt_code - gdt_start ; #defines for the code...
DATA_SEG equ gdt_data - gdt_start ; ...and data segments