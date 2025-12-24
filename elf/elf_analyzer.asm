; ==========================================
; 简易 ELF 文件头分析器 (The ELF Analyzer)
; 架构: x86-64 Linux
; 功能: 读取文件头，解析 Magic, Class, Machine, Entry Point
; 用法: ./analyzer <filename>
; ==========================================

section .data
    ; --- 提示信息 ---
    usage_msg:      db "Usage: ./analyzer <filename>", 0x0A, 0
    err_open:       db "Error: Cannot open file.", 0x0A, 0
    err_read:       db "Error: Failed to read header.", 0x0A, 0
    err_not_elf:    db "Error: Not a valid ELF file!", 0x0A, 0
    
    ; --- 输出标签 ---
    lbl_magic:      db "Magic:   OK (ELF)", 0x0A, 0
    lbl_class64:    db "Class:   ELF64", 0x0A, 0
    lbl_class32:    db "Class:   ELF32", 0x0A, 0
    lbl_classunk:   db "Class:   Unknown", 0x0A, 0
    
    lbl_machine_x86: db "Machine: AMD x86-64", 0x0A, 0
    lbl_machine_unk: db "Machine: Unknown (ID: 0x", 0 ; 后面跟十六进制
    
    lbl_entry:      db "Entry:   0x", 0
    
    newline:        db 0x0A, 0
    hex_map:        db "0123456789ABCDEF"

section .bss
    fd:             resq 1      ; 文件描述符
    header_buf:     resb 64     ; 存放 ELF 头部的缓冲区 (64 bytes)
    hex_out_buf:    resb 16     ; 用于存放转换后的 16 进制字符串

section .text
    global _start

; ==========================================
; 主程序入口
; ==========================================
_start:
    ; --- 1. 参数处理 ---
    ; 栈顶 [rsp] 是 argc
    pop rcx
    cmp rcx, 2              ; argc 必须 >= 2 (./analyzer filename)
    jl _exit_usage

    pop rdi                 ; 弹出 argv[0] (程序名，忽略)
    pop rdi                 ; 弹出 argv[1] (文件名字符串地址)
    
    ; --- 2. 打开文件 ---
    ; open(filename, O_RDONLY, 0)
    ; syscall 2
    mov rax, 2
    ; rdi 已经在上面设置好了(文件名)
    mov rsi, 0              ; O_RDONLY
    mov rdx, 0              ; Mode (ignored for reading)
    syscall

    cmp rax, 0
    jl _exit_open_err       ; 只有 rax < 0 才是错误
    mov [fd], rax           ; 保存文件描述符

    ; --- 3. 读取 ELF 头 (64字节) ---
    ; read(fd, buffer, 64)
    ; syscall 0
    mov rax, 0
    mov rdi, [fd]
    mov rsi, header_buf
    mov rdx, 64
    syscall

    cmp rax, 64             ; 必须读满 64 字节
    jl _exit_read_err

    ; --- 4. 校验 Magic Number ---
    ; ELF Magic: 0x7F, 'E', 'L', 'F'
    ; 在 Little Endian 内存中是: 0x464C457F
    mov eax, [header_buf]
    cmp eax, 0x464C457F
    jne _exit_not_elf

    ; 打印 Magic OK
    mov rdi, lbl_magic
    call print_str

    ; --- 5. 解析 Class (32/64 bit) ---
    ; Offset 0x04: 1 = 32-bit, 2 = 64-bit
    mov al, [header_buf + 0x04]
    cmp al, 2
    je .is_64
    cmp al, 1
    je .is_32
    jmp .is_unk
.is_64:
    mov rdi, lbl_class64
    call print_str
    jmp .parse_machine
.is_32:
    mov rdi, lbl_class32
    call print_str
    jmp .parse_machine
.is_unk:
    mov rdi, lbl_classunk
    call print_str

    ; --- 6. 解析 Machine (架构) ---
    ; Offset 0x12 (2 bytes)
.parse_machine:
    mov ax, [header_buf + 0x12]
    cmp ax, 0x3E            ; 0x3E (62) = AMD64
    je .is_amd64
    
    ; 如果不是 x86-64，显示 Unknown
    mov rdi, lbl_machine_unk
    call print_str
    ; 这里可以补充打印具体的 Machine ID，简单起见跳过
    call print_newline
    jmp .parse_entry

.is_amd64:
    mov rdi, lbl_machine_x86
    call print_str

    ; --- 7. 解析 Entry Point (入口地址) ---
    ; Offset 0x18 (8 bytes)
.parse_entry:
    mov rdi, lbl_entry
    call print_str

    mov rax, [header_buf + 0x18] ; 读取 64位 入口地址
    call print_hex64             ; 打印 RAX 的十六进制值

    call print_newline

    ; --- 8. 关闭并退出 ---
    ; close(fd)
    mov rax, 3
    mov rdi, [fd]
    syscall

    mov rax, 60         ; exit(0)
    mov rdi, 0
    syscall

; ==========================================
; 辅助函数
; ==========================================

; 打印以 0 结尾的字符串
; 输入: rdi = 字符串地址
print_str:
    push rdi
    ; 计算长度
    mov rdx, 0
.strlen_loop:
    cmp byte [rdi + rdx], 0
    je .strlen_done
    inc rdx
    jmp .strlen_loop
.strlen_done:
    mov rax, 1          ; write
    mov rdi, 1          ; stdout
    pop rsi             ; string addr
    syscall
    ret

; 打印换行
print_newline:
    mov rdi, newline
    call print_str
    ret

; 打印 RAX 中的 64 位数值为 16 进制字符串
; 逻辑：循环 16 次，每次取高 4 位，查表打印
print_hex64:
    mov rcx, 16         ; 16 个十六进制位 (64 / 4)
    mov rbx, rax        ; 备份数据
.hex_loop:
    ; 我们需要从高位开始打印，所以使用 rol (循环左移)
    ; 每次左移 4 位，最高 4 位就会跑到最低 4 位
    rol rbx, 4
    mov rax, rbx
    and rax, 0x0F       ; 取最低 4 位
    
    mov al, [hex_map + rax] ; 查表转 ASCII
    
    ; 这里为了简单，我们每算出一个字符就调用一次 write (效率低但代码短)
    ; 更好的做法是存入 buffer 一次性打印
    mov [hex_out_buf], al
    
    push rcx            ; 保存循环计数器
    push rbx            ; 保存数据
    
    mov rax, 1          ; write
    mov rdi, 1          ; stdout
    mov rsi, hex_out_buf
    mov rdx, 1          ; len = 1
    syscall
    
    pop rbx
    pop rcx
    
    dec rcx
    jnz .hex_loop
    ret

; ==========================================
; 错误处理
; ==========================================
_exit_usage:
    mov rdi, usage_msg
    call print_str
    jmp _exit_1

_exit_open_err:
    mov rdi, err_open
    call print_str
    jmp _exit_1

_exit_read_err:
    mov rdi, err_read
    call print_str
    jmp _exit_1

_exit_not_elf:
    mov rdi, err_not_elf
    call print_str
    jmp _exit_1

_exit_1:
    mov rax, 60
    mov rdi, 1
    syscall