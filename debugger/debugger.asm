; ==========================================
; UI Debugger (Final Polish)
; 功能: UI下移防止遮挡，修复坐标系
; ==========================================

section .data
    target_path:    db "./target", 0
    argv_ptr:       dq target_path, 0
    
    ; --- ANSI Escape Codes ---
    ; [2J = 清屏, [2;1H = 光标强制移动到 第2行 第1列 (留出第1行缓冲区)
    clear_screen:   db 0x1B, "[2J", 0x1B, "[2;1H", 0 
    
    ; 静态界面绘制
    box_line1:      db "+--------------------------------------------------+", 0x0A, 0
    box_line2:      db "| [ REGISTERS ]                                    |", 0x0A, 0
    box_line3:      db "|                                                  |", 0x0A, 0
    box_line4:      db "|                                                  |", 0x0A, 0
    box_line5:      db "+--------------------------------------------------+", 0x0A, 0
    box_line6:      db "| [ NEXT INSTRUCTION BYTES ]                       |", 0x0A, 0
    box_line7:      db "|                                                  |", 0x0A, 0
    box_line8:      db "+--------------------------------------------------+", 0x0A, 0
    
    cmd_prompt:     db "COMMAND > [Enter] Step  [q] Quit", 0

    ; --- 动态数据坐标 (全部向下偏移 1 行) ---
    ; 原来是 Row 3, 现在 Row 4
    cursor_rax:     db 0x1B, "[4;3H", 0           
    ; 原来是 Row 4, 现在 Row 5
    cursor_rip:     db 0x1B, "[5;3H", 0           
    ; 原来是 Row 7, 现在 Row 8
    cursor_code:    db 0x1B, "[8;3H", 0           
    ; 原来是 Row 10, 现在 Row 11
    cursor_cmd:     db 0x1B, "[11;1H", 0          

    ; 颜色与标签
    color_green:    db 0x1B, "[32m", 0
    color_red:      db 0x1B, "[31m", 0
    color_reset:    db 0x1B, "[0m", 0
    
    lbl_rax:        db "RAX: 0x", 0
    lbl_rip:        db "RIP: 0x", 0
    lbl_err:        db "READ ERROR (Process Exiting?)", 0
    
    hex_map:        db "0123456789ABCDEF"

section .bss
    wait_status:    resd 1
    pid:            resd 1
    regs_struct:    resb 216    ; user_regs_struct
    code_buf:       resq 1
    input_char:     resb 1

section .text
    global _start

_start:
    ; 1. Fork
    mov rax, 57
    syscall
    cmp rax, 0
    je .child_process
    mov [pid], eax

.debugger_loop:
    ; 2. Wait
    mov rax, 61
    mov edi, [pid]
    mov rsi, wait_status
    mov rdx, 0
    mov r10, 0
    syscall

    ; 3. Check Exit
    ; WIFEXITED: status & 0x7F == 0
    mov eax, [wait_status]
    and eax, 0x7F
    cmp eax, 0
    je .exit

    ; 4. Get Regs
    mov rax, 101            ; ptrace
    mov rdi, 12             ; GETREGS
    mov esi, [pid]
    mov rdx, 0
    mov r10, regs_struct
    syscall

    ; 5. Peek Text
    mov rbx, [regs_struct + 128] ; RIP
    
    mov rax, 101            ; ptrace
    mov rdi, 1              ; PEEKTEXT
    mov esi, [pid]
    mov rdx, rbx            ; Address
    mov r10, 0
    syscall
    mov [code_buf], rax     ; 结果可能是机器码或错误码

    ; --- 绘制 UI ---
    call draw_interface

    ; --- 等待输入 ---
    call wait_for_input
    cmp byte [input_char], 'q'
    je .exit

    ; 6. Single Step
    mov rax, 101
    mov rdi, 9              ; SINGLESTEP
    mov esi, [pid]
    mov rdx, 0
    mov r10, 0
    syscall

    jmp .debugger_loop

.exit:
    ; 退出清理
    mov rdi, color_reset
    call print_str
    
    ; 把光标移到最下面，防止覆盖
    mov rax, 1
    mov rdi, 1
    mov rsi, newline_exit
    mov rdx, 2
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall

.child_process:
    mov rax, 101
    mov rdi, 0
    syscall
    mov rax, 59
    mov rdi, target_path
    mov rsi, argv_ptr
    mov rdx, 0
    syscall
    mov rax, 60
    syscall

; ==========================================
; UI 绘制
; ==========================================
draw_interface:
    push rbx
    push rcx
    push rdx

    ; 1. 清屏并移动到 (2,1)
    mov rdi, clear_screen
    call print_str

    ; 2. 画框
    mov rdi, box_line1
    call print_str
    mov rdi, box_line2
    call print_str
    mov rdi, box_line3
    call print_str
    mov rdi, box_line4
    call print_str
    mov rdi, box_line5
    call print_str
    mov rdi, box_line6
    call print_str
    mov rdi, box_line7
    call print_str
    mov rdi, box_line8
    call print_str

    ; 3. 填 RAX
    mov rdi, cursor_rax
    call print_str
    mov rdi, color_green
    call print_str
    mov rdi, lbl_rax
    call print_str
    mov rax, [regs_struct + 80]
    call print_hex64
    mov rdi, color_reset
    call print_str

    ; 4. 填 RIP
    mov rdi, cursor_rip
    call print_str
    mov rdi, lbl_rip
    call print_str
    mov rax, [regs_struct + 128]
    call print_hex64

    ; 5. 填 Code
    mov rdi, cursor_code
    call print_str
    
    mov rax, [code_buf]
    cmp rax, 0
    jl .print_error

    call print_hex64
    jmp .draw_cmd

.print_error:
    mov rdi, color_red
    call print_str
    mov rdi, lbl_err
    call print_str
    mov rdi, color_reset
    call print_str

.draw_cmd:
    mov rdi, cursor_cmd
    call print_str
    mov rdi, cmd_prompt
    call print_str

    pop rdx
    pop rcx
    pop rbx
    ret

; ==========================================
; 辅助函数
; ==========================================
wait_for_input:
    mov rax, 0
    mov rdi, 0
    mov rsi, input_char
    mov rdx, 1
    syscall
    ret

print_str:
    push rdi
    mov rdx, 0
.len_loop:
    cmp byte [rdi + rdx], 0
    je .do_print
    inc rdx
    jmp .len_loop
.do_print:
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    syscall
    pop rdi
    ret

print_hex64:
    push rbx
    push rcx
    mov rcx, 16
    mov rbx, rax
.hex_loop:
    rol rbx, 4
    mov rax, rbx
    and rax, 0x0F
    mov al, [hex_map + rax]
    push rcx
    push rax
    mov rsi, rsp
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall
    pop rax
    pop rcx
    dec rcx
    jnz .hex_loop
    pop rcx
    pop rbx
    ret

section .data
    newline_exit: db 0x0A, 0x0A ; 退出时多打两个回车