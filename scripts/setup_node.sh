#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"

setup_node() {
    if check_and_confirm "Node.js (fnm)" "command -v fnm >/dev/null"; then
        log_info "Installing/Configuring Node.js (fnm)..."

        # Install fnm
        if ! command -v fnm >/dev/null; then
            log_info "Downloading fnm installer..."
            curl --connect-timeout 5 --retry 1 --retry-delay 2 -fsSL "$URL_FNM_INSTALLER" -o /tmp/fnm_install.sh || handle_net_error
            bash /tmp/fnm_install.sh --skip-shell
            rm -f /tmp/fnm_install.sh

            export PATH="$HOME/.local/share/fnm:$PATH"
            eval "$(fnm env --use-on-cd)"
            
            # Add to shellrc if not present
            if ! grep -q "fnm env" "$HOME/.bashrc"; then
                echo 'export PATH="$HOME/.local/share/fnm:$PATH"' >> "$HOME/.bashrc"
                # Fix for WSL2 where XDG_RUNTIME_DIR might be set but not exist
                echo 'if [ -n "$XDG_RUNTIME_DIR" ] && [ ! -d "$XDG_RUNTIME_DIR" ]; then unset XDG_RUNTIME_DIR; fi' >> "$HOME/.bashrc"
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
