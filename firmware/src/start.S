.section .text
.global _start
_start:

    # -----------------------------
    # Set up stack pointer
    # -----------------------------
    la sp, _stack_top

    # -----------------------------
    # Jump to main()
    # -----------------------------
    call main

halt:
    j halt
