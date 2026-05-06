#!/bin/bash

# LSP Language Server 安装脚本
# 安装 Go/Python/JS/TS/HTML/CSS 的 Language Server，并自动配置 OMC（如已安装）

source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"

# 检测 OMC servers.js 路径（动态，不硬编码版本号）
detect_omc_servers_js() {
    local omc_cache="$HOME/.claude/plugins/cache/omc"
    if [[ -d "$omc_cache" ]]; then
        find "$omc_cache" -path "*/dist/tools/lsp/servers.js" -type f 2>/dev/null | sort -V | tail -1
    fi
}

# 检测所有 LSP server 是否已安装
all_lsp_installed() {
    for cmd in "${LSP_COMMANDS[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            return 1
        fi
    done
    return 0
}

# 安装 gopls（Go LSP）
install_gopls() {
    if command -v gopls >/dev/null 2>&1; then
        log_info "gopls 已安装: $(gopls version 2>/dev/null | head -1)"
        return 0
    fi

    if ! command -v go >/dev/null 2>&1; then
        log_error "未检测到 Go 环境，请先运行 './main.sh --go' 安装 Go。"
        return 1
    fi

    log_info "正在安装 gopls (Go Language Server)..."

    # 确保当前 session 的 GOPROXY 生效（go env -w 仅影响后续新 session）
    if [[ "$USE_GO_MIRROR" == "true" ]]; then
        export GOPROXY="${GOPROXY_URL}"
    fi

    go install "$LSP_GOINSTALL_CMD" || {
        log_error "gopls 安装失败！请检查 Go 环境和网络连接。"
        return 1
    }
    log_success "gopls 安装完成。"
}

# 安装 npm LSP 包
install_npm_lsp_packages() {
    if ! command -v npm >/dev/null 2>&1; then
        log_error "未检测到 npm，请先运行 './main.sh --node' 安装 Node.js。"
        return 1
    fi

    for pkg in "${LSP_NPM_PACKAGES[@]}"; do
        # 检测包是否已全局安装
        if npm list -g "$pkg" >/dev/null 2>&1; then
            log_info "$pkg 已安装。"
        else
            log_info "正在安装 $pkg..."
            npm install -g "$pkg" || {
                log_error "$pkg 安装失败！"
                return 1
            }
            log_success "$pkg 安装完成。"
        fi
    done
}

# 验证所有 LSP server 安装状态
verify_lsp_installation() {
    local failed=0
    echo ""
    log_info "===== LSP Server 安装验证 ====="

    local descriptions=(
        "gopls:Go"
        "vscode-html-language-server:HTML"
        "vscode-css-language-server:CSS"
        "typescript-language-server:JS/TS"
        "pyright:Python"
    )

    for desc in "${descriptions[@]}"; do
        local cmd="${desc%%:*}"
        local lang="${desc##*:}"
        if command -v "$cmd" >/dev/null 2>&1; then
            log_success "  $lang → $cmd ✓"
        else
            log_error "  $lang → $cmd ✗ (未找到)"
            failed=$((failed + 1))
        fi
    done

    echo ""
    if [[ $failed -eq 0 ]]; then
        log_success "所有 LSP Server 安装验证通过！"
    else
        log_error "$failed 个 LSP Server 安装验证失败，请检查上方错误信息。"
        return 1
    fi
}

# 配置 OMC（替换 Python server: ty → pyright）
configure_omc() {
    local servers_js
    servers_js=$(detect_omc_servers_js)

    if [[ -z "$servers_js" ]]; then
        log_info "未检测到 OMC 插件，跳过自动配置。"
        show_manual_guide
        return 0
    fi

    log_info "检测到 OMC servers.js: $servers_js"

    # 备份
    cp "$servers_js" "${servers_js}.bak"
    log_info "已备份至 ${servers_js}.bak"

    # 替换 Python server: ty → pyright
    if grep -q "command: 'ty'" "$servers_js"; then
        sed -i "s/command: 'ty'/command: 'pyright'/" "$servers_js"
        sed -i "s/args: \['server'\]/args: ['--stdio']/" "$servers_js"
        sed -i "s|installHint: 'Install ty from https://github.com/astral-sh/ty'|installHint: 'npm install -g pyright'|" "$servers_js"
        sed -i "s/name: 'Python Language Server (ty)'/name: 'Python Language Server (pyright)'/" "$servers_js"
        log_success "已将 OMC Python LSP 从 ty 替换为 pyright。"
    else
        log_info "OMC Python LSP 配置无需修改（可能已配置）。"
    fi

    log_success "OMC LSP 配置完成。"
}

# 纯净版 Claude Code 手动配置向导
show_manual_guide() {
    echo ""
    log_info "===== LSP 手动配置向导 ====="
    echo ""
    echo "以下 LSP Server 已安装成功："
    echo "  gopls         → Go"
    echo "  pyright       → Python"
    echo "  typescript-language-server → JavaScript / TypeScript"
    echo "  vscode-html-language-server → HTML"
    echo "  vscode-css-language-server → CSS"
    echo ""
    echo "如需在 Claude Code 中启用 LSP 功能，建议安装 oh-my-claudecode 插件："
    echo "  https://github.com/gofullthrottle/oh-my-claudecode"
    echo ""
    echo "安装后 LSP 工具将自动可用（诊断、跳转定义、查找引用等）。"
    echo ""
}

# 主安装流程
setup_lsp() {
    log_info "===== LSP Language Server 安装配置 ====="

    # 幂等性检查
    if all_lsp_installed; then
        log_warn "所有 LSP Server 似乎已安装。"
        read -p "是否重新安装/覆盖？[y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY])
                log_info "将重新安装..."
                ;;
            *)
                log_info "跳过 LSP Server 安装。"
                # 即使跳过安装，仍执行 OMC 配置检查
                configure_omc
                return 0
                ;;
        esac
    fi

    # 1. 安装 gopls
    install_gopls || return 1

    # 2. 安装 npm LSP 包
    install_npm_lsp_packages || return 1

    # 3. 验证安装
    verify_lsp_installation || return 1

    # 4. OMC 检测与配置（或显示手动向导）
    configure_omc

    log_success "LSP Server 安装配置完成！"
}

setup_lsp
