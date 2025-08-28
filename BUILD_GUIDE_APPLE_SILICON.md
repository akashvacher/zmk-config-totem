# Building Totem Keyboard Firmware on Apple Silicon Mac

This guide will walk you through building the Totem keyboard firmware locally on an Apple Silicon Mac (M1, M2, M3, M4, etc.) from scratch.

## ⚡ Quickstart (Recommended)

The build script will automatically install everything needed on first run.

```bash
./build_local.sh
```

If the environment is incomplete, this will run `setup_env.sh` to install Homebrew packages, initialize `west`, install Zephyr Python requirements, and download/configure the Zephyr SDK non-interactively. After setup, it will build the firmware.

## 🎯 What You'll Build

This will create firmware files for:
- **Left half**: `totem_left-seeeduino_xiao_ble-zmk.uf2`
- **Right half**: `totem_right-seeeduino_xiao_ble-zmk.uf2` 
- **Settings reset**: `settings_reset-seeeduino_xiao_ble-zmk.uf2`

## 📋 Prerequisites

### Required Tools

1. **Homebrew** (package manager for macOS)
2. **Git** (version control)
3. **Python 3.8+** (programming language)
4. **CMake** (build system)
5. **Ninja** (build tool)
6. **Zephyr SDK** (embedded development toolkit)
7. **West** (Zephyr's meta-tool)

## 🚀 Step-by-Step Installation

You can skip this section if you used the Quickstart above. These steps are provided for manual setup or troubleshooting.

### Step 1: Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Install Required Tools via Homebrew

```bash
# Install build tools
brew install cmake ninja git python3

# Install additional dependencies
brew install dtc wget
```

### Step 3: Install Zephyr SDK

```bash
# Create a directory for the SDK (you can choose any location)
cd ~/
mkdir -p code/fun
cd code/fun

# Download Zephyr SDK 0.16.8 (compatible with Apple Silicon)
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/zephyr-sdk-0.16.8_macos-aarch64.tar.xz

# Extract the SDK
tar xf zephyr-sdk-0.16.8_macos-aarch64.tar.xz

# Move to final location
mv zephyr-sdk-0.16.8 zephyr-sdk-0.16.8

# Run the setup script
cd zephyr-sdk-0.16.8
./setup.sh

# Add to your shell profile (choose your shell)
# For bash:
echo 'export ZEPHYR_SDK_INSTALL_DIR=$HOME/code/fun/zephyr-sdk-0.16.8' >> ~/.bash_profile
echo 'export ZEPHYR_TOOLCHAIN_VARIANT=zephyr' >> ~/.bash_profile

# For zsh (default on newer macOS):
echo 'export ZEPHYR_SDK_INSTALL_DIR=$HOME/code/fun/zephyr-sdk-0.16.8' >> ~/.zshrc
echo 'export ZEPHYR_TOOLCHAIN_VARIANT=zephyr' >> ~/.zshrc

# Reload your shell
source ~/.zshrc  # or ~/.bash_profile for bash
```

### Step 4: Clone This Repository

```bash
# Navigate to your desired directory
cd ~/code/fun  # or wherever you want to store the project

# Clone the repository
git clone https://github.com/your-username/zmk-config-totem.git
cd zmk-config-totem
```

### Step 5: Set Up Python Virtual Environment

```bash
# Create virtual environment
python3 -m venv zmk-env

# Activate the environment
source zmk-env/bin/activate

# Install Python dependencies
pip install west
```

### Step 6: Initialize the ZMK Workspace

```bash
# Initialize west workspace
west init -l config/

# Update and pull dependencies
west update
```

#### Install Zephyr Python requirements

```bash
# Required for Kconfig/DT generation and build tooling
pip install -r zephyr/scripts/requirements.txt
```

This will download:
- ZMK firmware source code
- Zephyr RTOS
- All required modules and dependencies

### Step 7: Build the Firmware

Make sure the build script is executable and run it:

```bash
# Make the build script executable
chmod +x build_local.sh

# Run the build
./build_local.sh
```

## 📁 Build Output

After successful build, you'll find:

```
output/
└── firmware.zip    # Contains all .uf2 files
```

Extract `firmware.zip` to get:
- `totem_left-seeeduino_xiao_ble-zmk.uf2`
- `totem_right-seeeduino_xiao_ble-zmk.uf2`
- `settings_reset-seeeduino_xiao_ble-zmk.uf2`

## 💾 Flashing the Firmware

### For Each Keyboard Half:

1. **Connect** the keyboard half to your Mac via USB-C
2. **Enter bootloader mode**: Double-tap the reset button on the XIAO
3. **Mount point**: A drive named "XIAO-SENSE" should appear
4. **Flash firmware**: 
   - Drag `totem_left-seeeduino_xiao_ble-zmk.uf2` to left half
   - Drag `totem_right-seeeduino_xiao_ble-zmk.uf2` to right half
5. **Done**: The keyboard will automatically restart and be ready to use

### To Reset Settings:
If you need to clear keyboard settings, flash `settings_reset-seeeduino_xiao_ble-zmk.uf2` to either half.

## 🔧 Modifying the Keymap

The keymap is defined in `config/totem.keymap`. After making changes:

1. Edit the keymap file
2. Run `./build_local.sh` to rebuild
3. Flash the new firmware to both halves

## 📜 Understanding the Build Script

The `build_local.sh` script automates the entire build process:

### What it does:
1. **Activates** the Python virtual environment
2. **Sets** environment variables for Zephyr SDK
3. **Builds** three firmware variants:
   - Left half firmware
   - Right half firmware  
   - Settings reset firmware
4. **Packages** everything into `output/firmware.zip`
5. **Cleans up** temporary files

### Key build parameters:
- **Board**: `seeeduino_xiao_ble` (Seeed Xiao BLE controller)
- **Shields**: `totem_left`, `totem_right`, `settings_reset`
- **Config Path**: Points to the `config/` directory with your keymap

### Build directories:
- `build/left/` - Left half build artifacts
- `build/right/` - Right half build artifacts  
- `build/reset/` - Settings reset build artifacts
- `output/` - Final firmware files

## 🛠 Troubleshooting

### Build Issues

**Error: "west: command not found"**
```bash
# Ensure virtual environment is activated
source zmk-env/bin/activate
# Re-install west if needed
pip install west
```

**Error: "Zephyr SDK not found"**
```bash
# Check environment variables are set
echo $ZEPHYR_SDK_INSTALL_DIR
echo $ZEPHYR_TOOLCHAIN_VARIANT

# If empty, add to shell profile and reload
```

**Error: "Permission denied" on build script**
```bash
chmod +x build_local.sh
```

### SDK Download Issues

If the SDK download fails or is slow, try:
```bash
# Use curl instead of wget
curl -L -o zephyr-sdk-0.16.8_macos-aarch64.tar.xz \
  https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/zephyr-sdk-0.16.8_macos-aarch64.tar.xz
```

### Build Dependencies Issues

If you get cmake or ninja errors:
```bash
# Update Homebrew and reinstall
brew update
brew reinstall cmake ninja
```

### Path Issues

If you chose a different SDK installation path, update the build script:
```bash
# Edit build_local.sh and change this line:
export ZEPHYR_SDK_INSTALL_DIR=/your/custom/path/to/zephyr-sdk-0.16.8
```

## 📝 Notes

- **First build** takes 10-15 minutes as it compiles all dependencies
- **Subsequent builds** are much faster (1-2 minutes)
- **Apple Silicon** is fully supported with this setup
- **Build artifacts** are stored in `build/` directory
- **Output files** are cleaned and recreated on each build

## 🎉 Success!

You now have a complete local build environment for the Totem keyboard firmware on your Apple Silicon Mac. You can customize your keymap and build firmware without relying on GitHub Actions.

## 📚 Additional Resources

- [ZMK Documentation](https://zmk.dev/)
- [Totem Hardware Files](https://github.com/GEIGEIGEIST/totem)
- [ZMK Keycodes Reference](https://zmk.dev/docs/codes/)
- [ZMK Behaviors](https://zmk.dev/docs/behaviors/)
