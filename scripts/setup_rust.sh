#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"

setup_rust() {
    # 完整配置检查：cargo + crates.io 镜像配置
    if command -v cargo >/dev/null; then
        if [ -f "$HOME/.cargo/config" ] && grep -q "replace-with.*mirror\|mirrors.tuna" "$HOME/.cargo/config" 2>/dev/null; then
            log_success "Rust (Cargo) 已完整配置，跳过。"
            log_info "  cargo: $(cargo --version 2>/dev/null)"
            return 0
        fi
    fi

    log_info "Installing/Configuring Rust (Cargo)..."

    export RUSTUP_DIST_SERVER=${MIRROR_RUSTUP}
    export RUSTUP_UPDATE_ROOT=${MIRROR_RUSTUP}/rustup

    if ! command -v cargo >/dev/null; then
        log_info "Downloading Rust installer..."
        curl --connect-timeout 5 --retry 1 --retry-delay 2 --proto '=https' --tlsv1.2 -sSf "$URL_RUSTUP_INSTALLER" -o /tmp/rustup.sh || handle_net_error
        sh /tmp/rustup.sh -y
        rm -f /tmp/rustup.sh
        source "$HOME/.cargo/env"
    fi

    # Config crates.io mirror
    mkdir -p "$HOME/.cargo"
    cat > "$HOME/.cargo/config" <<EOF
[source.crates-io]
replace-with = 'mirror'

[source.mirror]
registry = "${MIRROR_CRATES_IO}"
EOF

    log_success "Rust configured."
}

setup_rust
