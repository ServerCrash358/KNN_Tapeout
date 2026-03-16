.section .text.startup
.global _start

_start:
    lui sp, (1024 * 32) >> 12  # valid stack
    call main

.global hang
hang:
    j hang

