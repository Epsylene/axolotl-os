/* ENTRY(_boot) */
INPUT(build/boot.o build/kern.o)

SECTIONS {
    /* The bootloader starts at 0x7c00 */
    .boot 0x7c00 : {
        *(.boot.text)
    }

    /* From 0x7e00 onwards are the second stage and the kernel
    */
    .text 0x7e00 : {
        *(.extended.text)
        *(.text*)
    }

    .data : {
        *(.data* .rodata*);
	}

	.rela : {
		*(.rela*);
		. = ALIGN(512);
    } = 0xdeadc0de

    SECOND_STAGE_LENGTH = ((. - ADDR(.text)) >> 9);
}