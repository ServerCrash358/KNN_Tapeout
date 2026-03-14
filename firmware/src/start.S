.section .text.startup
.global _start

_start:
    lui sp, (1024 * 32) >> 12  # valid stack

    # GPIO init: set all pins to output (0)
    li   t6, 0x05000000    # GPIO register
    li   t0, 0x0
    sw   t0, 4(t6)

    call main

.global hang
hang:
    j hang

