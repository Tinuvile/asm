section .data
    ; --- 这里是你提供的带有错误的数据表 ---
    table   db 7,2,3,4,5,6,7,8,9              ; Row 1: 1x1=7 (Error, should be 1)
            db 2,4,7,8,10,12,14,16,18         ; Row 2: 2x3=7 (Error, should be 6)
            db 3,6,9,12,15,18,21,24,27        ; Row 3: Correct
            db 4,8,12,16,7,24,28,32,36        ; Row 4: 4x5=7 (Error, should be 20)
            db 5,10,15,20,25,30,35,40,45      ; Row 5: Correct
            db 6,12,18,24,30,7,42,48,54       ; Row 6: 6x6=7 (Error, should be 36)
            db 7,14,21,28,35,42,49,56,63      ; Row 7: Correct
            db 8,16,24,32,40,48,56,7,72       ; Row 8: 8x8=7 (Error, should be 64)
            db 9,18,27,36,45,54,63,72,81      ; Row 9: Correct

    ; --- 字符串常量 ---
    header_msg db "Row Col Status", 10, "----------------", 10, 0
    space      db "   ", 0           ; 间隔空格
    msg_err    db " error", 10, 0    ; 错误提示并换行
    msg_fin    db 10, "finished!", 10, 0

section .bss
    num_buf resb 8                   ; 数字转字符串缓冲区

section .text
    global _start

_start:
    ; 打印表头
    mov rsi, header_msg
    call print_string

    ; --- 主过程寄存器规划 ---
    ; r12 = 当前行 (row), 1-9
    ; r13 = 当前列 (col), 1-9
    ; rbx = 表的基地址

    lea rbx, [table]        ; 加载表地址
    mov r12, 1              ; 初始化行计数器

row_loop:
    cmp r12, 9
    jg  finish_check        ; 如果行 > 9，结束

    mov r13, 1              ; 初始化列计数器

col_loop:
    cmp r13, 9
    jg  next_row            ; 如果列 > 9，换行

    ; --- 核心逻辑调用 ---
    ; 调用 check_cell 过程
    ; 这里体现了过程调用，且过程内部会使用 r12, r13, rbx 这些主过程的资源
    call check_cell

    inc r13                 ; 列++
    jmp col_loop

next_row:
    inc r12                 ; 行++
    jmp row_loop

finish_check:
    ; 打印完成信息
    mov rsi, msg_fin
    call print_string

    ; 退出程序
    mov rax, 60             ; sys_exit
    xor rdi, rdi
    syscall

; ==========================================================
; 过程: check_cell
; 功能: 计算理论值并与内存中的值比较
; 依赖: 使用主程序的 r12(row), r13(col), rbx(table base)
; ==========================================================
check_cell:
    ; 1. 计算内存偏移量 Index = (Row-1)*9 + (Col-1)
    mov rax, r12
    dec rax                 ; rax = row - 1
    mov rcx, 9
    mul rcx                 ; rax = (row-1) * 9
    add rax, r13
    dec rax                 ; rax = (row-1)*9 + (col-1) -> Index

    ; 2. 获取内存中的实际值 (Actual)
    xor rdx, rdx            ; 清空 rdx 用于存放读取的字节
    mov dl, [rbx + rax]     ; 从 table[Index] 读取 1 字节

    ; 3. 计算理论正确值 (Expected) = Row * Col
    mov rax, r12
    imul rax, r13

    ; 4. 比较
    cmp al, dl              ; 比较 Expected(al) 和 Actual(dl)
    je  cell_ok             ; 如果相等，直接返回

    ; 5. 如果不相等，调用打印错误的过程
    call print_error_line

cell_ok:
    ret

; ==========================================================
; 过程: print_error_line
; 功能: 打印 "x y error"
; 特点: 直接读取父过程的 r12 和 r13 寄存器
; ==========================================================
print_error_line:
    push rax                ; 保存 rax (因为它会被 print_int 修改)

    ; 打印行号 (r12)
    mov rax, r12
    call print_int

    ; 打印空格
    mov rsi, space
    call print_string

    ; 打印列号 (r13)
    mov rax, r13
    call print_int

    ; 打印错误后缀
    mov rsi, msg_err
    call print_string

    pop rax                 ; 恢复 rax
    ret

; ==========================================================
; 过程: print_string
; 功能: 打印以 0 结尾的字符串
; 输入: RSI 指向字符串
; ==========================================================
print_string:
    push rax
    push rdi
    push rdx
    push rcx

    ; 计算字符串长度
    mov rdx, 0
str_len_loop:
    cmp byte [rsi + rdx], 0
    je  do_print
    inc rdx
    jmp str_len_loop

do_print:
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    ; rsi 已经在正确位置
    ; rdx 已经是长度
    syscall

    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

; ==========================================================
; 过程: print_int
; 功能: 将 RAX 中的数字转为字符串并打印
; ==========================================================
print_int:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r11                ; syscall 可能会破坏 r11/rcx

    mov rsi, num_buf + 7    ; 指向缓冲区末尾
    mov rbx, 10             ; 除数
    mov rcx, rax            ; 被除数

convert_loop:
    xor rdx, rdx
    mov rax, rcx
    div rbx                 ; rax / 10
    mov rcx, rax            ; 商存回 rcx

    add dl, '0'             ; 余数转 ASCII
    dec rsi
    mov [rsi], dl

    test rcx, rcx
    jnz convert_loop

    ; 打印
    mov rdx, num_buf + 7
    sub rdx, rsi            ; 长度
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    syscall

    pop r11
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret