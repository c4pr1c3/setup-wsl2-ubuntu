#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"

setup_go() {
    # 完整配置检查：g + go + GOPROXY
    if command -v g >/dev/null && command -v go >/dev/null; then
        if [[ "$USE_GO_MIRROR" == "true" ]]; then
            local current_proxy
            current_proxy=$(go env GOPROXY 2>/dev/null)
            if echo "$current_proxy" | grep -q "goproxy"; then
                log_success "Go (g) 已完整配置，跳过。"
                log_info "  go: $(go version 2>&1 | awk '{print $3}'), GOPROXY: ${current_proxy}"
                return 0
            fi
        else
            log_success "Go (g) 已完整配置，跳过。"
            log_info "  go: $(go version 2>&1 | awk '{print $3}')"
            return 0
        fi
    fi

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

    # 配置镜像代理
    if [[ "$USE_GO_MIRROR" == "true" ]]; then
        export G_MIRROR="${MIRROR_GOLANG}"
        if ! grep -q "G_MIRROR" "$HOME/.g/env"; then
            echo "export G_MIRROR=${MIRROR_GOLANG}" >> "$HOME/.g/env"
        fi
    fi

    log_info "Installing Go (latest stable)..."
    g install latest

    if [[ "$USE_GO_MIRROR" == "true" ]]; then
        log_info "Configuring GOPROXY (${GOPROXY_URL})..."
        go env -w GOPROXY=${GOPROXY_URL}
    fi

    log_success "Go configured."
}

setup_go
