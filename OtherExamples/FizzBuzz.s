; FizzBuzz problem
; by Lubos Kuzma
; ISS Program, SADT, SAIT
; August 2022


; Problem:
; Print integers 1 to N, but print “Fizz” if an integer is divisible by 3, 
; “Buzz” if an integer is divisible by 5, and 
; “FizzBuzz” if an integer is divisible by both 3 and 5.


global _start
section .text


_start:

    mov r8, 0x0 ; count from 0

    .loop:
        ; Logic:
        ;
        ; divide by 3 -> if remainder is zero, print Fizz, set print_num_tf to 0
        ; divide by 5 -> if remainder is zero, print Buzz, set print_num_tf to 0
        ; if print_num_tf = 1, print_number

        mov dword [print_num_tf], 0x1   ; set print number flag 

    .div_by_three:
        mov r15, r8         ; prepare for div_by_three function
        call div_by_three
        cmp edx, 0x0        ; is divisible by three?
        jnz .div_by_five
        ; clear the print_num_tf flag
        mov dword [print_num_tf], 0x0
        ; print Fizz
        mov r14, fizz_word
        mov r15, fizz_l
        call print_string

    .div_by_five:
        mov r15, r8         ; prepare for div_by_five function
        call div_by_five
        cmp edx, 0x0        ; is divisible by three?
        jnz .print_number_section
        ; clear the print_num_tf flag
        mov dword [print_num_tf], 0x0
        ; print Buzz
        mov r14, buzz_word
        mov r15, buzz_l
        call print_string

    .print_number_section:
        cmp dword [print_num_tf], 0x0   ; Only print if Fizz or Buzz was NOT printed
        jz .loop_tail   
        call print_num

    .loop_tail:
        call print_LF
        inc r8
        cmp r8, 0x3E8       ; Count to 0x3E8 -> 1000 (999 + 1)
        jnz .loop
    call _exit


div_by_three:

    mov rdx, 0          ; clear dividend
    mov rax, r15        ; dividend
    mov rcx, 0x3       ; divisor (divide by 100)
    div rcx             ; EAX = result, EDX = remainder
    ret

div_by_five:
    mov rdx, 0          ; clear dividend
    mov rax, r15        ; dividend
    mov rcx, 0x5       ; divisor (divide by 100)
    div rcx             ; EAX = result, EDX = remainder
    ret

print_LF:
; prints Line Feed
; using stack for this
    mov r13, 0xA        ; 0xA is Line Feed
    push r13            ; push to stack

    mov rax, 1
    mov rdi, 1
    mov rsi, rsp        ; using stack pointer
    mov rdx, 1
    syscall
    pop r13             ; remove from stack
    ret

print_string: 
; needs the following conditions
; r14 - pointer to buffer
; r15 - length
    mov rax, 1          ; syscall # 1
    mov rdi, 1          ; set o STDO
    mov rsi, r14        ; set the pointer to string buffer
    mov rdx, r15        ; set the length of string
    syscall
    ret

print_num:
; Prints  the whole 3-digit number

    mov r15, r8    ; prepare to convert from hex to dec function
    call hex_to_dec

; Part below needs 3 digi number stored in memory. 
; This is done in hex_to_dec function. Ensure this is done beofore calling.

    mov r14b, [number]
    call print_digit

    mov r14b, [number + 1]
    call print_digit

    mov r14b, [number + 2]
    call print_digit

    ret

print_digit: 
; needs single digit hex number (0x0 to 0x9) in 
; r14 - hex number to be printed
; changes to decimal and prints
; only prints one digit

    mov r13, 0x30       ; 0x30 is the offset to change hex # to decimal (from ASCII)
    add r14, r13        ; add offset to the passed hex
    mov [digit], r14b   ; save this to mem (only lower byte)

    mov rax, 1          ; syscall # 1
    mov rdi, 1          ; STDO
    mov rsi, digit      ; pointer to buffer
    mov rdx, 0x1        ; length of the string
    syscall
    ret

hex_to_dec:
; r15 - dividend
; upon exit stack will have - 1s, 10s, and 100s all in decimal
; divide by 100, multiply remainder by 100, divide by 10, multiply remainder by 10
; save remainder

    pop r12             ; save return address
    ; 100s
    mov rdx, 0          ; clear dividend
    mov rax, r15        ; dividend
    mov rcx, 0x64       ; divisor (divide by 100)
    div rcx             ; EAX = result, EDX = remainder
    mov [number], al    ; save 100s
    mov rax, rdx
    
    ; 10s
    mov rdx, 0          ; clear 
    mov rcx, 0xA        ; divide by 10
    div rcx
    mov [number + 1], al    ; save 10s
    mov rax, rdx
    
    ; 1s 
    mov [number + 2], dl    ; save 1s

    push r12            ; retrieve return address onto stack
    ret


_exit:
; proper exit syscall
    mov rax, 60
    mov rdi, 0
    syscall

section .data
    fizz_word: db "Fizz"
    fizz_l: equ $ - fizz_word
    buzz_word: db "Buzz"
    buzz_l: equ $ - buzz_word


section .bss
    digit: resd 1       ; allocating 1 BYTE for digit
    number: resd 3      ; allocating 3 BYTES for number
    print_num_tf: resd 1     ; print number flag


