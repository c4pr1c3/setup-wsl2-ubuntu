#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"
source "$(dirname "$0")/../lib/detect.sh"

setup_apt() {
    # 检测当前系统版本代号
    detect_os
    local codename="$DETECTED_CODENAME"

    if [ -z "$codename" ]; then
        log_error "无法检测当前系统的 Ubuntu 版本代号 (检测到: ${DETECTED_ID} ${DETECTED_VERSION_ID})。"
        log_error "APT 源配置需要正确的版本代号。请确认您的系统版本。"
        exit 1
    fi

    log_info "检测到 Ubuntu 版本代号: ${codename} (${DETECTED_VERSION_ID})"

    # Idempotency check: Check if sources.list backup exists or if Tsinghua mirror is already mentioned
    if check_and_confirm "APT Configuration" "grep -q 'mirrors.tuna.tsinghua.edu.cn' /etc/apt/sources.list"; then
        log_info "Configuring APT to use Tsinghua Mirrors..."

        if [ ! -f /etc/apt/sources.list.bak ]; then
            sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
            log_info "Backed up sources.list to /etc/apt/sources.list.bak"
        fi

        sudo tee /etc/apt/sources.list > /dev/null <<EOF
# Default comment: sources.list configured by setup_dev_env.sh
deb ${MIRROR_UBUNTU} ${codename} main restricted universe multiverse
deb ${MIRROR_UBUNTU} ${codename}-updates main restricted universe multiverse
deb ${MIRROR_UBUNTU} ${codename}-backports main restricted universe multiverse
deb ${MIRROR_UBUNTU} ${codename}-security main restricted universe multiverse
EOF

        # Ubuntu 24.04+ 使用 DEB822 格式源文件，需禁用以避免与 sources.list 冲突
        if [ "$codename" != "jammy" ] && [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
            if [ ! -f /etc/apt/sources.list.d/ubuntu.sources.bak ]; then
                sudo cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak
                log_info "已备份 DEB822 格式源文件到 /etc/apt/sources.list.d/ubuntu.sources.bak"
            fi
            sudo mv /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.disabled
            log_info "已禁用 DEB822 格式源文件，改用传统 sources.list 格式。"
        fi

        log_info "Updating APT cache..."
        sudo apt-get update
        log_success "APT configured."
    fi
}

setup_apt
