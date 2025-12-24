#include <stdio.h>
#include <stdint.h>

// 中断服务程序
void my_overflow_isr() {
    printf(">>> ISR: Overflow detected! Correction logic running... <<<\n");
}

int main() {
    int8_t a = 127;
    int8_t b = 1;
    int64_t flags;

    printf("Computing: %d + %d\n", a, b);

    // 内联汇编
    __asm__ (
        "addb %2, %0\n\t"    // 执行 a = a + b (产生溢出)
        "pushfq\n\t"         // 保存标志位
        "popq %1\n\t"        // 弹出到变量 flags
        : "+r"(a), "=r"(flags)  // 输出
        : "r"(b)                // 输入
        : "cc"                  // 告诉编译器我们会改变标志位
    );

    // 手动检查 OF (第11位)，不使用 jo
    // 0x800 = 2048 = Bit 11
    if (flags & 0x800) {
        // 模拟执行 INTO
        my_overflow_isr();
    } else {
        printf("No overflow.\n");
    }

    printf("Result (wrapped): %d\n", a);
    return 0;
}