#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check and confirm action
# Usage: check_and_confirm "Description" "Check Command"
# Returns 0 to proceed, 1 to skip
check_and_confirm() {
    local description="$1"
    
    log_info "Checking: $description..."
    
    # If the check command returns 0 (true), it means the component is already present/configured
    if eval "$2"; then
        log_warn "$description appears to be already configured."
        read -p "Do you want to re-configure/overwrite it? [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY]) 
                return 0 
                ;;
            *)
                log_info "Skipping $description."
                return 1
                ;;
        esac
    else
        # Not configured, proceed
        return 0
    fi
}
