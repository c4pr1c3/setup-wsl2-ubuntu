#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"
source "$(dirname "$0")/../lib/detect.sh"

PORT=${1:-$SSH_PORT_DEFAULT}

setup_ssh() {
    # 非 WSL 环境警告：Supervisor 方案是为 WSL 设计的
    if ! detect_wsl; then
        log_warn "检测到当前环境非 WSL2。"
        log_warn "本脚本使用 Supervisor 管理 SSH 服务，这是为 WSL2 环境设计的方案。"
        log_warn "在原生 Linux 上，systemd 已内置服务管理能力，建议直接使用 systemctl 管理 SSH。"
        log_warn "继续执行将: 安装 Supervisor, 禁用系统 SSH 服务 (systemctl disable ssh)"
        read -p "是否仍然使用 Supervisor 方案？[y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY])
                log_warn "继续使用 Supervisor 方案（非 WSL 环境）..."
                ;;
            *)
                log_info "跳过 SSH 服务端配置。"
                log_info "提示: 在原生 Linux 上，可使用 'sudo apt install openssh-server && sudo systemctl enable --now ssh' 启用 SSH。"
                return 0
                ;;
        esac
    fi

    log_info "配置 OpenSSH Server (Supervisor 管理, 端口: $PORT)..."

    # Install openssh-server and supervisor if missing
    if ! command -v sshd >/dev/null || ! command -v supervisorctl >/dev/null; then
        log_info "安装 openssh-server 和 supervisor..."
        sudo apt-get install -y openssh-server supervisor
    fi

    # Backup config
    if [ ! -f /etc/ssh/sshd_config.bak ]; then
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    fi

    # Configure Port
    sudo sed -i -E '/^#?Port\s+[0-9]+/d' /etc/ssh/sshd_config
    echo "Port $PORT" | sudo tee -a /etc/ssh/sshd_config > /dev/null

    # Generate Host Keys if missing
    log_info "检查/生成 SSH Host Keys..."
    sudo ssh-keygen -A

    # Create Supervisor Config
    log_info "创建 Supervisor 配置 /etc/supervisor/conf.d/sshd.conf ..."
    sudo mkdir -p /etc/supervisor/conf.d
    sudo tee /etc/supervisor/conf.d/sshd.conf > /dev/null <<EOF
[program:sshd]
command=/bin/bash -c 'mkdir -p /run/sshd && /usr/sbin/sshd -D'
autostart=true
autorestart=true
stderr_logfile=/var/log/sshd.err.log
stdout_logfile=/var/log/sshd.out.log
EOF

    # Disable system sshd to avoid conflict
    log_info "禁用系统默认 SSH 服务 (交由 Supervisor 接管)..."
    sudo systemctl disable ssh 2>/dev/null || true
    sudo service ssh stop 2>/dev/null || true

    # Start Supervisor
    log_info "启动/重载 Supervisor..."
    sudo service supervisor start 2>/dev/null || true
    sudo supervisorctl reread
    sudo supervisorctl update
    
    # Check status
    if sudo supervisorctl status sshd | grep -q "RUNNING"; then
        log_success "OpenSSH Server (Supervisor) 已启动，端口: $PORT"
    else
        log_warn "OpenSSH Server 启动状态检查失败，请运行 'sudo supervisorctl status' 查看详情。"
    fi
}

setup_ssh
