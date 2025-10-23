section .data
    hello_msg db 'Hello, Assembly World!', 0xA, 0    ; 消息字符串，0xA是换行符，0是字符串结束符
    hello_len equ $ - hello_msg - 1                   ; 计算字符串长度（不包括结束符）

section .text
    global _start

_start:
    ; 系统调用：write
    mov rax, 1          ; sys_write 系统调用号
    mov rdi, 1          ; 文件描述符 1 (stdout/标准输出)
    mov rsi, hello_msg  ; 要写入的消息
    mov rdx, hello_len  ; 消息长度
    syscall             ; 执行系统调用

    ; 系统调用：exit
    mov rax, 60         ; sys_exit 系统调用号
    mov rdi, 0          ; 退出状态码 0（成功）
    syscall             ; 执行系统调用
