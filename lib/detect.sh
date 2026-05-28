#!/bin/bash

# 系统环境检测库
# 提供 OS 检测、WSL 检测、版本兼容性检查和风险警告功能

# 检测操作系统信息
# 设置全局变量: DETECTED_ID, DETECTED_VERSION_ID, DETECTED_CODENAME
detect_os() {
    if [ ! -f /etc/os-release ]; then
        DETECTED_ID="unknown"
        DETECTED_VERSION_ID=""
        DETECTED_CODENAME=""
        return 1
    fi

    # shellcheck disable=SC1091
    eval "$(grep -E '^(ID|VERSION_ID|UBUNTU_CODENAME)=' /etc/os-release)"

    DETECTED_ID="${ID:-unknown}"
    DETECTED_VERSION_ID="${VERSION_ID:-}"
    DETECTED_CODENAME="${UBUNTU_CODENAME:-}"

    # 如果没有 UBUNTU_CODENAME，尝试从映射表获取
    if [ -z "$DETECTED_CODENAME" ] && [ -n "$DETECTED_VERSION_ID" ]; then
        DETECTED_CODENAME=$(get_ubuntu_codename "$DETECTED_VERSION_ID")
    fi

    export DETECTED_ID DETECTED_VERSION_ID DETECTED_CODENAME
    return 0
}

# 检测是否运行在 WSL2 环境中
# 返回: 0 = WSL2, 1 = 非 WSL
detect_wsl() {
    if [ -f /proc/version ] && grep -qi "microsoft" /proc/version; then
        return 0
    fi
    return 1
}

# 根据版本号获取 Ubuntu 代号
# 参数: $1 = 版本号 (如 "22.04")
# 输出: 代号名 (如 "jammy")，未知版本返回空
get_ubuntu_codename() {
    local version="$1"
    local codename_map="22.04:jammy 24.04:noble 26.04:resolute"

    for entry in $codename_map; do
        local ver="${entry%%:*}"
        local codename="${entry##*:}"
        if [ "$ver" = "$version" ]; then
            echo "$codename"
            return 0
        fi
    done

    return 1
}

# 检查当前环境兼容性
# 返回兼容级别并设置全局变量 ENV_COMPAT_LEVEL
# 兼容级别: full (Ubuntu+WSL2), partial (Ubuntu 非 WSL2), unsupported (非 Ubuntu)
check_env_compat() {
    detect_os

    local is_ubuntu=false
    local is_supported_version=false
    local is_wsl=false

    # 检查是否为 Ubuntu
    if [ "$DETECTED_ID" = "ubuntu" ]; then
        is_ubuntu=true
        # 检查版本是否在支持列表中
        for ver in $SUPPORTED_UBUNTU_VERSIONS; do
            if [ "$DETECTED_VERSION_ID" = "$ver" ]; then
                is_supported_version=true
                break
            fi
        done
    fi

    # 检查是否为 WSL2
    if detect_wsl; then
        is_wsl=true
    fi

    # 确定兼容级别
    if $is_ubuntu && $is_supported_version && $is_wsl; then
        ENV_COMPAT_LEVEL="full"
    elif $is_ubuntu && $is_supported_version; then
        ENV_COMPAT_LEVEL="partial"
    elif $is_ubuntu; then
        ENV_COMPAT_LEVEL="partial-unsupported-version"
    else
        ENV_COMPAT_LEVEL="unsupported"
    fi

    export ENV_COMPAT_LEVEL
}

# 显示环境检测结果
show_detect_result() {
    echo ""
    log_info "===== 系统环境检测 ====="
    echo "  操作系统:   ${DETECTED_ID} ${DETECTED_VERSION_ID}"
    echo "  代号:       ${DETECTED_CODENAME:-未知}"
    echo "  WSL2 环境:  $(detect_wsl && echo '是' || echo '否')"
    echo "  兼容级别:   ${ENV_COMPAT_LEVEL}"
    echo ""
}

# 显示非 WSL2 环境的风险警告并等待用户确认
# 返回: 0 = 用户确认继续, 1 = 用户选择退出
show_non_wsl_risk_warning() {
    log_warn "================================================================="
    log_warn "  检测到当前运行环境非 WSL2！以下操作可能存在风险："
    log_warn "================================================================="
    echo ""
    log_warn "[高风险] APT 源配置"
    log_warn "  如果 Ubuntu 版本不在支持列表中，apt update 将失败。"
    log_warn "  当前支持版本: ${SUPPORTED_UBUNTU_VERSIONS}"
    echo ""
    log_warn "[中风险] SSH 服务端配置 (Supervisor 管理)"
    log_warn "  本脚本使用 Supervisor 替代 systemd 管理 SSH 服务，"
    log_warn "  这是为 WSL2 环境设计的方案。在原生 Linux 上，"
    log_warn "  systemd 已内置服务管理能力，Supervisor 是多余的。"
    log_warn "  脚本还会禁用系统默认 SSH 服务 (systemctl disable ssh)。"
    echo ""
    log_warn "[低风险] WSL 配置 (/etc/wsl.conf)"
    log_warn "  将写入 /etc/wsl.conf 配置文件，该文件仅在 WSL 环境"
    log_warn "  中有效。在非 WSL 环境中，此配置不会产生任何效果，"
    log_warn "  但会在系统中留下一个无意义的配置文件。"
    echo ""
    log_warn "[低风险] Windows PATH 禁用"
    log_warn "  appendWindowsPath = false 配置在非 WSL 环境无意义。"
    echo ""
    log_warn "[低风险] XDG_RUNTIME_DIR 修复"
    log_warn "  .bashrc 中的 XDG_RUNTIME_DIR workaround 仅 WSL2 需要，"
    log_warn "  在其他环境中无害但属于不必要的环境变量操作。"
    echo ""
    log_warn "[低风险] WSL 重启提示"
    log_warn "  脚本会提示执行 'wsl --shutdown'，该命令在非 WSL 环境"
    log_warn "  中无法执行，可能误导用户。"
    echo ""
    log_warn "================================================================="

    echo ""
    read -p "我已了解上述风险，确认继续执行？请输入 yes 继续: " response
    case "$response" in
        yes)
            log_info "用户确认继续。"
            return 0
            ;;
        *)
            log_info "用户选择退出。"
            return 1
            ;;
    esac
}

# 显示非 Ubuntu 系统的警告
# 返回: 0 = 用户确认继续, 1 = 用户选择退出
show_non_ubuntu_warning() {
    log_error "================================================================="
    log_error "  当前系统不是 Ubuntu！"
    log_error "  检测到: ${DETECTED_ID} ${DETECTED_VERSION_ID}"
    log_error "================================================================="
    log_error "  本脚本专为 Ubuntu 设计，使用 APT 包管理器。"
    log_error "  在其他 Linux 发行版上运行可能导致系统配置错误。"
    echo ""
    read -p "确定要继续吗？请输入 yes 继续: " response
    case "$response" in
        yes)
            log_warn "用户强制继续，后续操作可能失败。"
            return 0
            ;;
        *)
            log_info "用户选择退出。"
            return 1
            ;;
    esac
}

# 显示不支持版本的警告
# 返回: 0 = 用户确认继续, 1 = 用户选择退出
show_unsupported_version_warning() {
    log_warn "================================================================="
    log_warn "  当前 Ubuntu 版本不在官方支持列表中！"
    log_warn "  检测到版本: ${DETECTED_VERSION_ID} (${DETECTED_CODENAME:-未知代号})"
    log_warn "  支持版本: ${SUPPORTED_UBUNTU_VERSIONS}"
    log_warn "================================================================="
    log_warn "  APT 源配置可能无法正确匹配，导致软件包无法安装。"
    echo ""
    read -p "确定要继续吗？请输入 yes 继续: " response
    case "$response" in
        yes)
            log_warn "用户确认继续使用非官方支持版本。"
            return 0
            ;;
        *)
            log_info "用户选择退出。"
            return 1
            ;;
    esac
}

# 全局环境预检入口
# 在 main.sh 中调用，根据检测结果决定是否继续
run_env_preflight() {
    check_env_compat
    show_detect_result

    case "$ENV_COMPAT_LEVEL" in
        full)
            log_success "环境检测通过: Ubuntu ${DETECTED_VERSION_ID} (WSL2)"
            return 0
            ;;
        partial)
            # Ubuntu 支持版本，但非 WSL2
            if ! show_non_wsl_risk_warning; then
                exit 0
            fi
            ;;
        partial-unsupported-version)
            # Ubuntu 但版本不支持
            if [ "$DETECTED_ID" = "ubuntu" ]; then
                if ! show_non_wsl_risk_warning; then
                    exit 0
                fi
                if ! show_unsupported_version_warning; then
                    exit 0
                fi
            fi
            ;;
        unsupported)
            # 非 Ubuntu 系统
            if ! show_non_ubuntu_warning; then
                exit 0
            fi
            ;;
    esac

    return 0
}
