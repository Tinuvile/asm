# Makefile for Assembly Language Learning Project

# 编译器和工具
ASM = nasm
LINKER = ld
ASM_FLAGS = -f elf64
LINKER_FLAGS = 

# 源文件和目标文件
SOURCES = hello_world.asm calculator.asm fibonacci.asm
OBJECTS = $(SOURCES:.asm=.o)
EXECUTABLES = $(SOURCES:.asm=)

# 默认目标：编译所有程序
all: $(EXECUTABLES)

# 通用规则：从.asm文件生成.o文件
%.o: %.asm
	@echo "Assembling $<..."
	$(ASM) $(ASM_FLAGS) $< -o $@

# 通用规则：从.o文件生成可执行文件
%: %.o
	@echo "Linking $@..."
	$(LINKER) $(LINKER_FLAGS) $< -o $@

# 单独编译Hello World程序
hello_world: hello_world.o
	@echo "Building Hello World program..."
	$(LINKER) $(LINKER_FLAGS) hello_world.o -o hello_world

# 单独编译计算器程序
calculator: calculator.o
	@echo "Building Calculator program..."
	$(LINKER) $(LINKER_FLAGS) calculator.o -o calculator

# 单独编译斐波那契程序
fibonacci: fibonacci.o
	@echo "Building Fibonacci program..."
	$(LINKER) $(LINKER_FLAGS) fibonacci.o -o fibonacci

# 运行所有程序
run: all
	@echo "========================================="
	@echo "Running Hello World:"
	@echo "========================================="
	./hello_world
	@echo ""
	@echo "========================================="
	@echo "Running Calculator:"
	@echo "========================================="
	./calculator
	@echo ""
	@echo "========================================="
	@echo "Running Fibonacci:"
	@echo "========================================="
	./fibonacci
	@echo ""

# 清理生成的文件
clean:
	@echo "Cleaning up..."
	rm -f $(OBJECTS) $(EXECUTABLES)

# 重新编译所有内容
rebuild: clean all

# 调试版本（如果需要的话）
debug: ASM_FLAGS += -g -F dwarf
debug: all

# 显示帮助信息
help:
	@echo "Available targets:"
	@echo "  all        - Build all programs (default)"
	@echo "  hello_world - Build only Hello World program"
	@echo "  calculator - Build only Calculator program"
	@echo "  fibonacci  - Build only Fibonacci program"
	@echo "  run        - Build and run all programs"
	@echo "  clean      - Remove all generated files"
	@echo "  rebuild    - Clean and build all programs"
	@echo "  debug      - Build with debug information"
	@echo "  help       - Show this help message"

# 标记这些目标不是文件
.PHONY: all run clean rebuild debug help
