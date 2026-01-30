#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"

setup_node() {
    if check_and_confirm "Node.js (fnm)" "command -v fnm >/dev/null"; then
        log_info "Installing/Configuring Node.js (fnm)..."

        # Install fnm
        if ! command -v fnm >/dev/null; then
            curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
            export PATH="$HOME/.local/share/fnm:$PATH"
            eval "$(fnm env --use-on-cd)"
            
            # Add to shellrc if not present
            if ! grep -q "fnm env" "$HOME/.bashrc"; then
                echo 'export PATH="$HOME/.local/share/fnm:$PATH"' >> "$HOME/.bashrc"
                echo 'eval "$(fnm env --use-on-cd)"' >> "$HOME/.bashrc"
            fi
        fi

        # Config Node Mirror for fnm downloads
        export FNM_NODE_DIST_MIRROR="${MIRROR_NODE_DIST}"
        
        log_info "Installing Node.js LTS..."
        fnm install --lts
        fnm use lts-latest
        
        log_info "Configuring npm mirror..."
        npm config set registry ${MIRROR_NPM}
        
        log_success "Node.js configured."
    fi
}

setup_node
