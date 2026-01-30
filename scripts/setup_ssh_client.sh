#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"

setup_ssh_client() {
    local key_type="ed25519"
    local key_path="$HOME/.ssh/id_${key_type}"

    # Check if key already exists
    if check_and_confirm "SSH Client Key ($key_type)" "[ -f \"$key_path\" ]"; then
        log_info "Generating SSH Ed25519 Key Pair..."
        
        # Ensure .ssh directory exists
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"

        if [ -f "$key_path" ]; then
            log_warn "Existing key found at $key_path. Overwriting..."
            rm -f "$key_path" "$key_path.pub"
        fi

        # Generate key
        # -t: type, -a: rounds (for ed25519 this is implicit/ignored but good practice for others), 
        # -C: comment, -f: output file, -N: new passphrase (empty for no passphrase)
        ssh-keygen -t "$key_type" -C "$USER@$HOSTNAME" -f "$key_path" -N ""
        
        log_success "SSH Key generated at $key_path"
        log_info "Public Key Content:"
        cat "$key_path.pub"
    fi
}

setup_ssh_client
