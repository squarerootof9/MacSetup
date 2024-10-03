#!/usr/bin/env bash
# setup.sh
# Script to set up macOS with preferred settings and applications
# Author: oneofthree
# Date: 2024-10-01

# This script is licensed under the MIT License.
# See the LICENSE file in the project root for license information.

set -euo pipefail

# Log output to a file
exec > >(tee -i setup.log)
exec 2>&1

OS_VERSION=$(sw_vers -productVersion)
echo "Running on macOS $OS_VERSION"

# Exit if run as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root. Please run as a regular user."
    exit 1
fi

trap 'echo "An error occurred. Please check the setup.log for details."; exit 1' ERR

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

configure_finder() {

    # Show all files in Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true

    # Show Path Bar in Finder
    defaults write com.apple.finder ShowPathbar -bool true

    # Show Status Bar in Finder
    defaults write com.apple.finder ShowStatusBar -bool true

    # Enable Tab View in Finder
    defaults write com.apple.finder ShowTabView -bool true

    # Set current folder as default search scope
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    # Avoid creating .DS_Store files on network or USB volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    # Disable the warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Prohibit ejecting of any volumes
    defaults write com.apple.finder ProhibitEject -bool true

    # Show hard drives on the desktop
    defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true

    # Show external hard drives on the desktop
    defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

    # Show removable media on the desktop
    defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

    # Show mounted servers on the desktop
    defaults write com.apple.finder ShowMountedServersOnDesktop -bool true

    # Disable the warning before emptying the Trash
    defaults write com.apple.finder WarnOnEmptyTrash -bool false

    # Set the default view style to list view ('Nlsv')
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    # Enable snap-to-grid for icons on the desktop and in other icon views
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

    # Disable all animations
    defaults write com.apple.finder DisableAllAnimations -bool true

    echo "Restarting Finder"
    killall Finder
    echo "Finder Restarted"

}

configure_system() {

    # Enable spring loading for directories
    defaults write NSGlobalDomain com.apple.springing.enabled -bool true

    # Shorten the spring loading delay
    defaults write NSGlobalDomain com.apple.springing.delay -float 0.5

    # Show the ~/Library folder
    chflags nohidden ~/Library

    # Collapse Save panel by default
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool false

    # Collapse Print panel by default
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool false

    # Set the sidebar icon size to small (1)
    defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1

    # Enable AirDrop over Ethernet and on unsupported Macs
    defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

    # Disable password requirement after sleep or screen saver
    defaults write com.apple.screensaver askForPassword -int 0

    # Disable screen saver activation (set idle time to 'Never')
    defaults -currentHost write com.apple.screensaver idleTime 0

    # Disable auto-logout
    defaults write com.apple.autologout.AutoLogOutDelay -int 0

    # Set mouse tracking speed
    defaults write -g com.apple.mouse.scaling -float 3

    # Set scroll wheel speed
    defaults write -g com.apple.scrollwheel.scaling -float 0.5

    # Disable natural scrolling
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

    # Minimize windows into application icon
    defaults write com.apple.dock minimize-to-application -bool true

    echo "Restarting SystemUIServer"
    killall SystemUIServer
    echo "SystemUIServer Restarted"

}

configure_dock() {

    # Install dockutil if not already installed
    if ! command -v dockutil &> /dev/null; then
        echo "dockutil not found, installing via Homebrew..."
        install_homebrew
        brew install dockutil
    fi

    # Remove all existing Dock items
    dockutil --remove all --no-restart

    # List of applications to add to the Dock
    apps=(
        "/System/Applications/Launchpad.app"
        "/System/Applications/System Settings.app"
        "/System/Applications/Utilities/Terminal.app"
        "/Applications/Geany.app"
        "/Applications/Firefox.app"
        "/Applications/VLC.app"
        "/System/Applications/Clock.app"
        "/System/Applications/Maps.app"
    )

    # Add each application to the Dock
    for app in "${apps[@]}"; do
        if [ -e "$app" ]; then
            dockutil --add "$app" --no-restart
        else
            echo "Application not found for dock addition: $app"
        fi
    done

    echo "Restarting Dock to apply changes"
    killall Dock
    echo "Dock Restarted"

}

install_homebrew() {
    # Install Homebrew if not already installed
    if ! command -v brew &>/dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Determine the Homebrew installation path
        if [ -d "/opt/homebrew/bin" ]; then
            BREW_PATH="/opt/homebrew/bin/brew"
        elif [ -d "/usr/local/bin" ]; then
            BREW_PATH="/usr/local/bin/brew"
        else
            echo "Homebrew installation not found."
            exit 1
        fi

        # Ensure .zprofile exists
        touch "$HOME/.zprofile"

        # Add Homebrew to the PATH in .zprofile
        if ! grep -q 'eval "\$('"$BREW_PATH"' shellenv)"' "$HOME/.zprofile"; then
            echo 'eval "$('"$BREW_PATH"' shellenv)"' >> "$HOME/.zprofile"
            echo "Homebrew environment variables have been added to $HOME/.zprofile."
            echo "Please run 'source $HOME/.zprofile' or open a new terminal session to apply the changes."
        fi

        # Evaluate Homebrew environment for the current script
        eval "$("$BREW_PATH" shellenv)"
    else
        echo "Homebrew is already installed."
        # Ensure brew shellenv is evaluated
        eval "$(brew shellenv)"
    fi

    # Update and upgrade Homebrew
    brew update && brew upgrade && brew cleanup

}


configure_java() {

    # Create symbolic link for Java
    echo "Creating symbolic link for Java..."
    sudo ln -sfn /usr/local/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk

    # Create or update .zprofile without sudo
    echo "Configuring JAVA_HOME in .zprofile for login shells."
    touch ~/.zprofile

    # Add a comment if it doesn't exist
    if ! grep -qxF "# Added by setup script" ~/.zprofile; then
        echo "# Added by setup script" >> ~/.zprofile
    fi

    # Add LC_ALL if it doesn't exist
    if ! grep -qxF 'export LC_ALL=en_US.UTF-8' ~/.zprofile; then
        echo 'export LC_ALL=en_US.UTF-8' >> ~/.zprofile
    fi

    # Add JAVA_HOME if it doesn't exist
    if ! grep -qxF 'export JAVA_HOME=$(/usr/libexec/java_home)' ~/.zprofile; then
        echo 'export JAVA_HOME=$(/usr/libexec/java_home)' >> ~/.zprofile
    fi

    # Source the updated .zprofile
    source ~/.zprofile

    # Create or update .zshrc without sudo
    echo "Configuring JAVA_HOME in .zshrc for interactive non-login shells."
    touch ~/.zshrc

    # Add a comment if it doesn't exist
    if ! grep -qxF "# Added by setup script" ~/.zshrc; then
        echo "# Added by setup script" >> ~/.zshrc
    fi

    # Add LC_ALL if it doesn't exist
    if ! grep -qxF 'export LC_ALL=en_US.UTF-8' ~/.zshrc; then
        echo 'export LC_ALL=en_US.UTF-8' >> ~/.zshrc
    fi

    # Add JAVA_HOME if it doesn't exist
    if ! grep -qxF 'export JAVA_HOME=$(/usr/libexec/java_home)' ~/.zshrc; then
        echo 'export JAVA_HOME=$(/usr/libexec/java_home)' >> ~/.zshrc
    fi

    # Source the updated .zshrc
    source ~/.zshrc

    # Inform the user
    echo "Java environment variables have been configured in ~/.zprofile and ~/.zshrc."
    echo "Please run 'source ~/.zshrc' or restart your terminal session to apply the changes."

}

install_apps() {

    # Use Brewfile to install packages
    if [ -f "$SCRIPT_DIR/Brewfile" ]; then
        if ! brew bundle --file="$SCRIPT_DIR/Brewfile"; then
            echo "brew bundle encountered errors. Please check the output above."
        fi
    else
        echo "Brewfile not found in $SCRIPT_DIR."
        exit 1
    fi

    # Run pod setup for CocoaPods
    echo "Setting up CocoaPods..."
    pod setup

    }

install_custom() {

    # Download and install the latest version of OrcaSlicer
    echo "Downloading the latest version of OrcaSlicer..."
    latest_url=$(curl -s https://api.github.com/repos/SoftFever/OrcaSlicer/releases/latest | jq -r '.assets[] | select(.name | contains("Mac_x86_64")) | .browser_download_url')

    wget "$latest_url" -O OrcaSlicer.dmg --progress=bar:force
    hdiutil attach OrcaSlicer.dmg
    cp -R /Volumes/OrcaSlicer/OrcaSlicer.app /Applications/
    hdiutil detach /Volumes/OrcaSlicer
    rm OrcaSlicer.dmg

}

# Install Homebrew and applications

install_homebrew
install_apps

echo "Installed applications:"
echo "Homebrew packages from Brewfile"
echo ""

# Run configuration functions

echo "Configuring..."
configure_java
echo "Java configuration finished."
configure_finder
echo "Finder configuration finished."
configure_system
echo "System configuration finished."
configure_dock
echo "Dock configuration finished."
echo ""

# Restart affected applications

echo "Setup complete. Please restart your computer to apply all changes."
