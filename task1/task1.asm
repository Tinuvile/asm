section .data
    prompt db "请输入1到2位16进制数: ", 0
    prompt_len equ $ - prompt - 1
    result_msg db "对应的十进制数是: ", 0
    result_msg_len equ $ - result_msg - 1
    newline db 0x0A
    error_msg db "输入格式错误！请输入有效的16进制数(0-FF)", 0x0A
    error_msg_len equ $ - error_msg

section .bss
    input_buffer resb 10      ; 输入缓冲区
    output_buffer resb 10     ; 输出缓冲区
    hex_value resb 1          ; 存储转换后的数值

section .text
    global _start

_start:
    ; 显示提示信息
    mov rax, 1                ; sys_write
    mov rdi, 1                ; stdout
    mov rsi, prompt
    mov rdx, prompt_len
    syscall
    
    ; 读取用户输入
    mov rax, 0                ; sys_read
    mov rdi, 0                ; stdin
    mov rsi, input_buffer
    mov rdx, 10
    syscall
    
    mov r10, rax              ; 保存读取的字节数
    
    ; 处理输入（去掉换行符）
    dec r10                   ; 减去换行符
    
    ; 检查输入长度（应该是1或2个字符）
    cmp r10, 1
    je process_single_char
    cmp r10, 2
    je process_double_char
    jmp input_error

process_single_char:
    ; 处理单个16进制字符
    mov al, [input_buffer]
    call hex_char_to_value
    cmp al, 0xFF              ; 检查是否转换失败
    je input_error
    mov [hex_value], al
    jmp display_result

process_double_char:
    ; 处理两个16进制字符
    mov al, [input_buffer]    ; 第一个字符
    call hex_char_to_value
    cmp al, 0xFF
    je input_error
    mov bl, al                ; 保存第一位的值
    
    mov al, [input_buffer + 1] ; 第二个字符
    call hex_char_to_value
    cmp al, 0xFF
    je input_error
    
    ; 计算最终值: 第一位 * 16 + 第二位
    shl bl, 4                 ; 第一位左移4位 (乘以16)
    add bl, al                ; 加上第二位
    mov [hex_value], bl
    jmp display_result

; 将16进制字符转换为数值
; 输入: AL = 16进制字符
; 输出: AL = 数值 (0-15), 或 0xFF 表示错误
hex_char_to_value:
    cmp al, '0'
    jl hex_error
    cmp al, '9'
    jle hex_digit             ; 0-9
    
    cmp al, 'A'
    jl hex_error
    cmp al, 'F'
    jle hex_upper             ; A-F
    
    cmp al, 'a'
    jl hex_error
    cmp al, 'f'
    jle hex_lower             ; a-f
    
    jmp hex_error

hex_digit:
    sub al, '0'               ; '0'-'9' -> 0-9
    ret

hex_upper:
    sub al, 'A'               ; 'A'-'F' -> 0-5
    add al, 10                ; 转换为 10-15
    ret

hex_lower:
    sub al, 'a'               ; 'a'-'f' -> 0-5
    add al, 10                ; 转换为 10-15
    ret

hex_error:
    mov al, 0xFF              ; 错误标记
    ret

display_result:
    ; 显示结果提示
    mov rax, 1                ; sys_write
    mov rdi, 1                ; stdout
    mov rsi, result_msg
    mov rdx, result_msg_len
    syscall
    
    ; 将数值转换为十进制字符串
    mov al, [hex_value]
    call number_to_string
    
    ; 输出结果
    mov rax, 1                ; sys_write
    mov rdi, 1                ; stdout
    mov rsi, output_buffer
    mov rdx, r8               ; 字符串长度
    syscall
    
    ; 输出换行
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    jmp exit

input_error:
    ; 显示错误信息
    mov rax, 1                ; sys_write
    mov rdi, 1                ; stdout
    mov rsi, error_msg
    mov rdx, error_msg_len
    syscall
    jmp exit

; 将0-255的数字转换为十进制字符串
; 输入: AL = 数字
; 输出: output_buffer中存储字符串, R8 = 字符串长度
number_to_string:
    mov r8, 0                 ; 字符串长度计数器
    mov rsi, output_buffer + 9 ; 从缓冲区末尾开始
    mov bl, 10                ; 除数
    
    test al, al               ; 检查是否为0
    jnz convert_loop
    
    ; 特殊处理0
    mov byte [output_buffer], '0'
    mov r8, 1
    ret

convert_loop:
    test al, al
    jz convert_done
    
    xor ah, ah                ; 清除AH
    div bl                    ; AL / 10, 商在AL，余数在AH
    add ah, '0'               ; 余数转换为字符
    dec rsi
    mov [rsi], ah             ; 存储字符
    inc r8                    ; 增加长度计数
    jmp convert_loop

convert_done:
    ; 将字符串移动到缓冲区开头
    mov rdi, output_buffer
    mov rcx, r8
    rep movsb
    ret

exit:
    ; 正常退出
    mov rax, 60               ; sys_exit
    mov rdi, 0                ; 退出状态码
    syscall
