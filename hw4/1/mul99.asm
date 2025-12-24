section .data
    mul_sign db "x"
    eq_sign  db "="
    tab_char db 9    ; ASCII for tab (\t)
    newline  db 10   ; ASCII for newline (\n)

section .bss
    num_buf  resb 8  ; 用于整数转字符串的临时缓冲区

section .text
    global _start

_start:
    ; --- 初始化外层循环计数器 (行 i) ---
    mov r12, 1          ; r12 = i = 1

outer_loop:
    cmp r12, 9          ; 检查 i > 9
    jg  exit_program    ; 如果大于 9，程序结束

    ; --- 初始化内层循环计数器 (列 j) ---
    mov r13, 1          ; r13 = j = 1

inner_loop:
    cmp r13, r12        ; 检查 j > i (实现三角形打印)
    jg  end_inner       ; 如果 j > i，结束本行

    ; 1. 打印 j (列号)
    mov rax, r13
    call print_int      ; 【过程调用】打印 j

    ; 2. 打印 "x"
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, mul_sign   ; buffer
    mov rdx, 1          ; length
    syscall

    ; 3. 打印 i (行号)
    mov rax, r12
    call print_int      ; 【过程调用】打印 i

    ; 4. 打印 "="
    mov rax, 1
    mov rdi, 1
    mov rsi, eq_sign
    mov rdx, 1
    syscall

    ; 5. 计算并打印结果 (i * j)
    mov rax, r12
    imul rax, r13       ; rax = r12 * r13
    call print_int      ; 【过程调用】打印结果

    ; 6. 打印制表符 (Tab) 分隔
    mov rax, 1
    mov rdi, 1
    mov rsi, tab_char
    mov rdx, 1
    syscall

    ; --- 内层循环更新 ---
    inc r13             ; j++
    jmp inner_loop

end_inner:
    ; --- 换行 ---
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; --- 外层循环更新 ---
    inc r12             ; i++
    jmp outer_loop

exit_program:
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; status 0
    syscall

; ==========================================================
; 过程: print_int
; 功能: 将 RAX 中的无符号整数转换为字符串并打印到 stdout
; 输入: RAX (要打印的数字)
; 修改: RAX, RCX, RDX, RSI, RDI, R11 (System V ABI 调用规约中 syscall 会破坏 rcx/r11)
; ==========================================================
print_int:
    ; 保存 rbx (作为除数寄存器，虽然这里可以直接用立即数，但为了稳健)
    push rbx
    
    ; 指向缓冲区末尾 (栈式填充，从后往前)
    mov rsi, num_buf + 7
    
    ; 确保 rax 不为 0 的特殊处理 (本程序 1-81 不会是 0，但通用函数应考虑)
    ; 这里为了简化，直接进入转换循环
    
    mov rbx, 10         ; 除数 = 10

convert_loop:
    xor rdx, rdx        ; 清空 rdx，因为 div 使用 rdx:rax
    div rbx             ; rax / 10 -> 商在 rax，余数在 rdx
    add dl, '0'         ; 将余数转换为 ASCII
    dec rsi             ; 指针前移
    mov [rsi], dl       ; 存入缓冲区
    
    test rax, rax       ; 检查商是否为 0
    jnz convert_loop    ; 如果不为 0，继续循环

    ; --- 打印转换后的字符串 ---
    ; 计算长度: (num_buf + 7) - rsi
    mov rdx, num_buf + 7
    sub rdx, rsi        ; rdx 现在是字符串长度

    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    ; rsi 已经指向字符串开头
    syscall

    pop rbx             ; 恢复 rbx
    ret                 ; 【返回指令】返回调用点