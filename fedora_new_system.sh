#!/bin/bash
# "Things To Do!" script for a fresh Fedora Workstation installation

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

# Set variables
ACTUAL_USER=$SUDO_USER
ACTUAL_HOME=$(eval echo ~$SUDO_USER)
LOG_FILE="/var/log/fedora_things_to_do.log"
INITIAL_DIR=$(pwd)
RUSER_UID=$(id -u ${ACTUAL_USER})

# Function to generate timestamps
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Function to log messages
log_message() {
    local message="$1"
    echo "$(get_timestamp) - $message" | tee -a "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    local exit_code=$?
    local message="$1"
    if [ $exit_code -ne 0 ]; then
        color_echo "red" "ERROR: $message"
        exit $exit_code
    fi
}

# Function to prompt for reboot
prompt_reboot() {
    sudo -u $ACTUAL_USER bash -c 'read -p "It is time to reboot the machine. Would you like to do it now? (y/n): " choice; [[ $choice == [yY] ]]'
    if [ $? -eq 0 ]; then
        color_echo "green" "Rebooting..."
        reboot
    else
        color_echo "red" "Reboot canceled."
    fi
}

# Function to backup configuration files
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.bak"
        handle_error "Failed to backup $file"
        color_echo "green" "Backed up $file"
    fi
}

echo "";
echo "╔═════════════════════════════════════════════════════════════════════════════╗";
echo "║                                                                             ║";
echo "║   ░█▀▀░█▀▀░█▀▄░█▀█░█▀▄░█▀█░░░█░█░█▀█░█▀▄░█░█░█▀▀░▀█▀░█▀█░▀█▀░▀█▀░█▀█░█▀█░   ║";
echo "║   ░█▀▀░█▀▀░█░█░█░█░█▀▄░█▀█░░░█▄█░█░█░█▀▄░█▀▄░▀▀█░░█░░█▀█░░█░░░█░░█░█░█░█░   ║";
echo "║   ░▀░░░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░░░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░░▀░░▀░▀░░▀░░▀▀▀░▀▀▀░▀░▀░   ║";
echo "║   ░░░░░░░░░░░░▀█▀░█░█░▀█▀░█▀█░█▀▀░█▀▀░░░▀█▀░█▀█░░░█▀▄░█▀█░█░░░░░░░░░░░░░░   ║";
echo "║   ░░░░░░░░░░░░░█░░█▀█░░█░░█░█░█░█░▀▀█░░░░█░░█░█░░░█░█░█░█░▀░░░░░░░░░░░░░░   ║";
echo "║   ░░░░░░░░░░░░░▀░░▀░▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░░░░▀░░▀▀▀░░░▀▀░░▀▀▀░▀░░░░░░░░░░░░░░   ║";
echo "║                                                                             ║";
echo "╚═════════════════════════════════════════════════════════════════════════════╝";
echo "";
echo "This script automates \"Things To Do!\" steps after a fresh Fedora Workstation installation"
echo "ver. 25.03"
echo ""
echo "Don't run this script if you didn't build it yourself or don't know what it does."
echo ""
read -p "Press Enter to continue or CTRL+C to cancel..."

# System Upgrade
color_echo "blue" "It's best to run dnf upgrade before running this script to ensure all packages are up to date."

# System Configuration
# Set the system hostname to uniquely identify the machine on the network
#ask the user for a hostname and set it
color_echo "yellow" "Please enter a new hostname for your system:"
read -r NEW_HOSTNAME
color_echo "yellow" "Setting hostname to {$NEW_HOSTNAME}..."
hostnamectl set-hostname $NEW_HOSTNAME

#Set UTC Time
#Used to counter time inconsistencies in dual boot systems
color_echo "yellow" "Setting time to UTC..."
sudo timedatectl set-local-rtc '0'

# check if running on a laptop
if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
    LAPTOP=true
fi

#check it running in a virtual machine
if [ -f /sys/class/dmi/id/product_name ]; then
    if grep -q "VirtualBox" /sys/class/dmi/id/product_name; then
        color_echo "blue" "Running in VirtualBox. Skipping hardware configuration."
        VM=true
    elif grep -q "VMware" /sys/class/dmi/id/product_name; then
        color_echo "blue" "Running in VMware. Skipping hardware configuration."
        VM=true
    elif grep -q "QEMU" /sys/class/dmi/id/product_name; then
        color_echo "blue" "Running in QEMU. Skipping hardware configuration."
        VM=true
    elif grep -q "KVM" /sys/class/dmi/id/product_name; then
        color_echo "blue" "Running in KVM. Skipping hardware configuration."
        VM=true
    elif grep -q "Hyper-V" /sys/class/dmi/id/product_name; then
        color_echo "blue" "Running in Hyper-V. Skipping hardware configuration."
        VM=true
    elif grep -q "Xen" /sys/class/dmi/id/product_name; then
        color_echo "blue" "Running in Xen. Skipping hardware configuration."
        VM=true
    elif grep -q "Standard PC (i440FX + PIIX, 1996)" /sys/class/dmi/id/product_name; then
        color_echo "blue" "Running in Proxmox. Skipping hardware configuration."
        VM=true
    elif grep -q "Q35" /sys/class/dmi/id/product_name; then
        color_echo "blue" "Running in QEMU Q35. Skipping hardware configuration."
        VM=true
    elif grep -q "Virtio" /sys/class/dmi/id/product_name; then
        color_echo "blue" "Running in Virtio. Skipping hardware configuration."
        VM=true
    elif grep -q "Parallels" /sys/class/dmi/id/product_name; then
        color_echo "blue" "Running in Parallels. Skipping hardware configuration."
        VM=true
    else
        color_echo "green" "Running on physical hardware. Will configure hardware."
        VM=false
    fi
else
    color_echo "red" "Unable to determine if running in a VM. Skipping hardware configuration."
    VM=true
fi
#disable mitigation for CPUs
if [ "$VM" = false ]; then
    color_echo "yellow" "Disabling CPU mitigations..."
    grubby --update-kernel=ALL --args="mitigations=off"
else
    color_echo "blue" "Running in a VM. Skipping CPU mitigations."
fi

#Disable NetworkManager-wait-online.service
#Disabling it can decrease the boot time by at least ~15s-20s:
color_echo "yellow" "Disable NetworkManager-wait-online.service..."
systemctl disable NetworkManager-wait-online.service

#disable Gnome Software startup service
color_echo "yellow" "Disable Gnome Software autostart..."
rm /etc/xdg/autostart/org.gnome.Software.desktop

# Optimize DNF package manager for faster downloads and efficient updates
color_echo "yellow" "Configuring DNF Package Manager..."
backup_file "/etc/dnf/dnf.conf"
echo "max_parallel_downloads=10" | tee -a /etc/dnf/dnf.conf > /dev/null
echo "fastestmirror=True" | tee -a /etc/dnf/dnf.conf > /dev/null
dnf -y install dnf-plugins-core

# Enable RPM Fusion repositories to access additional software packages and codecs
color_echo "yellow" "Enabling RPM Fusion repositories..."
dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf group update core -y

# Install multimedia codecs to enhance multimedia capabilities
color_echo "yellow" "Installing multimedia codecs..."
dnf swap ffmpeg-free ffmpeg --allowerasing -y
dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf update @sound-and-video -y

#is this an AMD GPU system?
if lspci | grep -i "vga" | grep -i "Radeon" >/dev/null; then
    # Install Hardware Accelerated Codecs for AMD GPUs. This improves video playback and encoding performance on systems with AMD graphics.
    color_echo "yellow" "Installing AMD Hardware Accelerated Codecs..."
    dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
    dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y
    dnf swap mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686 -y
    dnf swap mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686 -y
else
    color_echo "blue" "No AMD GPU detected. Skipping AMD GPU driver installation."
fi

dnf install -y ffmpeg-libs libva libva-utils

# Install virtualization tools to enable virtual machines and containerization
if [ "$VM" = false ]; then
    color_echo "yellow" "Installing virtualization tools..."
    dnf install -y @virtualization
else
    color_echo "blue" "Running in a VM. Skipping virtualization tools installation."
fi

# is it a laptop?
if [ "$LAPTOP" = true ]; then
    # Enable battery percentage in the top bar
    gsettings set org.gnome.desktop.interface show-battery-percentage true
fi


# App Installation
# Install essential applications
color_echo "yellow" "Installing essential applications..."
dnf install -y btop htop rsync tilix fastfetch unzip unrar git wget curl gnome-tweaks timeshift gparted gnome-builder ImageMagick evolution dconf-editor adw-gtk3-theme
dnf install -y remmina remmina-plugins-rdp remmina-plugins-vnc remmina-plugins-spice remmina-plugins-nx remmina-plugins-exec

color_echo "green" "Essential applications installed successfully."

# Change Gnome settings
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.nautilus.preferences show-create-link true
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.nautilus.preferences show-delete-permanently true
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.nautilus.preferences show-hidden-files true
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.settings-daemon.plugins.power idle-dim true
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive'
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 1800
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1200
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.shell.weather automatic-location true
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.interface accent-color 'teal'
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.interface clock-show-date true
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.interface clock-format '12h'
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.interface enable-animations true
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.screensaver lock-delay 30
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.mutter attach-modal-dialogs true
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.shell development-tools true
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.interface clock-format '24h'
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.interface clock-show-date true
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.interface clock-show-seconds false
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.interface clock-show-weekday false

#install development tools
color_echo "yellow" "Installing development tools..."
dnf group install "Development Tools" "Development Libraries"
color_echo "green" "Development tools installed successfully."

# Install and enable SSH - already part of the Fedora 42 installation
# color_echo "yellow" "Installing and enabling SSH server..."
# dnf install -y openssh-server
# systemctl enable --now sshd
# systemctl start sshd
# color_echo "green" "SSH server installed and enabled successfully."

# Install Internet & Communication applications
color_echo "yellow" "Installing Google Chrome..."
if command -v dnf4 &>/dev/null; then
  dnf4 config-manager --set-enabled google-chrome
else
  dnf config-manager setopt google-chrome.enabled=1
fi
dnf install -y google-chrome-stable
color_echo "green" "Google Chrome installed successfully."

# Install Coding and DevOps applications
color_echo "yellow" "Installing Visual Studio Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf check-update
dnf install -y code
color_echo "green" "Visual Studio Code installed successfully."

# Install Media & Graphics applications
color_echo "yellow" "Installing VLC..."
dnf install -y vlc
color_echo "green" "VLC installed successfully."
color_echo "yellow" "Installing Krita..."
dnf install -y krita
color_echo "green" "Krita installed successfully."
color_echo "yellow" "Installing Blender..."
dnf install -y blender
color_echo "green" "Blender installed successfully."

#install others
color_echo "yellow" "Installing Openscad..."
dnf install -y openscad
color_echo "green" "Openscad installed successfully."
if [ "$VM" = false ]; then
    color_echo "yellow" "Installing virt-manager..."
    dnf install -y virt-manager
    color_echo "green" "virt-manager installed successfully."
fi

#install flatpaks
color_echo "yellow" "Installing flatpaks..."
FLATPAKS="
org.onlyoffice.desktopeditors
net.cozic.joplin_desktop
io.github.shiftey.Desktop
org.gimp.GIMP
org.inkscape.Inkscape
org.kde.kdenlive
fr.handbrake.ghb
org.audacityteam.Audacity
org.libretro.RetroArch
org.DolphinEmu.dolphin-emu
org.duckstation.DuckStation
org.ppsspp.PPSSPP
net.pcsx2.PCSX2
ca.parallel_launcher.ParallelLauncher
io.missioncenter.MissionCenter
com.github.tchx84.Flatseal
com.mattjakeman.ExtensionManager
io.github.flattool.Warehouse
br.com.wiselabs.simplexity
io.github.shiftey.Desktop
org.gimp.GIMP
org.inkscape.Inkscape
org.kde.kdenlive
org.bunkus.mkvtoolnix-gui
fr.handbrake.ghb
org.audacityteam.Audacity
dev.zed.Zed
net.sf.VICE
com.thincast.client
com.ugetdm.uGet
com.surfshark.Surfshark
com.sublimetext.three
com.rawtherapee.RawTherapee
org.freecad.FreeCAD
org.gnucash.GnuCash
org.flatpak.Builder
net.epson.epsonscan2
net.fasterland.converseen
de.leopoldluley.Clapgrep
org.avidemux.Avidemux
com.jeffser.Alpaca
com.neoutils.NeoRegex
com.jetbrains.PyCharm-Community
cc.arduino.IDE2
com.kolor.AutopanoPro
com.github.iwalton3.jellyfin-media-player
org.gnome.meld
com.getpostman.Postman
com.ugetdm.uGet
com.ktechpit.ultimate-media-downloader
com.github.IsmaelMartinez.teams_for_linux
"
for FLATPAK in $FLATPAKS; do
    if flatpak list --app | grep -q "$FLATPAK"; then
        color_echo "blue" "Flatpak $FLATPAK is already installed. Skipping."
    else
        color_echo "yellow" "Installing Flatpak: $FLATPAK..."
        flatpak install -y flathub "$FLATPAK"
        color_echo "green" "$FLATPAK installed successfully."
    fi
done

# Customization
# Install Microsoft Windows fonts (core)
color_echo "yellow" "Installing Microsoft Fonts (core)..."
dnf install -y curl cabextract xorg-x11-font-utils fontconfig
rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
color_echo "green" "Microsoft Fonts (core) installed successfully."

# Install Google fonts collection
color_echo "yellow" "Installing Google Fonts..."
wget -O /tmp/google-fonts.zip https://github.com/google/fonts/archive/main.zip
mkdir -p $ACTUAL_HOME/.local/share/fonts/google
unzip /tmp/google-fonts.zip -d $ACTUAL_HOME/.local/share/fonts/google
rm -f /tmp/google-fonts.zip
sudo -u ${ACTUAL_USER} fc-cache -fv
color_echo "green" "Google Fonts installed successfully."

# Install Adobe fonts collection
color_echo "yellow" "Installing Adobe Fonts..."
mkdir -p $ACTUAL_HOME/.local/share/fonts/adobe-fonts
git clone --depth 1 https://github.com/adobe-fonts/source-sans.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-sans
git clone --depth 1 https://github.com/adobe-fonts/source-serif.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-serif
git clone --depth 1 https://github.com/adobe-fonts/source-code-pro.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-code-pro
sudo -u ${ACTUAL_USER} fc-cache -f
color_echo "green" "Adobe Fonts installed successfully."

#check if this is a laptop and install laptop-specific tools
if [ "$LAPTOP" = true ]; then
    # Install laptop-specific tools
    color_echo "yellow" "Detected a laptop. Installing laptop-specific tools..."

    # install auto-cpufreq
    AUTO_CPUFREQ_PATH="$ACTUAL_HOME/.local/share/auto-cpufreq"
    if ! command_exists auto-cpufreq; then
        mkdir -p "$ACTUAL_HOME/.local/share"
        if [ -d "$AUTO_CPUFREQ_PATH" ]; then
            rm -rf "$AUTO_CPUFREQ_PATH"
        fi
        color_echo "yellow" "Cloning auto-cpufreq repository."
        git clone --depth=1 https://github.com/AdnanHodzic/auto-cpufreq.git "$AUTO_CPUFREQ_PATH"
        chown -R "$ACTUAL_USER:$ACTUAL_USER" "$AUTO_CPUFREQ_PATH"
        chmod -R 755 "$AUTO_CPUFREQ_PATH"
        cd "$AUTO_CPUFREQ_PATH"
        color_echo "yellow" "Running auto-cpufreq installer."
        ./auto-cpufreq-installer
        auto-cpufreq --install
        color_echo "green" "Laptop-specific tools installed successfully."
    else
        color_echo "green" "auto-cpufreq is already installed."
    fi
else
    color_echo "blue" "This is not a laptop. Skipping laptop-specific tools."
fi

# Install GNOME Shell extensions
color_echo "yellow" "Installing Gnome Extensions."
mkdir -p "$ACTUAL_HOME/.local/share/gnome-shell/extensions"
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.local/share/gnome-shell/extensions"
chmod -R 755 "$ACTUAL_HOME/.local/share/gnome-shell/extensions"
install_gnome_extension() {
    EXT="https://extensions.gnome.org/extension-data/$1"
    color_echo "yellow" "Downloading $EXT..."
    wget -O /tmp/extension.zip $EXT
    uuid=$(unzip -c /tmp/extension.zip metadata.json | grep uuid | cut -d \" -f4)
    unzip /tmp/extension.zip -d "$ACTUAL_HOME/.local/share/gnome-shell/extensions/$uuid"
    # check is a compiled schema exists. Compile it with glib-compile-schemas ./schemas if not
    if [ ! -e "$ACTUAL_HOME/.local/share/gnome-shell/extensions/$uuid/schemas/gschemas.compiled" ]; then
        color_echo "yellow" "Compiling schemas for $uuid..."
        glib-compile-schemas "$ACTUAL_HOME/.local/share/gnome-shell/extensions/$uuid/schemas"
    fi
    cp "$ACTUAL_HOME/.local/share/gnome-shell/extensions/$uuid/schemas/org.gnome.shell.extensions.$uuid.gschema.xml" \
    /usr/share/glib-2.0/schemas/
    # all would be ownwed by root. Change ownership and permissions
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.local/share/gnome-shell/extensions/$uuid"
    chmod -R 755 "$ACTUAL_HOME/.local/share/gnome-shell/extensions/$uuid"
    # color_echo "YELLOW" "Enabling $uuid..."
    # gnome-extensions enable "$uuid"
    rm -rf /tmp/extension.zip

}

EXTENSIONS="
dash2dock-liteicedman.github.com.v72.shell-extension.zip
burn-my-windowsschneegans.github.com.v45.shell-extension.zip
mediacontrolscliffniff.github.com.v38.shell-extension.zip
rounded-window-cornersfxgn.v12.shell-extension.zip
printerslinux-man.org.v29.shell-extension.zip
weatheroclockCleoMenezesJr.github.io.v16.shell-extension.zip
places-menugnome-shell-extensions.gcampax.github.com.v67.shell-extension.zip
notification-timeoutchlumskyvaclav.gmail.com.v13.shell-extension.zip
just-perfection-desktopjust-perfection.v34.shell-extension.zip
grand-theft-focuszalckos.github.com.v8.shell-extension.zip
blur-my-shellaunetx.v68.shell-extension.zip
monitorastraext.github.io.v47.shell-extension.zip
"

for EXT in $EXTENSIONS; do
    install_gnome_extension "$EXT"
    handle_error "Failed to install $EXT"
    color_echo "green" "$EXT installed successfully."
done
if [ "$LAPTOP" = true ]; then
    # Install laptop-specific GNOME extensions
    color_echo "yellow" "Installing laptop-specific GNOME extensions..."
    install_gnome_extension "Battery-Health-Chargingmaniacx.github.com.v74.shell-extension.zip"
    # wget -O /tmp/battery-health-charging.dconf https://raw.githubusercontent.com/jasonritchie06/myBashConfig/refs/heads/main/battery-health-settings.dconf
    # sudo -u "$ACTUAL_USER" dconf load -f / < /tmp/battery-health-charging.dconf
    # rm -rf /tmp/battery-health-charging.dconf
fi
if [ "$VM" = false ]; then
    install_gnome_extension "wifiqrcodeglerro.pm.me.v17.shell-extension.zip"
fi
# Compile schemas for the extensions
glib-compile-schemas /usr/share/glib-2.0/schemas/

# pull down settings for the extensions
sudo -u ${ACTUAL_USER} mkdir -p "$ACTUAL_HOME/.config/burn-my-windows"
sudo -u ${ACTUAL_USER} mkdir -p "$ACTUAL_HOME/.config/burn-my-windows/profiles"
sudo -u ${ACTUAL_USER} wget -O "$ACTUAL_HOME/.config/burn-my-windows/profiles/1750860737150827.conf" https://raw.githubusercontent.com/jasonritchie06/myBashConfig/refs/heads/main/1750860737150827.conf
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.config/burn-my-windows"
chmod -R 755 "$ACTUAL_HOME/.config/burn-my-windows"

color_echo "green" "All GNOME extensions installed successfully. They will show up after you log out and log back in."
color_echo "green" "Use the extensions app to enable them."

#install myBash dependencies
dnf install -y bash bash-completion tar bat tree fontconfig git fastfetch
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
    mkdir -p "$FONT_DIR"/"$FONT_NAME"
    mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
    sudo -u ${ACTUAL_USER} fc-cache -fv
    rm -rf "${TEMP_DIR}"
fi

# Install starship
color_echo  "yellow" "Installing font starship.."
dnf -y copr enable atim/starship
dnf -y install starship
color_echo "green" "starship installed successfully."

# Install zoxide
color_echo "yellow" "Installing zoxide..."
dnf -y install zoxide
color_echo "green" "zoxide installed successfully."

# Pull down my Bash configuration files
color_echo "yellow" "Pulling down my Bash configuration files..."
mv "$ACTUAL_HOME/.bashrc" "$ACTUAL_HOME/.bashrc.bak" 2>/dev/null
wget -O "$ACTUAL_HOME/.bashrc" https://raw.githubusercontent.com/jasonritchie06/myBashConfig/refs/heads/main/.bashrc
wget -O "$ACTUAL_HOME/.config/starship.toml" https://raw.githubusercontent.com/jasonritchie06/myBashConfig/refs/heads/main/starship.toml
chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.bashrc" "$ACTUAL_HOME/.config/starship.toml"
chmod 644 "$ACTUAL_HOME/.bashrc" "$ACTUAL_HOME/.config/starship.toml"
color_echo "green" "Bash configuration files pulled down successfully."

# set the favorite applications
# gsettings set org.gnome.shell favorite-apps \
# "['com.gexperts.Tilix.desktop', 'google-chrome.desktop', 'org.gnome.Nautilus.desktop', \
# 'org.gnome.Software.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Evolution.desktop', \
# 'org.gnome.Calculator.desktop', 'org.gnome.Settings.desktop', 'code.desktop', \
# 'org.gnome.SystemMonitor.desktop', 'appimagekit-joplin.desktop']"


# Set the default terminal to Tilix
sudo -u ${ACTUAL_USER} DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${RUSER_UID}/bus" gsettings set org.gnome.desktop.default-applications.terminal exec 'tilix'
#remove the default terminal
dnf remove -y ptyxis

# pull down my gnome settings script
color_echo "yellow" "Pulling down my Gnome settings script..."
wget -O "$ACTUAL_HOME/gnome_settings.sh" https://raw.githubusercontent.com/jasonritchie06/myBashConfig/refs/heads/main/gnome_settings.sh
chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/gnome_settings.sh"
chmod 755 "$ACTUAL_HOME/gnome_settings.sh"
color_echo "green" "Gnome settings script pulled down successfully."
color_echo "green" "Run this script as regular user after the reboot."

# Before finishing, ensure we're in a safe directory
cd /tmp || cd $ACTUAL_HOME || cd /

# Finish
echo "";
echo "╔═════════════════════════════════════════════════════════════════════════╗";
echo "║                                                                         ║";
echo "║   ░█░█░█▀▀░█░░░█▀▀░█▀█░█▄█░█▀▀░░░▀█▀░█▀█░░░█▀▀░█▀▀░█▀▄░█▀█░█▀▄░█▀█░█░   ║";
echo "║   ░█▄█░█▀▀░█░░░█░░░█░█░█░█░█▀▀░░░░█░░█░█░░░█▀▀░█▀▀░█░█░█░█░█▀▄░█▀█░▀░   ║";
echo "║   ░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░░░░▀░░▀▀▀░░░▀░░░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░▀░   ║";
echo "║                                                                         ║";
echo "╚═════════════════════════════════════════════════════════════════════════╝";
echo "";
color_echo "green" "All steps completed. Enjoy!"

# Prompt for reboot
prompt_reboot
