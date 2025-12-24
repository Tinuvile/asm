section .data
    prompt db "请输入一个 1 到 100 之间的数字: ", 0
    prompt_len equ $ - prompt
    
    msg_res db "从 1 加到该数的和为: ", 0
    msg_res_len equ $ - msg_res
    
    newline db 10  ; 换行符

section .bss
    input_buf resb 16    ; 预留输入缓冲区
    num_res   resb 16    ; 预留结果字符串缓冲区

section .text
    global _start

_start:
    ; --- 1. 打印提示信息 ---
    mov rax, 1              ; sys_write
    mov rdi, 1              ; file descriptor: stdout
    mov rsi, prompt         ; buffer
    mov rdx, prompt_len     ; count
    syscall

    ; --- 2. 读取用户输入 ---
    mov rax, 0              ; sys_read
    mov rdi, 0              ; file descriptor: stdin
    mov rsi, input_buf      ; buffer
    mov rdx, 16             ; max length
    syscall

    ; --- 3. 字符串转整数 (ATOI) ---
    ; 输入在 input_buf，格式如 "100\n"
    xor rax, rax            ; RAX 将存储最终的数字 N
    xor rcx, rcx            ; RCX 作为临时字符寄存器
    mov rsi, input_buf      ; 指向缓冲区开始

convert_to_int:
    mov cl, [rsi]           ; 取一个字节
    cmp cl, 10              ; 检查是否是换行符 (\n)
    je  calc_start          ; 如果是换行，结束转换
    cmp cl, 0               ; 检查是否是字符串结束
    je  calc_start
    cmp cl, '0'             ; 简单验证：小于 '0' 跳过
    jb  calc_start
    cmp cl, '9'             ; 简单验证：大于 '9' 跳过
    ja  calc_start

    sub cl, '0'             ; 将 ASCII '0'-'9' 转换为数值 0-9
    imul rax, 10            ; 当前结果 * 10
    add rax, rcx            ; 加上新的一位
    inc rsi                 ; 移动指针
    jmp convert_to_int

    ; --- 4. 计算求和 (1 + ... + N) ---
    ; 此时 RAX 中存放的是用户输入的数字 N
calc_start:
    cmp rax, 0              ; 如果输入是0或非法，避免死循环
    jle finish_program      ; 直接退出（或者可以处理报错）

    mov rcx, rax            ; RCX = N (作为循环计数器)
    xor rbx, rbx            ; RBX = 0 (作为累加器 Sum)

sum_loop:
    add rbx, rcx            ; Sum = Sum + Count
    dec rcx                 ; Count--
    jnz sum_loop            ; 如果 RCX != 0，继续循环

    ; 此时 RBX 中存放的是计算结果 (例如输入100，RBX=5050)
    
    ; --- 5. 整数转字符串 (ITOA) ---
    ; 将 RBX 中的数值转换为字符串，存入 num_res
    mov rax, rbx            ; 被除数放到 RAX
    mov rsi, num_res + 15   ; 指向缓冲区末尾 (栈式填充)
    mov byte [rsi], 10      ; 添加换行符
    dec rsi

    mov rcx, 10             ; 除数 10

convert_to_str:
    xor rdx, rdx            ; 清除 RDX (div 指令使用 RDX:RAX 128位除法)
    div rcx                 ; RAX / 10 -> 商在 RAX, 余数在 RDX
    add dl, '0'             ; 将余数 (0-9) 转换为 ASCII
    mov [rsi], dl           ; 存入缓冲区
    dec rsi                 ; 指针前移
    test rax, rax           ; 检查商是否为 0
    jnz convert_to_str      ;如果不为0，继续循环

    ; 此时 RSI 指向结果字符串的前一个位置，需要 +1
    inc rsi                 ; RSI 现在指向结果字符串的开头
    
    ; 计算要打印的长度
    ; 缓冲区末尾地址是 num_res + 16
    ; 当前地址是 RSI
    ; 长度 = (num_res + 16) - RSI
    mov rdx, num_res
    add rdx, 16
    sub rdx, rsi            ; RDX 现在是字符串长度
    
    ; 保存 RSI 和 RDX，因为我们要先打印 msg_res
    push rdx
    push rsi

    ; --- 6. 打印结果前缀 ---
    mov rax, 1              ; sys_write
    mov rdi, 1
    mov rsi, msg_res
    mov rdx, msg_res_len
    syscall

    ; --- 7. 打印计算出的数字 ---
    pop rsi                 ; 恢复数字字符串地址
    pop rdx                 ; 恢复数字字符串长度
    mov rax, 1              ; sys_write
    mov rdi, 1
    syscall

finish_program:
    ; --- 8. 退出程序 ---
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; error code 0
    syscall