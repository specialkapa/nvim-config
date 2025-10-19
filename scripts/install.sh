#!/usr/bin/env bash

#------------------------------------------------------------------------------
# Displays an error message in bold red text with an icon.
# Globals:
#   None
# Arguments:
#   message - The error message to display.
# Outputs:
#   Writes the formatted error message to stderr.
#------------------------------------------------------------------------------
show_error() {
    echo -e "\033[91;1m $1\033[0m" >&2
}

#------------------------------------------------------------------------------
# Displays a success message in bold green text with a checkmark.
# Globals:
#   None
# Arguments:
#   message - The success message to display.
# Outputs:
#   Writes the formatted success message to stderr.
#------------------------------------------------------------------------------
show_success() {
    echo -e "\033[92;1m✔ $1\033[0m" >&2
}

#------------------------------------------------------------------------------
# Displays a warning message in yellow text with an icon.
# Globals:
#   None
# Arguments:
#   message - The warning message to display.
# Outputs:
#   Writes the formatted warning message to stderr.
#------------------------------------------------------------------------------
show_warning() {
    echo -e "\033[0;33m $1\033[0m">&2
}

#------------------------------------------------------------------------------
# Installs a package using apt-get and attempts a fallback method on failure.
# Globals:
#   None
# Arguments:
#   package - The name of the package to install.
# Outputs:
#   Installs the package or reports errors encountered during installation.
#------------------------------------------------------------------------------
install_with_apt() {
    local package=$1

    sudo apt-get update
    sudo apt-get install -y "$package"

    if [ $? -ne 0 ]; then
        show_warning "Primary apt-get install failed for $package. Trying fallback method..."
        sudo apt-get update && \
        sudo apt-get install -y lsb-release && \
        sudo apt-get clean all && \
        sudo apt-get install -y "$package"
    fi
}

#------------------------------------------------------------------------------
# Installs a package using pacman with non-interactive flags.
# Globals:
#   None
# Arguments:
#   package - The name of the package to install.
# Outputs:
#   Installs the package or reports errors encountered during installation.
#------------------------------------------------------------------------------
install_with_pacman() {
    local package=$1

    sudo pacman -Sy --noconfirm "$package"
}

#------------------------------------------------------------------------------
# Ensures a Homebrew package is installed, installing it if missing.
# Globals:
#   None
# Arguments:
#   package - The name of the package to install.
# Outputs:
#   Installs the package or reports that it is already installed.
#------------------------------------------------------------------------------
install_with_brew() {
    local package=$1

    if brew list --formula "$package" > /dev/null 2>&1 || \
       brew list --cask "$package" > /dev/null 2>&1; then
        echo "$package is already installed with Homebrew."
        return 0
    fi

    if brew info --formula "$package" > /dev/null 2>&1; then
        brew install "$package"
    elif brew info --cask "$package" > /dev/null 2>&1; then
        brew install --cask "$package"
    else
        show_error "$package is not available in Homebrew repositories."
        return 1
    fi
}

#------------------------------------------------------------------------------
# Ensures a Cargo package is installed, installing it if necessary.
# Globals:
#   None
# Arguments:
#   package - The name of the Cargo package to install.
# Outputs:
#   Installs the package or reports relevant status/errors.
#------------------------------------------------------------------------------
install_cargo_package() {
    local package=$1

    if ! command -v cargo > /dev/null 2>&1; then
        show_error "cargo is not available. Install Rust and Cargo first."
        return 1
    fi

    if cargo install --list 2>/dev/null | grep -q "^$package v"; then
        show_warning "$package is already installed with Cargo."
        return 0
    fi

    if cargo install "$package"; then
        show_success "Cargo package $package installation complete."
    else
        show_error "Failed to install Cargo package $package."
        return 1
    fi
}

#------------------------------------------------------------------------------
# Detects the available package manager and delegates to the appropriate
# install strategy (apt-get, pacman, or Homebrew).
# Globals:
#   None
# Arguments:
#   package - The name of the package to install.
# Outputs:
#   Installs the package using the detected package manager.
#------------------------------------------------------------------------------
install_package_strategy() {
    local package=$1

    if command -v apt-get > /dev/null 2>&1; then
        install_with_apt "$package"
    elif command -v pacman > /dev/null 2>&1; then
        install_with_pacman "$package"
    elif command -v brew > /dev/null 2>&1; then
        install_with_brew "$package"
    else
        show_error "Unsupported package manager. None of apt-get, pacman, or brew found."
        return 1
    fi
}

#------------------------------------------------------------------------------
# Installs a package using the detected package manager if it is not already
# installed.
# Globals:
#   None
# Arguments:
#   package - The name of the package to install.
# Outputs:
#   Installs the package if not already installed.
#------------------------------------------------------------------------------
install_if_not_exists() {
    local package=$1
    local binary=${2:-$package}

    command_exists() {
        command -v "$1" > /dev/null 2>&1
    }

    if ! command_exists "$binary"; then
        echo "$package is not installed. Installing now."
        if install_package_strategy "$package"; then
            message="$package installation complete!"
            if command_exists show_success; then
                show_success "$message"
            else
                echo "$message"
            fi
        else
            show_error "Failed to install $package."
        fi
    else
        show_warning "$package is already installed."
    fi
}

cd $HOME

if command -v nvim > /dev/null 2>&1; then
    read -r -p "Neovim is already installed. Wipe existing configuration and reinstall? [y/N]: " wipe_choice
    if [[ "$wipe_choice" =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/.config/nvim"
        rm -rf "$HOME/.local/share/nvim"
        rm -rf "$HOME/.local/state/nvim"
        rm -rf "$HOME/.cache/nvim"
    fi
fi
if curl -LsSf https://astral.sh/uv/install.sh | sh; then
    show_success "uv installation complete."
else
    show_error "uv installation failed."
fi

if curl https://sh.rustup.rs -sSf | sh -s -- -y; then
    show_success "cargo/rust installation complete."
else
    show_error "cargo/rust installation failed."
fi

if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash; then
    show_success "nvm installation complete."
else
    show_error "nvm installation failed."
fi

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1090
    . "$NVM_DIR/nvm.sh"
fi

if command -v nvm > /dev/null 2>&1 && nvm install node; then
    show_success "node installation via nvm complete."
else
    show_error "node installation via nvm failed."
fi

if ! command -v brew > /dev/null 2>&1; then
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        show_success "homebrew installation complete."
    else
        show_error "homebrew installation failed."
    fi
fi

install_cargo_package grip-grab
install_if_not_exists ripgrep rg
install_if_not_exists fzf
install_if_not_exists fd
install_if_not_exists eza
install_if_not_exists neovim nvim

if [ ! -d "$HOME/.config" ]; then
  mkdir $HOME/.config 
fi

cd $HOME/.config
git clone git@github.com:specialkapa/nvim-config.git nvim
