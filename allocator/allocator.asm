; ==========================================
; 简易内存分配器 (Simple Memory Allocator)
; 架构: x86-64 Linux
; 功能: 实现 malloc 和 free
; ==========================================

; 初始化的全局变量段
section .data
    ; msg_alloc1是一个Lable(标号), 汇编器会把它翻译成一个内存地址（指针）
    ; db(Define Byte) 定义字节
    ; 0是结束符, 0x0A是换行符的ASCII码
    msg_alloc1: db "1. Allocated 32 bytes at: 0x", 0
    msg_write:  db "   Wrote data: ", 0
    msg_free:   db "2. Freed memory.", 0x0A, 0
    msg_alloc2: db "3. Allocated 16 bytes (should reuse): 0x", 0
    newline:    db 0x0A, 0
    msg_coal_test: db 0x0A, "--- Coalescing Test ---", 0x0A, 0
    msg_ptr_a:     db "Ptr A (Size 32): 0x", 0
    msg_ptr_b:     db "Ptr B (Size 32): 0x", 0
    msg_ptr_c:     db "Ptr C (Size 64) [Should == Ptr A]: 0x", 0
    
    ; 测试用的字符串
    hello_str:  db "Hello Heap!", 0
    
    ; 16进制查表
    hex_map:    db "0123456789ABCDEF"

; 未初始化的全局变量段
section .bss
    ; resq(Reserve Quadword), Quadword=8Bytes
    ; resb(Reserve Byte)
    heap_start: resq 1      ; 堆链表的头指针
    last_valid: resq 1      ; 最近访问的有效块（用于追加）
    hex_buf:    resb 16     ; 打印缓冲

; 代码段
section .text
    global _start

; ==========================================
; 主程序 (测试驱动)
; ==========================================
_start:
    ; --- 测试 1: 申请 32 字节 ---
    mov rdi, 32
    call my_malloc
    mov rbx, rax            ; 保存返回的指针到 RBX

    ; 打印地址
    mov rdi, msg_alloc1
    call print_str
    mov rax, rbx
    call print_hex
    call print_newline

    ; --- 测试 2: 写入数据 ---
    ; 将 "Hello Heap!" 写入刚才申请的内存
    mov rsi, hello_str      ; 源地址
    mov rdi, rbx            ; 目的地址 (堆内存)
    call strcpy

    mov rdi, msg_write
    call print_str
    mov rdi, rbx            ; 打印堆里的内容
    call print_str
    call print_newline

    ; --- 测试 3: 释放内存 ---
    mov rdi, rbx
    call my_free
    
    mov rdi, msg_free
    call print_str

    ; --- 测试 4: 再次申请 (应该复用刚才的空间) ---
    mov rdi, 16
    call my_malloc
    mov rbx, rax

    mov rdi, msg_alloc2
    call print_str
    mov rax, rbx
    call print_hex
    call print_newline

    ; --- 测试 5: 合并测试----------------------

    ; 打印分割线
    mov rdi, msg_coal_test
    call print_str

    ; 1. 申请 A (32 bytes) -> 实际占用 32+16=48
    mov rdi, 32
    call my_malloc
    mov r12, rax            ; R12 保存 A
    
    mov rdi, msg_ptr_a
    call print_str
    mov rax, r12
    call print_hex
    call print_newline

    ; 2. 申请 B (32 bytes) -> 实际占用 32+16=48
    mov rdi, 32
    call my_malloc
    mov r13, rax            ; R13 保存 B
    
    mov rdi, msg_ptr_b
    call print_str
    mov rax, r13
    call print_hex
    call print_newline

    ; 3. 释放 A 和 B
    ; 先释放 B
    mov rdi, r13
    call my_free
    ; 再释放 A (A 变空闲，发现后面 B 也是空闲，于是吃掉 B)
    ; 此时 A 的位置应该有一个大小为 48+48=96 的空闲块
    mov rdi, r12
    call my_free
    
    mov rdi, msg_free
    call print_str

    ; 4. 申请 C (64 bytes) -> 实际占用 64+16=80
    mov rdi, 64
    call my_malloc
    mov r14, rax
    
    mov rdi, msg_ptr_c
    call print_str
    mov rax, r14
    call print_hex
    call print_newline

    ; 退出
    mov rax, 60
    xor rdi, rdi
    syscall

; ==========================================
; my_malloc
; 输入: RDI = 请求大小
; 输出: RAX = 用户可用内存地址
; ==========================================
my_malloc:
    push rbp                ; 保持调用者的栈基址指针
    mov rbp, rsp            ; 将当前栈顶设为新的栈底
    push rbx                ; 保存 RBX (被调用者保存寄存器)

    ; 1. 对齐大小 (16字节对齐)
    add rdi, 15
    and rdi, -16
    
    ; 2. 加上 Header 大小 (16 bytes)
    add rdi, 16             ; RDI = 需要的总大小 (Total Block Size)

    ; 3. 检查堆是否初始化
    mov rax, [heap_start]   ; 读取全局变量 heap_start
    cmp rax, 0
    je .request_space       ; 如果堆是空的，直接申请

    ; 4. 搜索空闲链表 (First Fit)
    ; RAX = 当前 Header 地址
.scan_loop:
    mov rbx, [rax]          ; 读取 Size 字段（Header的前8字节）
    
    ; 检查占用位 (Bit 0)
    test rbx, 1             ; RBX的最低位
    jnz .next_block         ; 已占用，找下一个

    ; 检查大小
    mov rdx, rbx
    and rdx, -2             ; 屏蔽 Bit 0 得到真实大小
    cmp rdx, rdi            ; 比较现有块RDX大小和需要大小RDI
    jl .next_block          ; 太小了，找下一个

    ; --- 找到可用块 ---
    or qword [rax], 1       ; 标记为占用
    add rax, 16             ; 跳过 Header 返回 User Area
    jmp .malloc_done

.next_block:
    mov rdx, [rax + 8]      ; 加载 next 指针
    cmp rdx, 0
    je .request_space       ; 链表到头了，去申请新空间
    mov rax, rdx            ; 继续循环
    jmp .scan_loop

.request_space:
    ; --- 向 OS 申请新空间 ---
    ; RDI 此时是需要申请的总大小
    
    push rdi                ; [栈操作] 保存需要的尺寸
                            ; 此时栈顶是 Size，下面是 saved_rbx, saved_rbp, ret_addr

    ; 获取当前 break (sys_brk(0))
    mov rax, 12             ; 12是sys_brk
    xor rdi, rdi            ; 参数设为0
    syscall                 ; sys_brk在RAX中返回当前堆顶地址
    
    mov rbx, rax            ; RBX = 旧 break (新块的起始地址)
    
    ; 计算新 break = old_break + size
    ; 从栈顶读取 size，但不弹出
    mov rdx, [rsp]          ; RDX = size
    lea rdi, [rbx + rdx]    ; RDI = 新的结束地址
    
    ; 申请空间 (sys_brk(new_addr))
    mov rax, 12
    syscall                 ; 再次sys_brk，把堆顶推到RDI

    pop rdi                 ; [栈操作] 恢复 RDI，现在栈平衡了

    ; 检查是否成功 (rax 应该等于请求的新地址)
    cmp rax, 0
    jl .malloc_fail         ; 简单的错误检查

    ; --- 初始化新块 Header ---
    ; RBX 指向新块头部
    ; RDI 保存着刚才 pop 出来的 size
    
    mov rax, rdi            ; Size给RAX
    or rax, 1               ; 最低位标记为占用 (Allocated)
    mov [rbx], rax          ; 写入 Size + Flag

    mov qword [rbx + 8], 0  ; Next Ptr = NULL (这是新的尾巴)

    ; --- 将新块挂到链表末尾 ---
    cmp qword [heap_start], 0
    jne .link_to_tail
    
    ; 如果是第一块
    mov [heap_start], rbx
    jmp .return_new

.link_to_tail:
    ; 遍历找到当前的尾巴 (也就是 next 为 0 的那个块)
    mov rdx, [heap_start]   ; 从头开始遍历
.find_tail_loop:
    cmp qword [rdx + 8], 0  ; 检查当前块的Next指针是不是0
    je .found_tail          ; 是则找到尾巴了
    mov rdx, [rdx + 8]      ; 否则继续移动
    jmp .find_tail_loop
.found_tail:
    mov [rdx + 8], rbx      ; 让旧尾巴指向新块

.return_new:
    mov rax, rbx            ; RBX是Header地址
    add rax, 16             ; 返回 User Area (跳过 Header)
    jmp .malloc_done

.malloc_fail:
    xor rax, rax            ; 返回 NULL

.malloc_done:
    pop rbx                 ; 恢复 RBX
    pop rbp                 ; 恢复 RBP
    ret

; ==========================================
; my_free (支持向后合并 / Coalescing)
; 输入: RDI = 待释放的指针 (User Data 地址)
; ==========================================
my_free:
    cmp rdi, 0
    je .free_ret

    ; 1. 回退到 Header
    sub rdi, 16             ; RDI 现在指向 Current Block Header

    ; 2. 标记为空闲
    mov rax, [rdi]          ; 读取 Size | Flag
    and rax, -2             ; 清除 Bit 0 (Mark as Free)
    mov [rdi], rax          ; 写回

    ; --- [Coalescing Logic / 合并逻辑] ---
    ; 循环检查：一直合并，直到后面是分配块或链表结尾为止。

.coalesce_loop:
    ; 获取 Next Block 的地址
    mov rsi, [rdi + 8]      ; RSI = Next Block Pointer
    cmp rsi, 0              ; 如果 Next 是 NULL (链表末尾)
    je .free_ret            ; 没法合并了，返回

    ; 检查 Next Block 是否空闲
    mov rdx, [rsi]          ; 读取 Next Block 的 Size | Flag
    test rdx, 1             ; 检查 Bit 0
    jnz .free_ret           ; 如果 Next 是占用的 (Allocated)，停止合并，返回

    ; --- [执行合并] ---
    ; 此时：RDI = 当前块 Header, RSI = 下一块 Header
    ; 动作 1: 更新当前块的大小 (Size = Size A + Size B)
    ; 注意：RAX 存的是当前块的大小(已清理Flag)，RDX 是下一块的大小(Flag也是0因为是Free)
    
    mov rax, [rdi]          ; 重新读取当前块大小 (为了安全)
    add rax, rdx            ; 新大小 = 当前大小 + 下一块大小
    mov [rdi], rax          ; 更新当前块 Header

    ; 动作 2: 更新 Next 指针 (跳过下一块)
    ; Current->Next = Next->Next
    mov rcx, [rsi + 8]      ; 读取 Next->Next
    mov [rdi + 8], rcx      ; 更新 Current->Next

    ; 动作 3: 继续循环
    ; 现在还在当前块 (RDI)，但它变大了，
    ; 需要再次检查新的“邻居”是不是也是空的。
    jmp .coalesce_loop

.free_ret:
    ret

; ==========================================
; 辅助函数: String Copy
; ==========================================
strcpy:
    ; RDI = dest, RSI = src ; RSI源地址、RDI目标地址
    xor rcx, rcx            ; RCX清零
.cp_loop:
    mov al, [rsi + rcx]     ; 读取 src[rcx]
    mov [rdi + rcx], al     ; 写入 dest[rcx]
    inc rcx                 ; rcx++
    cmp al, 0               ; 是否遇到 '\0'
    jne .cp_loop
    ret

; ==========================================
; 辅助函数: Print Hex (64-bit)
; 功能: 将 RAX 中的 64 位整数以 16 个十六进制字符形式输出到 stdout
; 原理: 循环 16 次，每次处理 4 个二进制位(1个Hex位)，查表转ASCII并打印
; ==========================================
print_hex:
    push rbx                ; 备份被调用者保存寄存器RBX
    
    mov rcx, 16             ; 初始化循环计数器，64位整数 = 16 个 Hex 字符
    mov rbx, rax            ; 将要打印的数值备份到 RBX

.hex_loop:
    ; --- 1. 取出最高 4 位 (Nibble) ---
    rol rbx, 4              ; 循环左移 4 位。

    mov rax, rbx            ; 把移位后的结果复制给 RAX
    and rax, 0x0F           ; 与 0000...1111 进行 AND 运算。把高位全清零，只保留最低 4 位

    ; --- 2. 查表转换 (数值 -> ASCII) ---
    mov al, [hex_map + rax] ; 以 RAX 为索引，去 hex_map 数组里找对应的字符。
                            ; 如果 RAX=0，取 '0'；如果 RAX=10 (0xA)，取 'A'。
    mov [hex_buf], al       ; 将找到的字符存入内存缓冲区 hex_buf。

    ; --- 3. 准备系统调用 (打印这 1 个字符) ---
    push rcx
    push rbx
    
    mov rax, 1              ; 系统调用号 1 = sys_write
    mov rdi, 1              ; 参数1: 文件描述符 fd = 1 (标准输出 stdout)
    mov rsi, hex_buf        ; 参数2: 缓冲区地址
    mov rdx, 1              ; 参数3: 写入长度 = 1 字节
    syscall                 ; 执行系统调用
    
    ; --- 4. 恢复现场并循环 ---
    pop rbx                 
    pop rcx                 
    
    dec rcx                 ; 计数器减 1
    jnz .hex_loop           ; 如果 RCX != 0，跳回开头继续循环

    pop rbx                 ; 还原函数最开始保存的 RBX
    ret                     ; 函数返回

; ==========================================
; 辅助函数: Print String
; 功能: 打印以 0 (NULL) 结尾的字符串
; ==========================================
print_str:
    push rdi                
    mov rdx, 0              ; 初始化 RDX = 0，作为长度计数器 (Length Counter)

.len_loop:
    ; --- 计算 strlen ---
    cmp byte [rdi + rdx], 0 ; 检查 (基址 + 偏移) 处的字节是不是 0
    je .print               ; 如果是 0 (结束符)，说明长度算完了，跳转到打印部分
    
    inc rdx                 ; 否则，长度 + 1
    jmp .len_loop           ; 继续检查下一个字符

.print:
    ; --- 执行输出 ---
    mov rax, 1              ; 系统调用号 1 = sys_write
    mov rsi, rdi            ; 参数2: 缓冲区首地址。
    mov rdi, 1              ; 参数1: fd = 1 (stdout)
                            ; 参数顺序是: RDI=fd, RSI=buffer, RDX=len
                            
    syscall                 ; 执行系统调用 -> 打印整个字符串

    pop rdi                 ; 还原 RDI
    ret                     ; 函数返回

; ==========================================
; 辅助函数: Print Newline
; 功能: 打印一个换行符
; ==========================================
print_newline:
    mov rdi, newline        ; 将换行符 "\n" 的地址加载到 RDI
    call print_str          ; 复用 print_str 函数来打印它
    ret