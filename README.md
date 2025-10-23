# 汇编语言学习项目

这个项目使用GitHub Actions来构建和运行汇编代码，为学习x86_64汇编语言提供一个自动化的环境。

## 特性

- **自动化构建**: 使用GitHub Actions自动编译project目录下的汇编代码
- **单文件处理**: 确保project目录下只有一个.asm文件，避免混淆
- **自动部署**: 编译后的exe文件自动推送回仓库的project目录
- **跨平台**: 在Ubuntu环境中运行，确保一致性

## 项目结构

```
asm/
├── .github/
│   └── workflows/
│       └── build-and-run.yml    # GitHub Actions工作流配置
├── project/
│   ├── hello_world.asm          # 汇编源代码文件
│   └── hello_world              # 自动生成的可执行文件
├── Makefile                     # 编译配置文件
└── README.md                    # 项目说明文档
```
