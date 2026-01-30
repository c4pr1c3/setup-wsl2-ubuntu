#!/bin/bash

# Source config and utils
source "$(dirname "$0")/../config.sh"
source "$(dirname "$0")/../lib/utils.sh"

setup_miniconda() {
    if check_and_confirm "Miniconda" "[ -d \"$HOME/miniconda3\" ]"; then
        log_info "Installing/Configuring Miniconda..."
        
        # If directory exists but user confirmed overwrite, we might need to handle it or just let the installer handle/fail
        # The installer -b -u (update) or just skip if exists? 
        # Since check_and_confirm returned true (meaning user said yes to overwrite OR it didn't exist),
        # but the check condition was "exists". So if it exists, user said YES to re-configure.
        
        if [ ! -d "$HOME/miniconda3" ]; then
            local installer="Miniconda3-latest-Linux-x86_64.sh"
            wget "${MIRROR_ANACONDA}/miniconda/${installer}" -O /tmp/${installer}
            bash /tmp/${installer} -b -p "$HOME/miniconda3"
            rm /tmp/${installer}
            
            # Init
            eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
            $HOME/miniconda3/bin/conda init
        else
            log_info "Miniconda directory exists. Re-running configuration..."
            eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
        fi

        # Config Mirrors
        log_info "Configuring Conda mirrors (Tsinghua)..."
        conda config --set show_channel_urls yes
        conda config --remove-key channels 2>/dev/null || true
        conda config --add channels "${MIRROR_ANACONDA}/cloud/pytorch/"
        conda config --add channels "${MIRROR_ANACONDA}/cloud/menpo/"
        conda config --add channels "${MIRROR_ANACONDA}/cloud/bioconda/"
        conda config --add channels "${MIRROR_ANACONDA}/cloud/msys2/"
        conda config --add channels "${MIRROR_ANACONDA}/cloud/conda-forge/"
        conda config --add channels "${MIRROR_ANACONDA}/pkgs/main/"
        conda config --add channels "${MIRROR_ANACONDA}/pkgs/free/"

        # Create dev env
        if conda info --envs | grep -q "^${CONDA_ENV_NAME} "; then
            log_warn "Conda environment '${CONDA_ENV_NAME}' already exists."
             # We rely on the top-level confirmation or ask specifically for the env?
             # Let's just update it or leave it.
             log_info "Skipping creation of existing environment '${CONDA_ENV_NAME}'."
        else
            log_info "Creating '${CONDA_ENV_NAME}' environment with Python ${PYTHON_VERSION}..."
            conda create -n ${CONDA_ENV_NAME} python=${PYTHON_VERSION} -y
        fi
        
        log_success "Miniconda configured."
    fi
}

setup_miniconda
