[bits 64]

%ifdef MACOSX

  %define SYS_SOCKET 	0x02000061
  %define SYS_BIND 	0x02000068
  %define SYS_LISTEN 	0x0200006A
  %define SYS_ACCEPT 	0x0200001E
  %define SYS_CLOSE 	0x02000006
  %define SYS_READ 	0x02000003
  %define SYS_OPEN 	0x02000005
  %define SYS_WRITE 	0x02000004
  %define SYS_EXIT 	0x02000001

%else
  %ifdef BSD

    %define SYS_SOCKET 	0x61
    %define SYS_BIND 	0x68
    %define SYS_LISTEN 	0x6A
    %define SYS_ACCEPT 	0x1E
    %define SYS_CLOSE 	0x06
    %define SYS_READ 	0x03
    %define SYS_OPEN 	0x05
    %define SYS_WRITE 	0x04
    %define SYS_EXIT 	0x01

  %else

    %define SYS_SOCKET 	41
    %define SYS_BIND 	49
    %define SYS_LISTEN 	50
    %define SYS_ACCEPT 	43
    %define SYS_CLOSE 	3
    %define SYS_READ 	0
    %define SYS_OPEN 	2
    %define SYS_WRITE 	1
    %define SYS_EXIT 	60

  %endif
%endif


global _start

_start:

  call main

  mov rdi,rax
  xor rax,SYS_EXIT
  
  syscall
  
  
main:

  mov rax, SYS_SOCKET ; sys_socket 
  mov rdi, 2 ; PF_INET
  mov rsi, 1 ; SOCK_STREAM
  mov rdx, 0 
  syscall
  mov [rel ssock], eax
  cmp eax,0
  jl end
  
  mov rax, SYS_BIND ; sys_bind 
  xor rdi,rdi
  mov edi, [rel ssock]
  mov rsi, QWORD addr_in
  mov rdx, 16
  syscall 
  cmp eax,0
  jl end
  
  mov rax, SYS_LISTEN ; sys_listen 
  xor rdi,rdi
  mov edi, [rel ssock]
  xor rsi, rsi
  syscall
  cmp eax,0
  jl end
  
  cikl1:
   
  mov rax, SYS_ACCEPT ; sys_accept 
  xor rdi,rdi
  mov edi, [rel ssock]
  mov rsi, 0
  mov rdx, 0
  syscall 
  mov [rel csock], eax
  
  call send_file
 
  
  mov rax, SYS_CLOSE ; sys_close
  xor rdi,rdi
  mov edi, [rel csock]
  syscall 
  
  jmp cikl1
 
  xor rax,rax

  end:
  
ret


request:

  mov r10,4

  mov rax, SYS_READ ; sys_read 
  xor rdi,rdi
  mov edi, [rel csock]
  mov rsi, QWORD buffer
  mov rdx, 4096
  syscall 
  
  cmp rax,4
  jle request_end
  mov al, [rel buffer]
  cmp al,'G'
  jne request_end
  mov al, [rel buffer+1]
  cmp al,'E'
  jne request_end
  mov al, [rel buffer+2]
  cmp al,'T'
  jne request_end
  
  
  
  mov r10, QWORD buffer
  add r10,3
  mov al,'.'
  mov [r10],al
  add r10,1
    
  request_loop:
  
    mov al,[r10]
    cmp al,' '
    je request_loop_end
    
    inc r10
    
    jmp request_loop
    
  request_loop_end:
  
    xor al,al
    mov [r10],al
  
    mov rax,1
    
    ret
  
  request_end:
  
    xor rax,rax
  
ret


send_file:

  call request

  ;cmp rax,0
  ;je send_file_end2
  
   
  mov rdi, QWORD buffer
  add rdi,3
  mov rax, SYS_OPEN ; sys_open
  xor rsi, rsi 
  xor rdx, rdx
  syscall 
  ;cmp rax,0
  ;jl send_file_end1
  
  mov r10,rax
  
;   mov rax, SYS_WRITE ; sys_write
;   mov rdi, [rel csock]
;   mov rsi, QWORD header200
;   mov rdx, header200len
;   syscall 
;   cmp rax,0
;   jl send_file_end2
  
  send_file_loop:
  

    mov rdi, r10
    mov rax, SYS_READ ; sys_read
    mov rsi, QWORD buffer
    mov rdx, 4096
    syscall 
    cmp rax,0
    jle send_file_end2
    
    mov rdx, rax
    mov rdi, [rel csock]
    mov rax, SYS_WRITE ; sys_write
    mov rsi, QWORD buffer
    syscall 
    cmp rax,0
    jl send_file_end2
    
    
    
    jmp send_file_loop
  
  send_file_end1:
  
    ;mov rax, SYS_WRITE ; sys_write
    ;mov rdi, [rel csock]
    ;mov rsi, QWORD header404
    ;mov rdx, header404len
    ;syscall 
    
  send_file_end2:
  
  mov rdi, r10
  mov rax, 3 ; sys_close
  syscall 
  
ret


; Data

section .data
ssock: dd 0
csock: dd 0

addr_in: 
  dw 2 ; AF_INET
  dw 0x5000
  dd 0
  db 0,0,0,0,0,0,0,0
  
  
; header200: db "HTTP/1.0 200 Ok",13,10,"Content-Type: text/html",13,10,13,10
; header200len equ $-header200

;header404: db "HTTP/1.0 404 Not found",13,10,"Content-Type: text/html",13,10,"Content-Length: 96",13,10,13,10,"<html><head><title>404 Not found</title></head><body><p><h1>404 Not found</h1></p></body></html>"
;header404len equ $-header404

section .bss

buffer: resb 4096
