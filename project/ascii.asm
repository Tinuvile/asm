section .data
    newline db 0xA, 0               ; 换行符
    newline_len equ $ - newline - 1

section .bss
    char_buffer resb 1              ; 单个字符缓冲区

section .text
    global _start

_start:
    mov bl, 'a'                     ; bl寄存器存储当前字符，从'a'开始
    mov r8, 0                       ; r8用于计数每行输出的字符数
    mov r9, 2                       ; r9表示总行数（26个字母分2行，每行13个）

row_loop:
    mov rcx, 13                     ; 设置内层循环计数器：每行13个字符
    
char_loop:
    ; 检查是否已经超过'z'
    cmp bl, 'z'
    ja done                         ; 如果超过'z'，结束程序
    
    ; 将当前字符存储到缓冲区
    mov [char_buffer], bl
    
    ; 系统调用：输出当前字符
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    mov rsi, char_buffer            ; 字符缓冲区
    mov rdx, 1                      ; 写入1个字节
    syscall
    
    ; 移动到下一个字符
    inc bl
    
    ; 继续内层循环
    loop char_loop                  ; loop指令：rcx自动减1，如果rcx!=0则跳转
    
    ; 内层循环结束，输出换行符
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    mov rsi, newline                ; 换行符
    mov rdx, newline_len            ; 换行符长度
    syscall
    
    ; 检查是否还有更多行要输出
    dec r9                          ; 行计数器减1
    jnz row_loop                    ; 如果还有行未输出，继续外层循环

done:
    ; 程序结束
    mov rax, 60                     ; sys_exit
    mov rdi, 0                      ; 退出状态码
    syscall

; 程序说明：
; 1. 使用bl寄存器存储当前要输出的字符
; 2. 使用rcx作为loop指令的计数器，每行输出13个字符
; 3. 使用r8计数每行已输出的字符数
; 4. 使用r9控制总行数
; 5. loop指令会自动将rcx减1，并在rcx不为0时跳转
; 6. 每行结束后输出换行符，然后继续下一行
