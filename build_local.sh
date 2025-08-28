#!/bin/bash

# Build script for TOTEM ZMK firmware with proper naming
# Usage: ./build_local.sh

set -e  # Exit on any error

echo "🔧 Building TOTEM ZMK Firmware Locally"
echo "======================================"

# Ensure we're in the right directory
cd "$(dirname "$0")"

# Activate virtual environment if it exists
if [ -d "zmk-env" ]; then
    echo "📦 Activating Python virtual environment..."
    source zmk-env/bin/activate
fi

# Set Zephyr SDK environment variables (respect existing env, provide sensible defaults)
export ZEPHYR_TOOLCHAIN_VARIANT="${ZEPHYR_TOOLCHAIN_VARIANT:-zephyr}"
export ZEPHYR_SDK_INSTALL_DIR="${ZEPHYR_SDK_INSTALL_DIR:-$HOME/code/fun/zephyr-sdk-0.16.8}"
echo "🔧 Using Zephyr SDK: $ZEPHYR_SDK_INSTALL_DIR"

# Ensure environment is properly set up; if not, run setup script
MISSING=false
if [ ! -x "$ZEPHYR_SDK_INSTALL_DIR/arm-zephyr-eabi/bin/arm-zephyr-eabi-gcc" ]; then
    MISSING=true
fi
if ! command -v west >/dev/null 2>&1; then
    MISSING=true
fi
if [ ! -d "zmk" ] || [ ! -d "zephyr" ]; then
    MISSING=true
fi

if [ "$MISSING" = true ]; then
    echo "🧰 Environment incomplete. Running setup_env.sh..."
    if [ -f "setup_env.sh" ]; then
        bash setup_env.sh
    else
        echo "❌ setup_env.sh not found. Aborting."
        exit 1
    fi
    # Re-activate venv if created by setup
    if [ -d "zmk-env" ]; then
        echo "📦 Re-activating Python virtual environment..."
        # shellcheck disable=SC1091
        source zmk-env/bin/activate
    fi
fi

# Create output directory
mkdir -p output
rm -rf output/*  # Clean previously produced files

# Board and config settings
BOARD="seeeduino_xiao_ble"
CONFIG_PATH="$(pwd)/config"

echo "📍 Config path: $CONFIG_PATH"
echo "🎯 Board: $BOARD"
echo ""

# Build function
build_firmware() {
    local shield=$1
    local build_name=$2
    
    echo "🔨 Building $build_name ($shield)..."
    
    # Build with west (specify source directory) using pristine builds to avoid stale state
    west build -p always -d "build/$build_name" -s zmk/app -b "$BOARD" -- -DSHIELD="$shield" -DZMK_CONFIG="$CONFIG_PATH"
    
    # Copy and rename output file
    if [ -f "build/$build_name/zephyr/zmk.uf2" ]; then
        cp "build/$build_name/zephyr/zmk.uf2" "output/${shield}-${BOARD}-zmk.uf2"
        echo "✅ Created: output/${shield}-${BOARD}-zmk.uf2"
    else
        echo "❌ Build failed for $build_name"
        exit 1
    fi
}

# Build all variants
echo "🚀 Starting builds..."
echo ""

build_firmware "totem_left" "left"
build_firmware "totem_right" "right" 
build_firmware "settings_reset" "reset"

echo ""
echo "🎉 All builds completed successfully!"
echo ""
echo "📁 Built firmware files:"
ls -la output/*.uf2

echo ""
echo "📦 Creating firmware.zip archive..."
cd output
zip -r firmware.zip *.uf2
echo "🧹 Cleaning up individual UF2 files..."
rm -f *.uf2
cd ..
echo "✅ Created: output/firmware.zip"

echo ""
echo "📊 Final output:"
ls -la output/

echo ""
echo "💡 To flash firmware:"
echo "   1. Extract firmware.zip to get the UF2 files"
echo "   2. Connect keyboard half and double-tap reset"
echo "   3. Drag the appropriate .uf2 file to the mounted drive"
echo "   - Left side:  totem_left-${BOARD}-zmk.uf2"
echo "   - Right side: totem_right-${BOARD}-zmk.uf2" 
echo "   - Reset:      settings_reset-${BOARD}-zmk.uf2"
echo ""
echo "📦 All firmware files are in: output/firmware.zip"
