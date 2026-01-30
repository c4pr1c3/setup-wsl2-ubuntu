#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"

PORT=${1:-$SSH_PORT_DEFAULT}

setup_ssh() {
    # Check if SSH is installed and running on the specified port
    local is_configured="command -v sshd >/dev/null && grep -q \"^Port $PORT\" /etc/ssh/sshd_config"

    if check_and_confirm "OpenSSH Server (Port: $PORT)" "$is_configured"; then
        log_info "Configuring OpenSSH Server (Port: $PORT)..."

        # Install if missing
        if ! command -v sshd >/dev/null; then
            sudo apt-get install -y openssh-server
        fi

        # Backup config
        if [ ! -f /etc/ssh/sshd_config.bak ]; then
            sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
        fi

        # Configure Port
        # Remove existing Port lines (commented or not) and add the new one
        # Use regex to match "Port" at start of line, optional #, followed by space
        sudo sed -i -E '/^#?Port\s+[0-9]+/d' /etc/ssh/sshd_config
        echo "Port $PORT" | sudo tee -a /etc/ssh/sshd_config > /dev/null
        
        log_info "Restarting SSH service..."
        if sudo service ssh restart; then
            log_success "OpenSSH Server running on port $PORT."
            log_info "Note: WSL2 does not always respect systemd enable. You may need to add 'service ssh start' to /etc/wsl.conf or .bashrc if not using systemd."
        else
            log_error "Failed to start SSH service."
        fi
    fi
}

setup_ssh
