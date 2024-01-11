; testing socket networking system call
; x86-64
; Notes:
; use errorno.h for error numbers
; https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/v0.97/include/linux/errno.h
; Creating socket - socket(2) man
; Binding - ip(7) man
; Listen - listen(2) man
; Accept - accept(2)

; global variables on the stack
; rbp+0x0 -> socket fd #
; rbp+0x8 -> read buffer fd #
; rbp+0x10 -> number of characters received from network buffer

;*****************************
struc sockaddr_in_type
; defined in man ip(7) because it's dependent on the type of address
    .sin_family:        resw 1
    .sin_port:          resw 1
    .sin_addr:          resd 1
    .sin_zero:          resd 2          ; padding       
endstruc

;*****************************


section .data

    socket_f_msg:   db "Socket failed to be created.", 0xA, 0x0
    socket_f_msg_l: equ $ - socket_f_msg

    socket_t_msg:   db "Socket created.", 0xA, 0x0
    socket_t_msg_l: equ $ - socket_t_msg

    bind_f_msg:   db "Socket failed to bind.", 0xA, 0x0
    bind_f_msg_l: equ $ - bind_f_msg

    bind_t_msg:   db "Socket bound.", 0xA, 0x0
    bind_t_msg_l: equ $ - bind_t_msg

    listen_f_msg:   db "Failed to start listening.", 0xA, 0x0
    listen_f_msg_l: equ $ - listen_f_msg

    listen_t_msg:   db "Listening.", 0xA, 0x0
    listen_t_msg_l: equ $ - listen_t_msg

    buffer_closed_msg:   db "Buffer closed.", 0xA, 0x0
    buffer_closed_msg_l: equ $ - buffer_closed_msg

    socket_closed_msg:   db "Socket closed.", 0xA, 0x0
    socket_closed_msg_l: equ $ - socket_closed_msg

    sockaddr_in: 
        istruc sockaddr_in_type 

            at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0x901F          ;port in hex and big endian order, 8080 -> 0x901F
            at sockaddr_in_type.sin_addr,    dd 0x00            ;00 -> any address, address 127.0.0.1 -> 0x0100007F

        iend
    sockaddr_in_l: equ $ - sockaddr_in


section .bss

    peer_address_length:     resd 1             ; when Accept is created, the connecting peer will populate this with the address length
    msg_buf:                 resb 1024          ; message buffer

section .text
    global _start




_start:
    push rbp
    sub rsp, 0x100                      ; allocate 0x100 bytes for variables below base pointer
    mov rbp, rsp

    call _network.init
    call _network.listen
    call _network.accept
    call _network.read

    ; addition code to be insterted here, if you don't want the program to shutdown after one message

    jmp _exit

_network:
.init:
    ; socket, based on IF_INET to get tcp
    mov rax, 0x29                       ; socket syscall
    mov rdi, 0x02                       ; int domain - AF_INET = 2, AF_LOCAL = 1
    mov rsi, 0x01                       ; int type - SOCK_STREAM = 1
    mov rdx, 0x00                       ; int protocol is 0
    syscall     
    cmp rax, 0x00
    jl _socket_failed                   ; jump if negative
    mov [rbp+0x00], rax                 ; save the socket fd to basepointer
    call _socket_created

    ; bind, use sockaddr_in struct
    ;       int bind(int sockfd, const struct sockaddr *addr,
    ;            socklen_t addrlen);
    mov rax, 0x31                       ; bind syscall
    mov rdi, qword [rbp + 0x00]         ; sfd (rbp-0)
    mov rsi, sockaddr_in                ; sockaddr struct pointer
    mov rdx, sockaddr_in_l              ; address length 
    syscall
    cmp rax, 0x00
    jl _bind_failed
;    push rax
    call _bind_created
    ret

.listen:
    ; listen
    ; int listen(int sockfd, int backlog);
    mov rax, 0x32                       ; listen syscall
    mov rdi, qword [rbp + 0x00]         ; sfd (rbp-0)
    mov rsi, 0x03                       ; maximum backlog of 3 connections
    syscall
    cmp rax, 0x00
    jl _listen_failed
 ;   push rax
    call _listen_created
    ret

.accept:
    ; accept
    ;        int accept(int sockfd, struct sockaddr *restrict addr,
    ;              socklen_t *restrict addrlen);
    mov rax, 0x2B                       ; accept syscall
    mov rdi, qword [rbp + 0x00]         ; sfd (rbp-0)
    mov rsi, sockaddr_in                ; sockaddr struc pointer
    mov rdx, peer_address_length        ; populated with peer address length
    syscall
    mov qword [rbp + 0x08], rax         ; save new fd of buffer
    ret

.read:
    mov rax, 0x00                       ; read syscall
    mov rdi, qword [rbp + 0x08]         ; buffer fd (rbp-8)
    mov rsi, msg_buf                    ; buffer pointer where message will be saved
    mov rdx, 1024                       ; message buffer size
    syscall
    mov qword [rbp + 0x10], rax            ; save number of received chars to stack
    call _write_network_buffer
    ret

.close:
    mov rax, 0x3                       ; close syscall
    mov rdi, qword [rbp + 0x08]        ; buffer fd (rbp-8)
    syscall
    cmp rax, 0x0
    jne _network.close.return
    call _socket_closed
.close.return:
    ret

.shutdown:
    mov rax, 0x30                      ; close syscall
    mov rdi, qword [rbp + 0x00]        ; sfd (rbp-0)
    mov rsi, 0x2                       ; shuwdown RW
    syscall
    cmp rax, 0x0
    jne _network.shutdown.return
    call _buffer_closed
.shutdown.return:
    ret



_write_network_buffer:
    mov r14, msg_buf                    ; message buffer pointer
    mov r15, [rbp + 0x10]                 ; length of message from stack
    call _print
    ret

_socket_failed:
    mov r14, socket_f_msg
    mov r15, socket_f_msg_l
    call _print
    jmp _exit

_socket_created:
    mov r14, socket_t_msg
    mov r15, socket_t_msg_l
    call _print
    ret

_bind_failed:
    mov r14, bind_f_msg
    mov r15, bind_f_msg_l
    call _print
    jmp _exit

_bind_created:
    mov r14, bind_t_msg
    mov r15, bind_t_msg_l
    call _print
    ret

_listen_failed:
    mov r14, listen_f_msg
    mov r15, listen_f_msg_l
    call _print
    jmp _exit

_listen_created:
    mov r14, listen_t_msg
    mov r15, listen_t_msg_l
    call _print
    ret

_buffer_closed:
    mov r14, buffer_closed_msg
    mov r15, buffer_closed_msg_l
    call _print
    ret

_socket_closed:
    mov r14, socket_closed_msg
    mov r15, socket_closed_msg_l
    call _print
    ret

_print:
    ; needs r14 - buffer; r15 - length 
    mov rax, 0x1                        ; write syscall
    mov rdi, 0x1                        ; STDOUT FD
    mov rsi, r14                        ; *buf
    mov rdx, r15                        ; length
    syscall
    ret


_exit:
    call _network.close
    call _network.shutdown

    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall
