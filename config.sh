#!/bin/bash

# Deb Deps
DEB_DEPS="unzip proxychains4 supervisor"

# Default Configuration
SSH_PORT_DEFAULT=8022

# Mirrors
MIRROR_UBUNTU="https://mirrors.tuna.tsinghua.edu.cn/ubuntu/"
MIRROR_ANACONDA="https://mirrors.tuna.tsinghua.edu.cn/anaconda"
MIRROR_RUSTUP="https://mirrors.tuna.tsinghua.edu.cn/rustup"
MIRROR_GOLANG="https://mirrors.tuna.tsinghua.edu.cn/golang/"
MIRROR_NPM="https://registry.npmmirror.com"
MIRROR_NODE_DIST="https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/"
MIRROR_CRATES_IO="https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
GOPROXY_URL="https://goproxy.cn,direct"

# Install Script URLs
URL_FNM_INSTALLER="https://fnm.vercel.app/install"
URL_RUSTUP_INSTALLER="https://sh.rustup.rs"
URL_G_INSTALLER="https://raw.githubusercontent.com/voidint/g/master/install.sh"

# Versions (if needed)
PYTHON_VERSION="3.13"
CONDA_ENV_NAME="dev"

# ========== LSP Server 配置 ==========
# Go LSP
LSP_GOINSTALL_CMD="golang.org/x/tools/gopls@latest"

# npm LSP 包列表
LSP_NPM_PACKAGES=(
    "vscode-langservers-extracted"       # HTML + CSS + JSON
    "typescript-language-server"          # JS + TS
    "typescript"                          # TS 依赖
    "pyright"                             # Python
)

# 需要验证的 LSP server 可执行命令
LSP_COMMANDS=(
    "gopls"
    "vscode-html-language-server"
    "vscode-css-language-server"
    "typescript-language-server"
    "pyright"
)
