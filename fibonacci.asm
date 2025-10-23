section .data
    title_msg db 'Fibonacci Sequence Generator', 0xA, 0
    title_len equ $ - title_msg - 1
    
    msg1 db 'Generating first 10 Fibonacci numbers:', 0xA, 0
    msg1_len equ $ - msg1 - 1
    
    comma db ', ', 0
    comma_len equ $ - comma - 1
    
    newline db 0xA, 0
    newline_len equ $ - newline - 1

section .bss
    result resb 20      ; 缓冲区用于数字转字符串

section .text
    global _start

_start:
    ; 打印标题
    mov rax, 1
    mov rdi, 1
    mov rsi, title_msg
    mov rdx, title_len
    syscall
    
    ; 打印说明
    mov rax, 1
    mov rdi, 1
    mov rsi, msg1
    mov rdx, msg1_len
    syscall

    ; 初始化斐波那契数列
    mov rbx, 0          ; F(0) = 0
    mov rcx, 1          ; F(1) = 1
    mov r8, 10          ; 计数器，生成10个数

    ; 打印第一个数字 (0)
    mov rax, rbx
    call print_number
    
    dec r8              ; 减少计数器
    jz done             ; 如果只需要一个数字，就完成

print_comma1:
    ; 打印逗号和空格
    mov rax, 1
    mov rdi, 1
    mov rsi, comma
    mov rdx, comma_len
    syscall

    ; 打印第二个数字 (1)
    mov rax, rcx
    call print_number
    
    dec r8              ; 减少计数器
    jz done             ; 如果只需要两个数字，就完成

fibonacci_loop:
    ; 打印逗号和空格
    mov rax, 1
    mov rdi, 1
    mov rsi, comma
    mov rdx, comma_len
    syscall
    
    ; 计算下一个斐波那契数: F(n) = F(n-1) + F(n-2)
    mov rax, rbx        ; rax = F(n-2)
    add rax, rcx        ; rax = F(n-2) + F(n-1) = F(n)
    
    ; 更新变量准备下一次迭代
    mov rbx, rcx        ; F(n-2) = 旧的F(n-1)
    mov rcx, rax        ; F(n-1) = 新计算的F(n)
    
    ; 打印当前的斐波那契数
    call print_number
    
    ; 检查是否完成
    dec r8
    jnz fibonacci_loop

done:
    ; 打印最终换行符
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, newline_len
    syscall

    ; 退出程序
    mov rax, 60
    mov rdi, 0
    syscall

; 函数：将rax中的数字转换为字符串并打印
print_number:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    
    ; 处理特殊情况：数字为0
    test rax, rax
    jnz convert_start
    
    ; 如果是0，直接打印字符'0'
    mov byte [result], '0'
    mov rax, 1
    mov rdi, 1
    mov rsi, result
    mov rdx, 1
    syscall
    jmp print_number_end

convert_start:
    mov rbx, 10         ; 除数
    mov rcx, 0          ; 字符计数器
    mov rsi, result     ; 指向结果缓冲区的末尾
    add rsi, 19         ; 指向缓冲区末尾

convert_loop:
    xor rdx, rdx        ; 清零rdx用于除法
    div rbx             ; rax / 10，商在rax，余数在rdx
    add rdx, '0'        ; 将余数转换为ASCII字符
    dec rsi             ; 向前移动指针
    mov [rsi], dl       ; 存储字符
    inc rcx             ; 增加字符计数
    test rax, rax       ; 检查商是否为0
    jnz convert_loop    ; 如果不为0，继续循环

    ; 打印转换后的字符串
    mov rax, 1
    mov rdi, 1
    ; rsi已经指向字符串的开始
    mov rdx, rcx        ; 字符串长度
    syscall

print_number_end:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
