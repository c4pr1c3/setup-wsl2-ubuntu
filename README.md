# Ubuntu 22.04 (WSL2) 开发环境初始化脚本

这是一个用于快速配置 Ubuntu 22.04 (WSL2) 本地开发环境的 Shell 脚本套件。它集成了国内高速镜像源（清华大学开源软件镜像站），并自动化安装主流开发工具，旨在提供开箱即用的开发体验。

## ✨ 特性

- **国内加速**：APT, Conda, NPM, Rust, Go 等均默认配置清华/国内镜像源，大幅提升下载速度。
- **模块化设计**：支持一键全量安装，也支持按需单独配置特定组件。
- **WSL2 优化**：针对 WSL2 环境优化的 SSH 服务端配置（支持自定义端口），并提供 WSL 基础配置（systemd, interop）。
- **幂等性**：内置状态检查，重复运行会提示确认，避免误覆盖现有配置。
- **工具链集成**：
    - **基础依赖**: 自动安装 unzip, proxychains4 等常用工具。
    - **WSL 配置**: 自动配置 `/etc/wsl.conf` (systemd, PATH 隔离)。
    - **Git**: 自动配置 `~/.gitconfig`，强制校验用户信息。
    - **Python**: Miniconda3 (默认创建 Python 3.13 `dev` 环境)
    - **Node.js**: 使用 `fnm` 管理多版本 (默认安装 LTS)
    - **Go**: 使用 `g` 工具管理多版本 (轻量级、二进制分发)
    - **Rust**: 标准 `rustup` 安装流程
    - **SSH**: 服务端配置 (Supervisor 管理) & 客户端 Ed25519 密钥生成

## 🚀 快速开始

1.  **赋予执行权限**
    ```bash
    chmod +x main.sh scripts/*.sh
    ```

2.  **配置 Git 用户信息**
    复制配置文件模板并填入您的姓名和邮箱：
    ```bash
    cp git.config.example git.config
    ```
    编辑 `git.config`：
    ```ini
    [user]
        email = your.email@example.com
        name = Your Name
    ```

3.  **一键全量配置** (推荐)
    ```bash
    ./main.sh --all
    ```

## 📖 使用指南

### 常用命令选项

| 功能 | 命令 | 说明 |
| :--- | :--- | :--- |
| **全量配置** | `./main.sh --all` | 执行所有初始化任务 |
| **APT 换源** | `./main.sh --apt` | 备份原源，替换为清华源并更新缓存 |
| **基础依赖** | `./main.sh --deps` | 安装 unzip, proxychains4 等基础工具 |
| **WSL 配置** | `./main.sh --wsl` | 配置 `/etc/wsl.conf` (启用 systemd, 禁用 host path) |
| **Git 配置** | `./main.sh --git` | 检查并复制 `git.config` 到 `~/.gitconfig` |
| **SSH 服务端** | `./main.sh --ssh-server <port>` | 配置 SSH 服务 (Supervisor 管理, 默认端口 8022) |
| **SSH 客户端** | `./main.sh --ssh-client` | 生成 Ed25519 密钥对 (`~/.ssh/id_ed25519`) |
| **Python (Conda)** | `./main.sh --conda` | 安装 Miniconda & 创建 `dev` 环境 |
| **Node.js** | `./main.sh --node` | 安装 fnm, Node.js LTS, 配置 npm 淘宝镜像 |
| **Rust** | `./main.sh --rust` | 安装 rustup, cargo, 配置 crates.io 镜像 |
| **Go** | `./main.sh --go` | 安装 g, Go Latest, 配置 GOPROXY |

### 自定义配置

所有可配置项（如镜像源 URL、默认端口、Python 版本等）均集中在 [config.sh](config.sh) 文件中。

## 📂 项目结构

```text
.
├── main.sh                 # 主入口脚本，负责参数解析和流程控制
├── config.sh               # 配置文件，定义全局变量
├── git.config.example      # Git 配置文件模板
├── CLAUDE.md               # 项目上下文与开发规范文档
├── lib/
│   └── utils.sh            # 通用工具库（日志、颜色、交互确认）
└── scripts/                # 独立组件安装脚本
    ├── setup_apt.sh
    ├── install_deps.sh
    ├── setup_wsl.sh
    ├── setup_git.sh
    ├── setup_ssh_server.sh
    ├── setup_ssh_client.sh
    ├── setup_miniconda.sh
    ├── setup_node.sh
    ├── setup_rust.sh
    └── setup_go.sh
```

## ⚠️ 注意事项

1.  **Git 配置**：运行 `--git` 或 `--all` 之前，**必须**从 `git.config.example` 复制并修改生成 `git.config` 文件。如果未配置，脚本会报错并停止执行。
2.  **Shell 重启**：脚本执行完毕后，建议重启终端或执行 `source ~/.bashrc`，以确保环境变量立即生效。
3.  **WSL 重启**：运行 `--wsl` 后，需要执行 `wsl --shutdown` 重启 WSL 实例以使配置生效。
4.  **SSH 服务**：SSH 服务由 Supervisor 管理，配置位于 `/etc/supervisor/conf.d/sshd.conf`。
