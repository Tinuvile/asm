; ==========================================
; 简易 HTTP 服务器 (The Assembly Web Server)
; 架构: x86-64 Linux (Works on WSL)
; 功能: 监听 8080 端口，响应 "Hello from ASM"
; ==========================================

section .data
    ; --- HTTP 响应报文 ---
    response_text:  db "HTTP/1.1 200 OK", 0x0D, 0x0A
                    db "Content-Type: text/html", 0x0D, 0x0A
                    db "Content-Length: 27", 0x0D, 0x0A 
                    db "Connection: close", 0x0D, 0x0A
                    db 0x0D, 0x0A                       ; Header 结束的空行
                    ; Body 部分
                    db "<h1>Hello from NASM!</h1>", 0x0D, 0x0A
    response_len:   equ $ - response_text

    ; --- Sockaddr_in 结构体 (16 bytes) ---
    ; struct sockaddr_in {
    ;    short sin_family;   // 2 bytes (AF_INET = 2)
    ;    short sin_port;     // 2 bytes (Big Endian)
    ;    long  sin_addr;     // 4 bytes
    ;    long  sin_zero;     // 8 bytes (padding)
    ; }
    sockaddr:
        dw 2                ; AF_INET (2)
        dw 0x901F           ; Port 8080. Hex: 0x1F90. 小端序内存存为: 90 1F -> 网络大端序读为 1F 90
        dd 0                ; IP: 0.0.0.0 (INADDR_ANY)
        dq 0                ; Padding

    ; --- Reuse Address 选项值 ---
    reuse_val: dd 1

section .bss
    server_fd: resq 1       ; 存放服务器 Socket 文件描述符
    client_fd: resq 1       ; 存放客户端 Socket 文件描述符
    read_buf:  resb 4096    ; 接收缓冲区

section .text
    global _start

_start:
    ; 1. 创建 Socket
    ; socket(AF_INET, SOCK_STREAM, 0)
    ; syscall number 41
    mov rax, 41
    mov rdi, 2              ; AF_INET
    mov rsi, 1              ; SOCK_STREAM (TCP)
    mov rdx, 0              ; Protocol (IP)
    syscall

    ; 检查错误 (rax < 0)
    cmp rax, 0
    jl _exit_error
    mov [server_fd], rax    ; 保存 server_fd

    ; 1.5 设置 SO_REUSEADDR (可选，但调试时重要，防止 Address already in use)
    ; setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &reuse_val, sizeof(reuse_val))
    ; syscall number 54
    mov rax, 54
    mov rdi, [server_fd]
    mov rsi, 1              ; SOL_SOCKET
    mov rdx, 2              ; SO_REUSEADDR
    mov r10, reuse_val      ; 指向参数值的指针
    mov r8, 4               ; 参数长度
    syscall

    ; 2. 绑定端口 (Bind)
    ; bind(server_fd, &sockaddr, 16)
    ; syscall number 49
    mov rax, 49
    mov rdi, [server_fd]
    mov rsi, sockaddr       ; 结构体地址
    mov rdx, 16             ; 结构体长度
    syscall

    cmp rax, 0
    jl _exit_error

    ; 3. 开始监听 (Listen)
    ; listen(server_fd, backlog)
    ; syscall number 50
    mov rax, 50
    mov rdi, [server_fd]
    mov rsi, 10             ; Backlog (等待队列长度)
    syscall

    cmp rax, 0
    jl _exit_error

    ; print "Server running..." (Optional feedback)
    ; 这里省略，直接进入主循环

_server_loop:
    ; 4. 接受连接 (Accept) - 阻塞点
    ; accept(server_fd, NULL, NULL)
    ; syscall number 43
    mov rax, 43
    mov rdi, [server_fd]
    mov rsi, 0              ; 不关心客户端 IP 信息，设为 NULL
    mov rdx, 0
    syscall

    cmp rax, 0
    jl _server_loop         ; 如果 accept 失败，尝试继续循环
    mov [client_fd], rax    ; 保存 client_fd

    ; 5. 读取请求 (Read)
    ; 虽然不解析 GET 请求，但须读取数据以清除 TCP 接收缓冲区
    ; read(client_fd, read_buf, 4096)
    ; syscall number 0
    mov rax, 0
    mov rdi, [client_fd]
    mov rsi, read_buf
    mov rdx, 4096
    syscall

    ; 6. 发送响应 (Write)
    ; write(client_fd, response_text, response_len)
    ; syscall number 1
    mov rax, 1
    mov rdi, [client_fd]
    mov rsi, response_text
    mov rdx, response_len
    syscall

    ; 7. 关闭客户端连接 (Close)
    ; close(client_fd)
    ; syscall number 3
    mov rax, 3
    mov rdi, [client_fd]
    syscall

    ; 8. 回到循环开始
    jmp _server_loop

_exit_error:
    ; 退出程序 (Error)
    mov rax, 60         ; sys_exit
    mov rdi, 1          ; error code 1
    syscall