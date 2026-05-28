#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"

setup_miniconda() {
    # 完整配置检查：miniconda3 + conda + dev 环境
    local conda_bin="$HOME/miniconda3/bin/conda"
    if [ -d "$HOME/miniconda3" ] && [ -x "$conda_bin" ]; then
        if $conda_bin info --envs 2>/dev/null | grep -q "^${CONDA_ENV_NAME} "; then
            log_success "Miniconda 已完整配置，跳过。"
            log_info "  conda: $($conda_bin --version 2>/dev/null), 环境 '${CONDA_ENV_NAME}' 已存在"
            return 0
        fi
    fi

    log_info "Installing/Configuring Miniconda..."

    if [ ! -d "$HOME/miniconda3" ]; then
        local installer="Miniconda3-latest-Linux-x86_64.sh"
        log_info "Downloading Miniconda installer..."
        curl --connect-timeout 5 --retry 1 --retry-delay 2 -fSL "${MIRROR_ANACONDA}/miniconda/${installer}" -o /tmp/${installer} || handle_net_error
        bash /tmp/${installer} -b -p "$HOME/miniconda3"
        rm -f /tmp/${installer}

        # Init
        eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
        $HOME/miniconda3/bin/conda init
    else
        log_info "Miniconda directory exists. Re-running configuration..."
        eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
    fi

    # Config Mirrors
    log_info "Configuring Conda mirrors (Tsinghua)..."
    cat > "$HOME/.condarc" <<EOF
channels:
  - defaults
show_channel_urls: true
default_channels:
  - ${MIRROR_ANACONDA}/pkgs/main
  - ${MIRROR_ANACONDA}/pkgs/r
  - ${MIRROR_ANACONDA}/pkgs/msys2
custom_channels:
  conda-forge: ${MIRROR_ANACONDA}/cloud
  pytorch: ${MIRROR_ANACONDA}/cloud
EOF

    # Create dev env
    if $conda_bin info --envs | grep -q "^${CONDA_ENV_NAME} "; then
        log_info "Conda 环境 '${CONDA_ENV_NAME}' 已存在，跳过创建。"
    else
        log_info "Creating '${CONDA_ENV_NAME}' environment with Python ${PYTHON_VERSION}..."
        $conda_bin create -n ${CONDA_ENV_NAME} python=${PYTHON_VERSION} -y
    fi

    log_success "Miniconda configured."
}

setup_miniconda
