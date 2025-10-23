section .data
    newline db 0x0A           ; 换行符

section .bss
    char_buffer resb 1        ; 字符缓冲区

section .text
    global _start

_start:
    mov r8, 97                ; 起始ASCII值 'a' (使用r8避免与系统调用号冲突)
    mov r9, 0                 ; 计数器，用于每行13个字符

print_loop:
    ; 将当前字符存入缓冲区
    mov [char_buffer], r8b    ; 存储字符到缓冲区
    
    ; 系统调用write输出字符
    mov rax, 1                ; sys_write
    mov rdi, 1                ; stdout
    mov rsi, char_buffer      ; 字符缓冲区地址
    mov rdx, 1                ; 输出1个字节
    syscall
    
    inc r9                    ; 增加计数器
    inc r8                    ; 下一个ASCII字符
    
    ; 检查是否需要换行（每13个字符）
    cmp r9, 13
    jne check_end
    
    ; 输出换行符
    mov rax, 1                ; sys_write
    mov rdi, 1                ; stdout
    mov rsi, newline          ; 换行符地址
    mov rdx, 1                ; 输出1个字节
    syscall
    
    mov r9, 0                 ; 重置计数器

check_end:
    ; 检查是否已输出完所有小写字母（a-z）
    cmp r8, 123               ; 'z'的ASCII值是122，所以检查123
    jl print_loop
    
    ; 如果最后一行不足13个字符，也要换行
    cmp r9, 0
    je exit
    
    ; 输出最后的换行符
    mov rax, 1                ; sys_write
    mov rdi, 1                ; stdout
    mov rsi, newline          ; 换行符地址
    mov rdx, 1                ; 输出1个字节
    syscall

exit:
    ; 正常退出程序
    mov rax, 60               ; sys_exit
    mov rdi, 0                ; 退出状态码
    syscall
