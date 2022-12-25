#   .sh
    .section .text
    .global _start
#   .type   _start,@function
_start:
    mov.l   _pstack,sp
    mov.l   _main_dis,r2
    jsr     @r2
    nop

1:
_pass:
    bra 1b
    nop
    .align  4   
_pstack:
    .long   _stack
_main_dis:
    .long   _main
