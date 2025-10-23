# Makefile for Assembly Language Learning Project

# 编译器和工具
ASM = nasm
LINKER = ld
ASM_FLAGS = -f elf64
LINKER_FLAGS = 

# 项目目录和源文件
PROJECT_DIR = project
ASM_FILES = $(wildcard $(PROJECT_DIR)/*.asm)
SOURCES = $(notdir $(ASM_FILES))
OBJECTS = $(SOURCES:.asm=.o)
EXECUTABLES = $(SOURCES:.asm=)

# 默认目标：编译project目录下的程序
all: build-project

# 通用规则：从project目录的.asm文件生成.o文件
%.o: $(PROJECT_DIR)/%.asm
	@echo "Assembling $<..."
	$(ASM) $(ASM_FLAGS) $< -o $@

# 通用规则：从.o文件生成可执行文件到project目录
%: %.o
	@echo "Linking $@ to $(PROJECT_DIR)/$@..."
	$(LINKER) $(LINKER_FLAGS) $< -o $(PROJECT_DIR)/$@

# 检查project目录下的asm文件并编译
build-project: check-single-asm
	@ASM_FILE=$$(find $(PROJECT_DIR) -name "*.asm" -type f | head -1); \
	if [ -n "$$ASM_FILE" ]; then \
		BASENAME=$$(basename "$$ASM_FILE" .asm); \
		echo "Building $$BASENAME from $$ASM_FILE..."; \
		$(ASM) $(ASM_FLAGS) "$$ASM_FILE" -o "$$BASENAME.o"; \
		$(LINKER) $(LINKER_FLAGS) "$$BASENAME.o" -o "$(PROJECT_DIR)/$$BASENAME"; \
		rm -f "$$BASENAME.o"; \
		echo "Executable created: $(PROJECT_DIR)/$$BASENAME"; \
	fi

# 检查project目录下是否只有一个asm文件
check-single-asm:
	@ASM_COUNT=$$(find $(PROJECT_DIR) -name "*.asm" -type f | wc -l); \
	if [ $$ASM_COUNT -eq 0 ]; then \
		echo "Error: No .asm files found in $(PROJECT_DIR)/ directory"; \
		exit 1; \
	elif [ $$ASM_COUNT -gt 1 ]; then \
		echo "Error: Multiple .asm files found in $(PROJECT_DIR)/ directory:"; \
		find $(PROJECT_DIR) -name "*.asm" -type f; \
		echo "Please ensure only one .asm file exists in $(PROJECT_DIR)/ directory"; \
		exit 1; \
	fi

# 运行project目录下的程序
run: build-project
	@ASM_FILE=$$(find $(PROJECT_DIR) -name "*.asm" -type f | head -1); \
	if [ -n "$$ASM_FILE" ]; then \
		BASENAME=$$(basename "$$ASM_FILE" .asm); \
		echo "========================================="; \
		echo "Running $$BASENAME:"; \
		echo "========================================="; \
		chmod +x "$(PROJECT_DIR)/$$BASENAME"; \
		"./$(PROJECT_DIR)/$$BASENAME"; \
		echo ""; \
	fi

# 清理生成的文件
clean:
	@echo "Cleaning up..."
	rm -f *.o
	find $(PROJECT_DIR) -type f -executable -not -name "*.asm" -delete 2>/dev/null || true

# 重新编译所有内容
rebuild: clean build-project

# 调试版本（如果需要的话）
debug: ASM_FLAGS += -g -F dwarf
debug: build-project

# 显示帮助信息
help:
	@echo "Available targets:"
	@echo "  all           - Build program from project/ directory (default)"
	@echo "  build-project - Build the single .asm file from project/ directory"
	@echo "  run           - Build and run the program from project/ directory"
	@echo "  clean         - Remove all generated files"
	@echo "  rebuild       - Clean and build program"
	@echo "  debug      - Build with debug information"
	@echo "  help       - Show this help message"

# 标记这些目标不是文件
.PHONY: all build-project check-single-asm run clean rebuild debug help
