# 汇编语言学习项目

这个项目使用GitHub Actions来构建和运行汇编代码，为学习x86_64汇编语言提供一个自动化的环境。

## 🚀 特性

- **自动化构建**: 使用GitHub Actions自动编译和运行汇编代码
- **示例程序**: 包含从简单到复杂的汇编程序示例
- **跨平台**: 在Ubuntu环境中运行，确保一致性
- **详细注释**: 所有代码都有中文注释，便于理解

## 📁 项目结构

```
asm/
├── .github/
│   └── workflows/
│       └── build-and-run.yml    # GitHub Actions工作流配置
├── hello_world.asm              # Hello World示例程序
├── calculator.asm               # 简单计算器示例程序
├── fibonacci.asm                # 斐波那契数列生成器
├── Makefile                     # 编译配置文件
└── README.md                    # 项目说明文档
```

## 🛠️ 使用方法

### 在GitHub上使用

1. **Fork这个仓库**到你的GitHub账户
2. **推送代码更改**到main分支
3. **查看Actions页面**，GitHub会自动运行工作流
4. **检查输出结果**在Actions的运行日志中

### 在本地使用

如果你想在本地环境中编译和运行：

#### 安装依赖
```bash
# Ubuntu/Debian
sudo apt-get install nasm gcc gdb build-essential

# macOS (使用Homebrew)
brew install nasm gcc

# Windows (使用WSL推荐)
```

#### 编译和运行
```bash
# 编译所有程序
make all

# 运行所有程序
make run

# 单独编译某个程序
make hello_world
make calculator
make fibonacci

# 清理生成的文件
make clean

# 重新编译
make rebuild

# 查看帮助
make help
```

## 📚 示例程序说明

### 1. Hello World (`hello_world.asm`)
- 最基础的汇编程序
- 演示系统调用的使用
- 输出"Hello, Assembly World!"消息

**关键概念:**
- 系统调用（syscall）
- 寄存器操作
- 内存段（section）

### 2. 简单计算器 (`calculator.asm`)
- 演示基本算术运算
- 数字到字符串的转换
- 函数调用和栈操作

**关键概念:**
- 算术指令（add, sub, mul）
- 数据类型转换
- 函数定义和调用
- 栈操作（push, pop）

### 3. 斐波那契数列生成器 (`fibonacci.asm`)
- 演示循环和递推算法
- 复杂的数字处理和格式化输出
- 寄存器管理和数据存储

**关键概念:**
- 循环控制（loop, jnz）
- 条件跳转指令
- 复杂的数学计算
- 字符串缓冲区管理
- 多寄存器协调使用

## 🔧 工作流说明

GitHub Actions工作流会执行以下步骤：

1. **检出代码**: 获取仓库代码
2. **安装工具**: 安装NASM、GCC等编译工具
3. **显示版本**: 显示工具版本信息
4. **编译程序**: 使用Makefile编译所有汇编程序
5. **运行程序**: 执行生成的可执行文件并显示输出

## 📖 学习资源

### 寄存器说明
- `rax`: 累加器，常用于算术运算和系统调用号
- `rbx`: 基址寄存器，常用于内存寻址
- `rcx`: 计数器寄存器，常用于循环
- `rdx`: 数据寄存器，常用于数据操作
- `rsi`: 源索引寄存器，常用于字符串操作
- `rdi`: 目标索引寄存器，常用于字符串操作

### 常用系统调用
- `1`: sys_write（写入）
- `60`: sys_exit（退出）

### 汇编指令
- `mov`: 数据传送
- `add`: 加法
- `sub`: 减法
- `mul`: 乘法
- `div`: 除法
- `call`: 函数调用
- `ret`: 函数返回

## 🎯 扩展建议

可以添加更多示例程序来学习：

1. **字符串操作**: 字符串长度计算、比较、复制
2. **文件操作**: 读写文件的汇编程序
3. **数组操作**: 数组排序、搜索算法
4. **递归函数**: 阶乘、斐波那契数列
5. **内存管理**: 动态内存分配和释放

## 🤝 贡献

欢迎提交Pull Request来改进这个学习项目！可以：

- 添加新的示例程序
- 改进现有代码的注释
- 修复bug或优化性能
- 完善文档说明

## 📝 许可证

本项目采用MIT许可证，详见LICENSE文件。

---

**祝你在汇编语言学习的路上取得成功！** 🎉
