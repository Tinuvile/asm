; target.asm - 被调试的目标程序
section .text
    global _start

_start:
    mov rcx, 0xFFFFFF          ; 循环
    mov rax, 0

.loop:
    add rax, 1          ; 简单的指令，方便调试器单步跟踪
    dec rcx
    jnz .loop

    ; 退出
    mov rax, 60
    mov rdi, 0
    syscall