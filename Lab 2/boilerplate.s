; Created by Lubos Kuzma
; ISS Program at SADT, Southern Alberta Institute of Technology
; September, 2022
; x86-64, NASM

; *******************************
; Functionality of the program:
; This is a boilerplate example
; *******************************

global _start               ; exposes entry point to other programs
section .text               ; defines that the text below if the program itself

_start:                     ; Entry point
    mov rax, 0xABCDEFABCDEFABCD
    mov rax, 0xF

    jmp _exit               ; uncoditional jumpt to _exit

_exit:
    mov rax, 60             ; x86-64 syscall for sys_exit
    mov rdi, 0              ; system return code of 0 (normal exit)
    syscall                 ; execute syscall
