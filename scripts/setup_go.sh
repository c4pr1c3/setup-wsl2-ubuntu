#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"

setup_go() {
    if check_and_confirm "Go (g)" "command -v g >/dev/null"; then
        log_info "Installing/Configuring Go (using 'g' version manager)..."
        
        # Using 'g' (voidint/g)
        if ! command -v g >/dev/null; then
            log_info "Installing 'g'..."
            log_info "Downloading g installer..."
            curl --connect-timeout 5 --retry 1 --retry-delay 2 -sSL "$URL_G_INSTALLER" -o /tmp/g_install.sh || handle_net_error
            bash /tmp/g_install.sh
            rm -f /tmp/g_install.sh
            
            # Source env
            [ -s "$HOME/.g/env" ] && source "$HOME/.g/env"
            
            # Add to bashrc
            if ! grep -q ".g/env" "$HOME/.bashrc"; then
                 echo '[ -s "$HOME/.g/env" ] && \. "$HOME/.g/env"' >> "$HOME/.bashrc"
            fi
        fi

        # Config Mirror
        export G_MIRROR="${MIRROR_GOLANG}"
        # Persist G_MIRROR
        if ! grep -q "G_MIRROR" "$HOME/.g/env"; then
            echo "export G_MIRROR=${MIRROR_GOLANG}" >> "$HOME/.g/env"
        fi
        
        log_info "Installing Go (latest stable)..."
        g install latest
        
        log_info "Configuring GOPROXY..."
        go env -w GOPROXY=${GOPROXY_URL}
        
        log_success "Go configured."
    fi
}

setup_go
