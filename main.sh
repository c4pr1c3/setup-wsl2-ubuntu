#!/bin/bash
#
# Ubuntu 22.04 (WSL2) 开发环境初始化脚本
#
# 用法: ./main.sh [选项]
#

set -e

# 脚本根目录（支持 bind mount 等无法直接执行的场景）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 确保脚本具有执行权限（部分挂载场景可能无效，通过 bash 调用兜底）
chmod +x "${SCRIPT_DIR}"/scripts/*.sh 2>/dev/null || true

# 加载配置和工具
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib/utils.sh"

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
    echo "  --no-mirror        禁用 Go 镜像代理，使用官方源直连"
    echo "  --skip-check       跳过系统环境预检测（适用于自动化场景）"
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

# 预扫描：提前处理 --no-mirror、--skip-check 和 --help
for arg in "$@"; do
    if [[ "$arg" == "--no-mirror" ]]; then
        export USE_GO_MIRROR=false
    fi
    if [[ "$arg" == "--skip-check" ]]; then
        SKIP_PREFLIGHT=true
    fi
    if [[ "$arg" == "--help" ]]; then
        SKIP_PREFLIGHT=true
    fi
done

# 加载环境检测库
source "${SCRIPT_DIR}/lib/detect.sh"

# 环境预检：检测系统兼容性，非兼容环境需要二次确认
if [[ "${SKIP_PREFLIGHT:-false}" != "true" ]]; then
    run_env_preflight
fi

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            bash "${SCRIPT_DIR}/scripts/setup_apt.sh"
            bash "${SCRIPT_DIR}/scripts/install_deps.sh"
            bash "${SCRIPT_DIR}/scripts/setup_wsl.sh"
            bash "${SCRIPT_DIR}/scripts/setup_git.sh"
            bash "${SCRIPT_DIR}/scripts/setup_ssh_server.sh" $SSH_PORT_DEFAULT
            bash "${SCRIPT_DIR}/scripts/setup_ssh_client.sh"
            bash "${SCRIPT_DIR}/scripts/setup_miniconda.sh"
            bash "${SCRIPT_DIR}/scripts/setup_node.sh"
            bash "${SCRIPT_DIR}/scripts/setup_rust.sh"
            bash "${SCRIPT_DIR}/scripts/setup_go.sh"
            bash "${SCRIPT_DIR}/scripts/setup_lsp.sh"
            shift
            ;;
        --apt)
            bash "${SCRIPT_DIR}/scripts/setup_apt.sh"
            shift
            ;;
        --deps)
            bash "${SCRIPT_DIR}/scripts/install_deps.sh"
            shift
            ;;
        --wsl)
            bash "${SCRIPT_DIR}/scripts/setup_wsl.sh"
            shift
            ;;
        --git)
            bash "${SCRIPT_DIR}/scripts/setup_git.sh"
            shift
            ;;
        --ssh-server)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                bash "${SCRIPT_DIR}/scripts/setup_ssh_server.sh" "$2"
                shift 2
            else
                bash "${SCRIPT_DIR}/scripts/setup_ssh_server.sh" $SSH_PORT_DEFAULT
                shift
            fi
            ;;
        --ssh-client)
            bash "${SCRIPT_DIR}/scripts/setup_ssh_client.sh"
            shift
            ;;
        --conda)
            bash "${SCRIPT_DIR}/scripts/setup_miniconda.sh"
            shift
            ;;
        --node)
            bash "${SCRIPT_DIR}/scripts/setup_node.sh"
            shift
            ;;
        --rust)
            bash "${SCRIPT_DIR}/scripts/setup_rust.sh"
            shift
            ;;
        --go)
            bash "${SCRIPT_DIR}/scripts/setup_go.sh"
            shift
            ;;
        --lsp)
            bash "${SCRIPT_DIR}/scripts/setup_lsp.sh"
            shift
            ;;
        --no-mirror)
            export USE_GO_MIRROR=false
            log_info "已禁用 Go 镜像代理，将使用官方源直连。"
            shift
            ;;
        --skip-check)
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
