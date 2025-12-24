;注：在现代 x86-64 Linux 环境下：
;INTO 指令失效：在 x86-64 的 64 位模式（Long Mode）下，INTO 指令（机器码 CE）是非法指令，执行它会产生异常。
;权限限制：Linux 用户态程序（Ring 3）无权直接修改中断向量表（IDT），因此无法真正地“重写”内核的中断服务程序（ISR）。
;因此下面程序将是一个在用户态对这个过程的模拟。它会手动检测溢出标志（OF），并跳转到自定义的“中断服务程序”函数中。

section .data
    msg_start   db "正在计算 8位有符号数: 127 + 1 ...", 10, 0
    msg_normal  db "计算正常 (未检测到溢出)", 10, 0
    msg_ovf     db ">>> 触发中断: 检测到溢出 (OF=1)! <<<", 10, 0
    msg_exit    db "程序结束。", 10, 0

section .text
    global _start

_start:
    ; --- 1. 打印开始信息 ---
    mov rsi, msg_start
    call print_string

    ; --- 2. 执行计算 (制造溢出) ---
    ; 8位有符号数范围: -128 到 +127
    mov al, 127         ; AL = 0x7F (+127)
    mov bl, 1           ; BL = 0x01
    add al, bl          ; AL = 0x80 (-128)，此时 OF 标志位会被硬件置 1

    ; --- 3. 手动检测溢出 (不使用 JO/JNO) ---
    ; 原理: RFLAGS 寄存器的第 11 位是 OF (Overflow Flag)
    ; 掩码: 2^11 = 2048 = 0x800

    pushfq              ; 将 RFLAGS 寄存器内容压入栈
    pop rdx             ; 将栈顶内容弹出到 RDX，现在 RDX 保存了刚才的标志位
    
    test rdx, 0x800     ; 检查第 11 位是否为 1 (0x800 是二进制 1000 0000 0000)
    jnz simulate_into   ; 如果结果不为0 (即 OF=1)，跳转到模拟中断逻辑
                        ; 注意：这里用的是 JNZ (Jump if Not Zero)，符合“不用 JO”的要求

    ; --- 如果没有溢出，继续执行 ---
    mov rsi, msg_normal
    call print_string
    jmp program_exit

; ==========================================================
; 模拟 INTO 指令的行为
; 在 16位 模式下，INTO 指令会检查 OF，如果为1则触发 Int 4
; 这里我们用软件跳转模拟这一行为
; ==========================================================
simulate_into:
    call overflow_isr   ; 调用我们的“中断服务程序”
    
    ; 从 ISR 返回后，继续执行后续代码
    jmp program_exit

; ==========================================================
; 重写的“中断服务程序” (ISR)
; 对应题目要求的: 重写 INTO (4号中断) 的中断服务程序
; ==========================================================
overflow_isr:
    push rax            ; 保护现场 (虽然本例简单，但这是 ISR 的标准动作)
    push rsi
    push rdi

    ; 执行中断处理逻辑：打印报错信息
    mov rsi, msg_ovf
    call print_string

    ; 在真实中断中，这里应该尝试修正错误或决定是否终止进程
    ; 这里我们模拟处理完毕

    pop rdi             ; 恢复现场
    pop rsi
    pop rax
    ret                 ; 相当于 IRET (中断返回)

; ==========================================================
; 程序退出点
; ==========================================================
program_exit:
    mov rsi, msg_exit
    call print_string

    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; status 0
    syscall

; ==========================================================
; 辅助过程: print_string
; ==========================================================
print_string:
    push rax
    push rdi
    push rdx
    push rcx

    mov rdx, 0
.str_len:
    cmp byte [rsi + rdx], 0
    je  .do_print
    inc rdx
    jmp .str_len

.do_print:
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    syscall

    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret