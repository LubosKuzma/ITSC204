; ITSC204 - Final Project Server Side
; based on socket networking system calls
; x86-64
; Version: 1.0
; Created by Lubos Kuzma
; SADT, SAIT
; on October 2022
; Notes:
; use errorno.h for error numbers
; https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/v0.97/include/linux/errno.h
; Creating socket - socket(2) man
; Binding - ip(7) man
; Listen - listen(2) man
; Accept - accept(2)

SIGPIPE equ 0xD
SIG_IGN equ 0x1
NULL    equ 0x0

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

    hello_msg:   db "Welcome.", 0xA, 0x00
    hello_msg_l: equ $ - hello_msg

    enter_msg:   db 0xA, 0xA, "Enter the number of random bytes you would like.", 0x0A, "Type number between 100 and 4FF:", 0x0A, 0x0
    enter_msg_l: equ $ - enter_msg

    entry_error_msg:   db "Your entry is not a command nor a hex number", 0xA, 0x00
    entry_error_msg_l: equ $ - entry_error_msg

    invalid_entry_msg:   db "Please, enter number between 100 and 4FF.", 0xA, 0x00
    invalid_entry_msg_l: equ $ - invalid_entry_msg

    ; list of commands

    cmd_1_exit: db "exit", 0x0A
    cmd_1_exit_l: equ $ - cmd_1_exit

    sockaddr_in: 
        istruc sockaddr_in_type 

            at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0x901F          ;(DEFAULT, passed on stack) port in hex and big endian order, 8080 -> 0x901F
            at sockaddr_in_type.sin_addr,    dd 0x00            ;(DEFAULT) 00 -> any address, address 127.0.0.1 -> 0x0100007F

        iend
    sockaddr_in_l:  equ $ - sockaddr_in

    

section .bss

    ; global variables
    peer_address_length:     resd 1             ; when Accept is created, the connecting peer will populate this with the address length
    msg_buf:                 resb 1024          ; message buffer
    random_byte:             resb 1             ; reserve 1 byte
    socket_fd:               resq 1             ; socket file descriptor
    read_buffer_fd           resq 1             ; file descriptor for read buffer
    chars_received           resq 1             ; number of characters received from socket
    client_live              resq 1             ; T/F is client connected

section .text
    global _start
    extern sigaction
 
_start:
    push rbp
    mov rbp, rsp

    mov qword [client_live], 0x0


    ; set the SIGPIPE signal to ignore
    mov rdi, rsp
    push SIG_IGN        ; new action -> SIG_IGN 
    mov rsi, rsp        ; pointer to action struct
    mov edx, NULL       ; old action -> NULL
    mov edi, SIGPIPE    ; SIGPIPE    
    mov rax, 0xD        ; rt_sigaction syscall
    mov r10, 0x8        ; size of struc (8 bytes)
    syscall

    add rsp, 0x8        ; restore stack


    call _network.init
    call _network.listen
    .retry:
        call _network.accept
        
        ; write Hello message to socket
        push qword [read_buffer_fd] ; get the fd global variable into local variable 
        push hello_msg_l
        push hello_msg
        call _write_text_to_socket

    .net_read_loop:
    
        ; write Enter message to socket
        push qword [read_buffer_fd] ; get the fd global variable into local variable 
        push enter_msg_l
        push enter_msg
        call _write_text_to_socket

    .net_read_loop_nomsg:

        call _network.read
        call _print_network_buffer
        
        ; check for valid commands
        push qword [chars_received] 
        push msg_buf
        call _read_command
        ; if command is 'exit' then exit
        cmp eax, 0x01
        jz _exit

        ; if command is anything else, perform ascii to hex conversion
        ; ascii to hex

        ; adjust number of chars in buffer to remove \n
        mov rax, qword [chars_received]
        dec rax
        push rax
        push msg_buf
        call _ascii_to_hex
        add rsp, 0x10                       ; clean up
        ;check and validate return value
        cmp rax, 0x100
        jl .invalid_entry
        cmp rax, 0x4FF
        jg .invalid_entry

        push rax                            ; pass argument from previous function to the next function
        call _print_random
        add rsp, 0x8                        ; clean up stack  

        jmp .end_loop
    
    .invalid_entry:
        call _invalid_entry

    .end_loop:
        mov rax, qword [client_live]
        cmp qword rax, 0x01
        jne _start.retry
        jmp _start.net_read_loop_nomsg

    
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
        mov [socket_fd], rax                 ; save the socket fd to basepointer
        call _socket_created

        ; bind, use sockaddr_in struct
        ;       int bind(int sockfd, const struct sockaddr *addr,
        ;            socklen_t addrlen);
        mov rax, 0x31                       ; bind syscall
        mov rdi, qword [socket_fd]          ; sfd
        mov rsi, sockaddr_in                ; sockaddr struct pointer
        mov rdx, sockaddr_in_l              ; address length 
        syscall
        cmp rax, 0x00
        jl _bind_failed
        call _bind_created
        ret

    .listen:
        ; listen
        ; int listen(int sockfd, int backlog);
        mov rax, 0x32                       ; listen syscall
        mov rdi, qword [socket_fd]          ; sfd
        mov rsi, 0x03                       ; maximum backlog of 3 connections
        syscall

        cmp rax, 0x00
        jl _listen_failed
        call _listen_created
        ret

    .accept:
        ; accept
        ;        int accept(int sockfd, struct sockaddr *restrict addr,
        ;              socklen_t *restrict addrlen);
        mov rax, 0x2B                       ; accept syscall
        mov rdi, qword [socket_fd]          ; sfd
        mov rsi, sockaddr_in                ; sockaddr struc pointer
        mov rdx, peer_address_length        ; populated with peer address length
        syscall

        mov qword [read_buffer_fd], rax     ; save new fd of buffer
        mov qword [client_live], 0x1                ; set client connection flag to 1
        ret

    .read:
        mov rax, 0x00                       ; read syscall
        mov rdi, qword [read_buffer_fd]     ; read buffer fd
        mov rsi, msg_buf                    ; buffer pointer where message will be saved
        mov rdx, 1024                       ; message buffer size
        syscall
        
        mov qword [chars_received], rax     ; save number of received chars to global
        ret

    .close:
        mov rax, 0x3                        ; close syscall
        mov rdi, qword [read_buffer_fd]     ; read buffer fd
        syscall
        
        cmp rax, 0x0
        jne _network.close.return
        call _socket_closed
        
        .close.return:
            ret

    .shutdown:
        mov rax, 0x30                       ; close syscall
        mov rdi, qword [socket_fd]          ; sfd
        mov rsi, 0x2                        ; shuwdown RW
        syscall
        
        cmp rax, 0x0
        jne _network.shutdown.return
        call _buffer_closed
        .shutdown.return:
            ret


_print_random:
    ; generates random bytes and prints them RAX times
    ; follows C Call Convention

    ; [rbp + 0x10] -> number of bytes to generate
    
    ; prologue
    push rbp
    mov rbp, rsp
    push rdi
    push rsi

    mov rbx, [rbp + 0x10]       ; load argument 1
    
    .loop:
        ; NOTE: rdrand was introduced in IvyBridge CPU
        ; must add "-cpu IvyBridge" to the x86_64 qemu in the toolbox.sh
        rdrand rax
        jnc .loop                   ; check CF -> 1 = instruction was done correctly
        xor rax, 0xF                ; mask down to one byte
        mov byte [random_byte], al
        dec rbx
        ; write byte message to screen
        push 0x1
        push random_byte
        call _print

    .break:   
        ; write byte message to socket
        push qword [read_buffer_fd]     ; get the fd global variable into local variable 
        push 0x1
        push random_byte
        call _write_text_to_socket

        cmp rbx, 0x00
        jne .loop
        
    ; epilogue
    pop rsi
    pop rdi
    pop rbp
    ret

_ascii_to_hex:
    ; takes the first 8 bytes of the buffer in ascii form
    ; returns hex representation in RAX
    ; follows C Call Convention

    ; prologue
    push rbp
    mov rbp, rsp
    push rdi
    push rsi

    ; [rbp + 0x10] -> buffer pointer
    ; [rbp + 0x18] -> buffer length
    
    xor rbx, rbx        ; clear counter
    xor rcx, rcx        ; clear rcx
    .loop:
        mov rdx, qword [rbp + 0x10]
        mov al, byte [rdx + rbx] ; load ascii payload
        ; do hex validation (must be between 0x30 and 0x39, 0x41 and 0x46)
        ; skip conversion if loaded less than 0x30 (non ASCII)
       
        cmp rax, 0x46
        jg .end_with_error
        ; if letter, subtract 0x37
        cmp rax, 0x40
        jg .letter 
        cmp rax, 0x39
        jg .end_with_error
        cmp rax, 0x30
        jl .end_with_error
        sub rax, 0x30
        jmp .end_bias
    .letter:
        sub rax, 0x37
        jmp .end_bias

    .end_bias:
        or rcx, rax
        shl rcx, 0x04
    .end_loop:
        inc rbx
        cmp rbx, [rbp + 0x18]
        jl .loop

        shr rcx, 0x4
        mov rax, rcx
        jmp .return

    .end_with_error:
        call _entry_error
        mov rax, 0x00

    .return:
    ; epilogue
    pop rsi
    pop rdi
    pop rbp
    ret

_read_command:
    ; check if command is exit
    ; this function can be used to expand command functionality
    ; function returns 0 in rax if no command was found
    ; or command # if one was found in the command list

    ; follows C Calling Convention, except stack clean up, which is done at the end of function

    ; prologue
    push rbp
    mov rbp, rsp
    push rdi
    push rsi

    ; [rbp + 0x10] -> buffer pointer
    ; [rbp + 0x18] -> buffer length
   
    mov edi, [rbp + 0x10]
    mov esi, cmd_1_exit                     ; load the comparison string to string register esi
    repe cmpsb                              ; compare string one byte at the time and repeat while equal
                                            ; the output of this operation (count of how many equal chars is there) is writte
                                            ; is written into eax
    cmp eax, cmd_1_exit_l                   ; compare the number of same characters to number of chrs in test string
    jz .cmd_exit                            ; if they are the same number, strings are the same
   
   ;mov esi, cmd_2_do_something_else
   ;repe cmpsb
   ;cmp eax, cmd_2_do_something_else_l
   ;jz .cmd_do_something_else

    mov eax, 0x00
    jmp .return

    .cmd_exit:
        mov eax, 0x01
        jmp .return

   ;.cmd_do_something_else:
   ;    mov eax, 0x02
   ;    jmp .return

    .return:

    ; epilogue
    pop rsi
    pop rdi
    pop rbp
    ret 0x10                                ; clean up the stack upon return - not strictly following C Calling Convention

_print:
    ; prologue
    push rbp
    mov rbp, rsp
    push rdi
    push rsi

    ; [rbp + 0x10] -> buffer pointer
    ; [rbp + 0x18] -> buffer length
    
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, [rbp + 0x10]
    mov rdx, [rbp + 0x18]
    syscall

    ; epilogue
    pop rsi
    pop rdi
    pop rbp
    ret 0x10                                ; clean up the stack upon return - not strictly following C Calling Convention

_write_text_to_socket:
        
    ; prologue
    push rbp
    mov rbp, rsp
    push rdi
    push rsi

    ; [rbp + 0x10] -> buffer pointer
    ; [rbp + 0x18] -> buffer length
    ; [rbp + 0x20] -> fd of the socket

    mov rax, 0x1
    mov rdi, [rbp + 0x20]
    mov rsi, [rbp + 0x10]
    mov rdx, [rbp + 0x18]
    syscall
    cmp rax, 0x0
    jge .end_fun
    call _client_conn_handler

    .end_fun:
    ; epilogue
    pop rsi
    pop rdi
    pop rbp
    ret 0x18                                ; clean up the stack upon return - not strictly following C Calling Convention    


_print_network_buffer:
    ; print network buffer
    push qword [chars_received]             ; length of message from stack
    push msg_buf                            ; message buffer pointer
    call _print
    ret

_socket_failed:
    ; print socket failed
    push socket_f_msg_l
    push socket_f_msg
    call _print
    jmp _exit

_socket_created:
    ; print socket created
    push socket_t_msg_l
    push socket_t_msg
    call _print
    ret

_bind_failed:
    ; print bind failed
    push bind_f_msg_l
    push bind_f_msg
    call _print
    jmp _exit

_bind_created:
    ; print bind created
    push bind_t_msg_l
    push bind_t_msg
    call _print
    ret

_listen_failed:
    ; print listen failed
    push listen_f_msg_l
    push listen_f_msg
    call _print
    jmp _exit

_listen_created:
    ; print listen created
    push listen_t_msg_l
    push listen_t_msg
    call _print
    ret

_buffer_closed:
    ; print buffer closed
    push buffer_closed_msg_l
    push buffer_closed_msg
    call _print
    ret

_socket_closed:
    ; print socket closed
    push socket_closed_msg_l
    push socket_closed_msg
    call _print
    ret

_entry_error:
    ; print entry error message
    push entry_error_msg_l
    push entry_error_msg
    call _print

    ; write error message to socket
    push qword [read_buffer_fd] ; get the fd global variable into local variable 
    push entry_error_msg_l
    push entry_error_msg
    call _write_text_to_socket
    ret

_invalid_entry:
    ; print invalid entry error message
    push invalid_entry_msg_l
    push invalid_entry_msg
    call _print

    ; write invalid entry error to socket
    push qword [read_buffer_fd] ; get the fd global variable into local variable 
    push invalid_entry_msg_l
    push invalid_entry_msg
    call _write_text_to_socket

    ret

_client_conn_handler:
    mov qword [client_live], 0x00
    ret

_exit:
    call _network.close
    call _network.shutdown

    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall
