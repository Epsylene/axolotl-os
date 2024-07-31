[bits 32]

; Paging is a system where memory, as seen by processes of the
; OS, is accessed through a set of virtual adresses, which can
; be different from the physical adresses. This allows
; accessing portions of memory that are not contiguous, for
; example, as well as protecting sections from being read or
; written to.
;
; On x86, paging is done through a series of two tables: the
; page directory and the page table, each containing 1024
; 4-byte entries (4 KB total). In the page directory, each
; entry points to a page table ; in the page table, each entry
; points to a 4 KB physical page frame (that is, a 4 KB segment
; of physical memory). Translating a virtual adress into a
; physical adress then involves dividing the virtual adress
; into three parts : the most significant 10 bits (bits 22-31)
; specify the index of the page directory entry, the next 10
; bits (12-21) specify the index of the page table entry, and
; the last 12 (0-11) specify the page offset.
;
; On x64, paging remains the same except two more page-map
; tables are used : the page-map level-4 table (PML4T), which
; is above the page-directory pointer table (PDPT), which is
; above the page-directory table (PDT), which is above the page
; table (PT). Entries are now 64 bits long, so there are only
; 512 of each, and the total maximum physical memory adressable
; is 512 GB per PML4T entry, so 256 TB.

PGT_ENTRY equ 0x1000 ; the adress of the PML4T, which is 
    ; the start of the paging table; note that 0x1000 is
    ; 4096, that is, 4 KiB.

set_up_identity_paging:
    pushad ; PUSHAD, like PUSHA, pushes all registers on
        ; the stack, except it does so with the 32-bit variants
        ; instead of the 16-bit ones.

    ; The first thing we will do is an "identity paging" (that
    ; is, a 1:1 paging, where virtual and physical adresses are
    ; the same) of the first megabyte of memory, to make things
    ; easier next. We start by clearing the memory area of the
    ; page tables:
    mov edi, PGT_ENTRY ; REP STOSD repeats ECX times the
    xor eax, eax       ; instruction STOSD, which writes
    mov ecx, 4096      ; on memory starting at EDI a double
    rep stosd          ; word of whatever is in EAX. Here,
                       ; that means that 4 bytes are set to
                       ; 0 4096 times starting at PGT_ENTRY,
                       ; or that the pages memory area is
                       ; all set to 0.

    ; Then we set up the paging structure, with PML4T[0] ->
    ; PDPT[0] -> PDT[0] -> PT[0]:
    mov edi, PGT_ENTRY ; we have to reset EDI because the
        ; STOSD instruction changed it
    mov cr3, edi ; the CR3 register stores the physical adress
        ; of the base of the paging structure hierarchy
    mov dword [edi], 0x2003 ; set the adress 0x1000 to the
        ; value 0x2003, because we want the PML4T's first entry
        ; to be the adress of the PDPT at 0x2000, plus some
        ; flags; the bits are, from least to most significant:        
        ; - "present": the page is present in physical memory
        ;   at the moment
        ; - "read/write": page is read-only if not set
        ; - "user/supervisor": if not set, only the supervisor
        ;   can access it
        ; - "PWT": if set, write-through, where data is written
        ;   simultaneously in the cache and in storage, is
        ;   enabled; if not, write-back is, where writing is
        ;   done only in the cache, and re-written in the
        ;   storage if contents of the cache are removed
        ; - "PCD": if set the page will not be cached
        ; - "accessed": page read
        ; - "dirty": page written to
        ; - "page size": self-explanatory
        ; - "global": the page can be seen by all processes
        ; - "PAT" (Page Attribute Table): if supported, this
        ;   feature allows to set different memory attributes
        ;   for the page.
        ;
        ; Here, because the first two bits are set (3 is 011),
        ; the page is present and read/write-able.
    add edi, 0x1000
    mov dword [edi], 0x3003 ; PDPT -> PDT
    add edi, 0x1000
    mov dword [edi], 0x4003 ; PDT -> PT

    ; Next we add 512 entries to our page table, such that each
    ; contains the corresponding physical adress (PT[0] = 0x0,
    ; PT[1] = 0x1, etc):
    add edi, 0x1000
    mov ebx, 0x00000003 ; flags
    mov ecx, 512 ; loop count
    .set_entry:
        mov dword[edi], ebx ; Set entry flags...
        add ebx, 0x1000 ; ...move one pointed adress up...
        add edi, 8 ; ...and set edi to the next entry (each
            ; entry is 8 bytes long, because there are 512
            ; entries for 4096 bytes)
        loop .set_entry ; the LOOP instruction will loop
            ; as many times as set in the ECX register  

    ; Now we have to enable PAE (Physical Adress Extension),
    ; which allows adresses up to 64 bits (note: most
    ; processors support less than this amount) and is required
    ; for long mode:
    mov eax, cr4
    or eax, 1 << 5 ; the sixth bit of the CR4 register is
        ; the one used to set PAE
    mov cr4, eax

    popad
    ret