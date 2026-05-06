#!/bin/bash
#
# Ubuntu 22.04 (WSL2) 开发环境初始化脚本
#
# 用法: ./main.sh [选项]
#

set -e

# 加载配置和工具
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib/utils.sh"

# 确保脚本具有执行权限
chmod +x "$(dirname "$0")"/scripts/*.sh

help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --all              执行所有配置步骤"
    echo "  --apt              配置 APT 镜像源 (清华源)"
    echo "  --deps             安装基础依赖 (unzip, proxychains4)"
    echo "  --wsl              配置 WSL 基础设置 (/etc/wsl.conf)"
    echo "  --git              配置 Git 客户端 (需先修改 git.config)"
    echo "  --ssh-server [p]   配置 OpenSSH 服务端 (默认端口 $SSH_PORT_DEFAULT)"
    echo "  --ssh-client       生成 SSH 客户端密钥 (Ed25519)"
    echo "  --conda            安装/配置 Miniconda & Python $PYTHON_VERSION"
    echo "  --node             安装/配置 Node.js (fnm) & npm"
    echo "  --rust             安装/配置 Rust (Cargo)"
    echo "  --go               安装/配置 Go (g)"
    echo "  --lsp              安装 LSP Language Servers (gopls, pyright, etc.)"
    echo "  --help             显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --all"
    echo "  $0 --apt --ssh-server 2222"
    echo "  $0 --node --go"
}

# --- 主程序 ---

if [ $# -eq 0 ]; then
    help
    exit 0
fi

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            ./scripts/setup_apt.sh
            ./scripts/install_deps.sh
            ./scripts/setup_wsl.sh
            ./scripts/setup_git.sh
            ./scripts/setup_ssh_server.sh $SSH_PORT_DEFAULT
            ./scripts/setup_ssh_client.sh
            ./scripts/setup_miniconda.sh
            ./scripts/setup_node.sh
            ./scripts/setup_rust.sh
            ./scripts/setup_go.sh
            ./scripts/setup_lsp.sh
            shift
            ;;
        --apt)
            ./scripts/setup_apt.sh
            shift
            ;;
        --deps)
            ./scripts/install_deps.sh
            shift
            ;;
        --wsl)
            ./scripts/setup_wsl.sh
            shift
            ;;
        --git)
            ./scripts/setup_git.sh
            shift
            ;;
        --ssh-server)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                ./scripts/setup_ssh_server.sh "$2"
                shift 2
            else
                ./scripts/setup_ssh_server.sh $SSH_PORT_DEFAULT
                shift
            fi
            ;;
        --ssh-client)
            ./scripts/setup_ssh_client.sh
            shift
            ;;
        --conda)
            ./scripts/setup_miniconda.sh
            shift
            ;;
        --node)
            ./scripts/setup_node.sh
            shift
            ;;
        --rust)
            ./scripts/setup_rust.sh
            shift
            ;;
        --go)
            ./scripts/setup_go.sh
            shift
            ;;
        --lsp)
            ./scripts/setup_lsp.sh
            shift
            ;;
        --help)
            help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            help
            exit 1
            ;;
    esac
done

log_success "请求的任务已完成！请重启 Shell 以确保所有环境变量生效。"
