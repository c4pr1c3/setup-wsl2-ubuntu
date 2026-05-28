#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"
source "$(dirname "$0")/../lib/detect.sh"

setup_wsl() {
    # WSL 环境守卫：非 WSL 环境显示警告
    if ! detect_wsl; then
        log_warn "检测到当前环境非 WSL2。"
        log_warn "/etc/wsl.conf 配置文件仅在 WSL 环境中有效。"
        log_warn "在非 WSL 环境中，此操作将创建一个无效的配置文件。"
        read -p "是否仍然继续配置 WSL？[y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY])
                log_warn "继续配置 WSL（非 WSL 环境）..."
                ;;
            *)
                log_info "跳过 WSL 配置。"
                return 0
                ;;
        esac
    fi

    # Check if /etc/wsl.conf contains the target configuration (simple check)
    local is_configured="grep -q 'appendWindowsPath = false' /etc/wsl.conf 2>/dev/null && grep -q 'systemd=true' /etc/wsl.conf 2>/dev/null"

    if check_and_confirm "WSL 配置 (/etc/wsl.conf)" "$is_configured"; then
        log_info "正在配置 WSL 基础设置..."

        # Backup
        if [ -f /etc/wsl.conf ]; then
            if [ ! -f /etc/wsl.conf.bak ]; then
                sudo cp /etc/wsl.conf /etc/wsl.conf.bak
                log_info "已备份原配置到 /etc/wsl.conf.bak"
            fi
        fi

        # Write config
        sudo tee /etc/wsl.conf > /dev/null <<EOF
[network]
generateHosts = false

[boot]
systemd=true

[interop]
appendWindowsPath = false
EOF

        log_success "WSL 配置完成。"
        log_warn "注意：WSL 配置更改需要重启 WSL 才能生效 (wsl --shutdown)。"
        log_warn "appendWindowsPath = false 将导致无法直接在 WSL 中运行 Windows 命令（如 code, explorer.exe）。"
        log_warn "如需使用 Windows 命令，请手动将 Windows 路径添加到 PATH 或修改配置。"
    fi
}

setup_wsl
