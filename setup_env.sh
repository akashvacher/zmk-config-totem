#!/bin/bash

set -euo pipefail

echo "🛠  Setting up ZMK build environment"
echo "==================================="

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

# Configurable via env; defaults chosen to match the guide and build script
ZSDK_VERSION="${ZSDK_VERSION:-0.16.8}"
ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ]; then
    SDK_ARCH="macos-aarch64"
else
    SDK_ARCH="macos-x86_64"
fi
ZSDK_DIR_DEFAULT="$HOME/code/fun/zephyr-sdk-$ZSDK_VERSION"
ZEPHYR_SDK_INSTALL_DIR="${ZEPHYR_SDK_INSTALL_DIR:-$ZSDK_DIR_DEFAULT}"
ZSDK_TAR="zephyr-sdk-${ZSDK_VERSION}_${SDK_ARCH}.tar.xz"
ZSDK_URL="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/${ZSDK_TAR}"

ensure_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "❌ Homebrew is required. Install from https://brew.sh and re-run."
        exit 1
    fi
}

install_brew_packages() {
    echo "📦 Installing Homebrew packages (cmake, ninja, git, python3, dtc, wget, zip)"
    brew install cmake ninja git python3 dtc wget zip || true
}

ensure_venv() {
    if [ ! -d "$REPO_ROOT/zmk-env" ]; then
        echo "🐍 Creating Python virtual environment"
        python3 -m venv "$REPO_ROOT/zmk-env"
    fi
    echo "📦 Activating virtual environment and installing Python deps (west)"
    # shellcheck source=/dev/null
    source "$REPO_ROOT/zmk-env/bin/activate"
    python3 -m pip install --upgrade pip
    pip install -U west
}

west_setup() {
    echo "🌲 Initializing west workspace"
    if [ ! -d "$REPO_ROOT/zmk" ]; then
        west init -l "$REPO_ROOT/config"
    fi
    west update
    echo "🐍 Installing Zephyr Python requirements"
    pip install -r "$REPO_ROOT/zephyr/scripts/requirements.txt"
}

install_zephyr_sdk() {
    if [ -x "$ZEPHYR_SDK_INSTALL_DIR/arm-zephyr-eabi/bin/arm-zephyr-eabi-gcc" ]; then
        echo "✅ Zephyr SDK already installed at $ZEPHYR_SDK_INSTALL_DIR"
        return
    fi

    echo "⬇️  Downloading Zephyr SDK $ZSDK_VERSION for $SDK_ARCH"
    mkdir -p "$(dirname "$ZEPHYR_SDK_INSTALL_DIR")"
    cd "$(dirname "$ZEPHYR_SDK_INSTALL_DIR")"

    if [ ! -f "$ZSDK_TAR" ]; then
        curl -L -o "$ZSDK_TAR" "$ZSDK_URL"
    fi

    echo "📦 Extracting SDK"
    tar xf "$ZSDK_TAR"
    if [ ! -d "zephyr-sdk-$ZSDK_VERSION" ]; then
        echo "❌ Expected directory zephyr-sdk-$ZSDK_VERSION not found after extract"
        exit 1
    fi
    mv -f "zephyr-sdk-$ZSDK_VERSION" "$ZEPHYR_SDK_INSTALL_DIR"

    echo "⚙️  Running Zephyr SDK setup (non-interactive)"
    cd "$ZEPHYR_SDK_INSTALL_DIR"
    # Install only the needed toolchain for ARM targets; pipe yes to auto-confirm if prompted
    yes | ./setup.sh -t arm-zephyr-eabi || ./setup.sh -t arm-zephyr-eabi
}

persist_env() {
    echo "📝 Persisting environment variables to shell profiles"
    add_line() {
        local file="$1"; shift
        local line="$1"
        if [ -f "$file" ]; then
            if grep -qsF "$line" "$file"; then return; fi
        fi
        echo "$line" >> "$file"
    }
    add_line "$HOME/.zshrc" "export ZEPHYR_TOOLCHAIN_VARIANT=zephyr"
    add_line "$HOME/.zshrc" "export ZEPHYR_SDK_INSTALL_DIR=$ZEPHYR_SDK_INSTALL_DIR"
    add_line "$HOME/.bash_profile" "export ZEPHYR_TOOLCHAIN_VARIANT=zephyr"
    add_line "$HOME/.bash_profile" "export ZEPHYR_SDK_INSTALL_DIR=$ZEPHYR_SDK_INSTALL_DIR"
}

ensure_homebrew
install_brew_packages
ensure_venv
west_setup
install_zephyr_sdk
persist_env

echo "✅ Environment setup complete. If this is your first run, open a new terminal or 'source' your shell profile to load env vars."


