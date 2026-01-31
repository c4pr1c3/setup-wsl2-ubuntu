#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"

setup_rust() {
    if check_and_confirm "Rust (Cargo)" "command -v cargo >/dev/null"; then
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
    fi
}

setup_rust
