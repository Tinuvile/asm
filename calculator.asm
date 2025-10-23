section .data
    msg1 db 'Simple Calculator Demo', 0xA, 0
    msg1_len equ $ - msg1 - 1
    
    msg2 db 'Computing: 15 + 25 = ', 0
    msg2_len equ $ - msg2
    
    msg3 db 'Computing: 50 - 10 = ', 0
    msg3_len equ $ - msg3
    
    msg4 db 'Computing: 8 * 7 = ', 0
    msg4_len equ $ - msg4
    
    newline db 0xA, 0
    newline_len equ $ - newline - 1

section .bss
    result resb 10      ; 用于存储结果字符串的缓冲区

section .text
    global _start

_start:
    ; 打印标题
    mov rax, 1
    mov rdi, 1
    mov rsi, msg1
    mov rdx, msg1_len
    syscall

    ; 计算并显示 15 + 25
    mov rax, 1
    mov rdi, 1
    mov rsi, msg2
    mov rdx, msg2_len
    syscall
    
    mov rax, 15         ; 第一个数
    mov rbx, 25         ; 第二个数
    add rax, rbx        ; 相加
    call print_number   ; 打印结果
    
    ; 计算并显示 50 - 10
    mov rax, 1
    mov rdi, 1
    mov rsi, msg3
    mov rdx, msg3_len
    syscall
    
    mov rax, 50         ; 第一个数
    mov rbx, 10         ; 第二个数
    sub rax, rbx        ; 相减
    call print_number   ; 打印结果
    
    ; 计算并显示 8 * 7
    mov rax, 1
    mov rdi, 1
    mov rsi, msg4
    mov rdx, msg4_len
    syscall
    
    mov rax, 8          ; 第一个数
    mov rbx, 7          ; 第二个数
    mul rbx             ; 相乘（结果在rax中）
    call print_number   ; 打印结果

    ; 退出程序
    mov rax, 60
    mov rdi, 0
    syscall

; 函数：将rax中的数字打印为字符串
print_number:
    push rax
    push rbx
    push rcx
    push rdx
    
    mov rbx, 10         ; 除数（十进制）
    mov rcx, 0          ; 计数器
    
convert_loop:
    xor rdx, rdx        ; 清零rdx
    div rbx             ; rax / 10, 商在rax，余数在rdx
    add rdx, '0'        ; 将余数转换为ASCII字符
    push rdx            ; 将字符压入栈中
    inc rcx             ; 增加字符计数
    test rax, rax       ; 检查商是否为0
    jnz convert_loop    ; 如果不为0，继续循环

print_loop:
    pop rdx             ; 从栈中弹出字符
    mov [result], dl    ; 将字符存储到结果缓冲区
    
    ; 打印单个字符
    mov rax, 1
    mov rdi, 1
    mov rsi, result
    mov rdx, 1
    syscall
    
    loop print_loop     ; 循环直到rcx为0
    
    ; 打印换行符
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, newline_len
    syscall
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
