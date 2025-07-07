#!/bin/sh
# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# Funtion to echo colored text
color_echo() {
    local color="$1"
    local text="$2"
    case "$color" in
        "red")     echo -e "\033[0;31m$text\033[0m" ;;
        "green")   echo -e "\033[0;32m$text\033[0m" ;;
        "yellow")  echo -e "\033[1;33m$text\033[0m" ;;
        "blue")    echo -e "\033[0;34m$text\033[0m" ;;
        *)         echo "$text" ;;
    esac
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Determine package manager
PACKAGEMANAGER='nala apt dnf yum pacman zypper emerge xbps-install nix-env'
for pgm in $PACKAGEMANAGER; do
    if command_exists "$pgm"; then
        PACKAGER="$pgm"
        color_echo "green" "Using package manager: $PACKAGER"
        break
    fi
done

# Set variables
ACTUAL_USER=$SUDO_USER
ACTUAL_HOME=$(eval echo ~$SUDO_USER)
LOG_FILE="/var/log/fedora_things_to_do.log"
INITIAL_DIR=$(pwd)
RUSER_UID=$(id -u ${ACTUAL_USER})
DEPENDENCIES='bash bash-completion tar bat tree fontconfig git unzip unrar'
    if ! command_exists nvim; then
        DEPENDENCIES="${DEPENDENCIES} neovim"
    fi

    color_echo "yellow" "Installing dependencies..."
    case "$PACKAGER" in
        pacman)
            install_pacman_dependencies
            ;;
        nala)
            ${PACKAGER} install -y ${DEPENDENCIES}
            ;;
        emerge)
            ${PACKAGER} -v app-shells/bash app-shells/bash-completion app-arch/tar app-editors/neovim sys-apps/bat app-text/tree app-text/multitail app-misc/fastfetch app-misc/trash-cli
            ;;
        xbps-install)
            ${PACKAGER} -v ${DEPENDENCIES}
            ;;
        nix-env)
             ${PACKAGER} -iA nixos.bash nixos.bash-completion nixos.gnutar nixos.neovim nixos.bat nixos.tree nixos.multitail nixos.fastfetch nixos.pkgs.starship nixos.trash-cli
            ;;
        dnf)
            ${PACKAGER} install -y ${DEPENDENCIES}
            ;;
        zypper)
            ${PACKAGER} install -n ${DEPENDENCIES}
            ;;
        *)
            ${PACKAGER} install -yq ${DEPENDENCIES}
            ;;
    esac


#install myBash dependencies
#dnf install -y bash bash-completion tar bat tree fontconfig git fastfetch
FONT_NAME="MesloLGS Nerd Font Mono"
if fc-list :family | grep -iq "$FONT_NAME"; then
    color_echo "yellow" "$FONT_NAME is already installed. Skipping font installation."
else
    color_echo  "yellow" "Installing font $FONT_NAME..."
    # Change this URL to correspond with the correct font
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    FONT_DIR="$ACTUAL_HOME/.local/share/fonts"
    TEMP_DIR=$(mktemp -d)
    curl -sSLo "$TEMP_DIR"/"${FONT_NAME}".zip "$FONT_URL"
    unzip "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"
    sudo -u "$ACTUAL_USER" mkdir -p "$FONT_DIR"/"$FONT_NAME"
    mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
    sudo -u ${ACTUAL_USER} fc-cache -fv
    rm -rf "${TEMP_DIR}"
fi

# # Install starship
if ! command_exists starship; then
    if ! sudo -u "$ACTUAL_USER" curl -sS https://starship.rs/install.sh | sudo -u "$ACTUAL_USER" sh; then
        color_echo "red" "Something went wrong during starship install!"
        exit 1
    fi
else
    color_echo "blue" "Starship already installed"
fi
if ! command_exists fzf; then
    if [ -d "$ACTUAL_HOME/.fzf" ]; then
        color_echo "yellow" "FZF directory already exists. Skipping installation."
    else
        sudo -u "$ACTUAL_USER" git clone --depth 1 https://github.com/junegunn/fzf.git $ACTUAL_HOME/.fzf
        sudo -u "$ACTUAL_USER" $ACTUAL_HOME/.fzf/install
    fi
else
    color_echo "blue" "Fzf already installed\n"
fi
# # Install zoxide
if ! command_exists zoxide; then
    if ! sudo -u "$ACTUAL_USER" curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sudo -u "$ACTUAL_USER" sh; then
        color_echo "red" "Something went wrong during zoxide install!"
        exit 1
    fi
else
    color_echo "blue"  "Zoxide already installed\n"
fi

# Pull down my Bash configuration files
color_echo "yellow" "Pulling down my Bash configuration files..."
mv "$ACTUAL_HOME/.bashrc" "$ACTUAL_HOME/.bashrc.bak" 2>/dev/null
wget -O "$ACTUAL_HOME/.bashrc" https://raw.githubusercontent.com/jasonritchie06/myBashConfig/refs/heads/main/.bashrc
sudo -u "$ACTUAL_USER" mkdir -p "$ACTUAL_HOME/.config"
wget -O "$ACTUAL_HOME/.config/starship.toml" https://raw.githubusercontent.com/jasonritchie06/myBashConfig/refs/heads/main/starship.toml
chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.bashrc" "$ACTUAL_HOME/.config/starship.toml"
chmod 755 "$ACTUAL_HOME/.bashrc" "$ACTUAL_HOME/.config/starship.toml"
color_echo "green" "Bash configuration files pulled down successfully."