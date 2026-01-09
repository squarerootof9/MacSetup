#!/usr/bin/env bash
# setup.sh
# Script to set up macOS with preferred settings and applications
# Author: oneofthree
# Date: 2024-10-01

# This script is licensed under the MIT License.
# See the LICENSE file in the project root for license information.

set -euo pipefail

# Log output to a file
# exec > >(tee -i setup.log)
# exec 2>&1

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

pause() {
	read -n1 -rsp $'Press any key to continue...\n'
}

setup_finder() {

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

setup_system() {

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

setup_dock() {

	# Install dockutil if not already installed
	if ! command -v dockutil &>/dev/null; then
		echo "dockutil not found, installing via Homebrew..."
		install_formulae dockutil
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
			echo 'eval "$('"$BREW_PATH"' shellenv)"' >>"$HOME/.zprofile"
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

install_cask() {
	local cask="${1:-}"

	if [[ -z "$cask" ]]; then
		echo "✗ install_cask: missing cask name"
		return 1
	fi

	if ! command -v brew >/dev/null 2>&1; then
		install_homebrew
	fi

	echo "➜ Installing (${cask})"

	if brew list --cask "$cask" >/dev/null 2>&1; then
		echo "✓ Already installed (${cask})."
		return 0
	fi

	if ! brew install --cask --force "$cask"; then
		echo "✗ Failed to install (${cask})"
		return 1
	fi
}

install_formulae() {

	local formulae="${1:-}"

	if [[ -z "$formulae" ]]; then
		echo "✗ install_formulae: missing formulae name"
		return 1
	fi

	if ! command -v brew >/dev/null 2>&1; then
		install_homebrew
	fi

	echo "➜ Installing (${formulae})"

	if brew list "$formulae" >/dev/null 2>&1; then
		echo "✓ Already installed (${formulae})."
		return 0
	fi

	if ! brew install --force "$formulae"; then
		echo "✗ Failed to install (${formulae})"
		return 1
	fi
}

install_java() {

	echo "Installing Java..."

	brew install openjdk # This installs Java
	brew install cocoapods

	echo "Configuring Java..."

	# Create symbolic link for Java
	echo "Creating symbolic link for Java..."
	sudo ln -sfn /usr/local/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk

	# Create or update .zprofile without sudo
	echo "Configuring JAVA_HOME in .zprofile for login shells."
	touch ~/.zprofile

	# Add a comment if it doesn't exist
	if ! grep -qxF "# Added by setup script" ~/.zprofile; then
		echo "# Added by setup script" >>~/.zprofile
	fi

	# Add LC_ALL if it doesn't exist
	if ! grep -qxF 'export LC_ALL=en_US.UTF-8' ~/.zprofile; then
		echo 'export LC_ALL=en_US.UTF-8' >>~/.zprofile
	fi

	# Add JAVA_HOME if it doesn't exist
	if ! grep -qxF 'export JAVA_HOME=$(/usr/libexec/java_home)' ~/.zprofile; then
		echo 'export JAVA_HOME=$(/usr/libexec/java_home)' >>~/.zprofile
	fi

	# Source the updated .zprofile
	source ~/.zprofile

	# Create or update .zshrc without sudo
	echo "Configuring JAVA_HOME in .zshrc for interactive non-login shells."
	touch ~/.zshrc

	# Add a comment if it doesn't exist
	if ! grep -qxF "# Added by setup script" ~/.zshrc; then
		echo "# Added by setup script" >>~/.zshrc
	fi

	# Add LC_ALL if it doesn't exist
	if ! grep -qxF 'export LC_ALL=en_US.UTF-8' ~/.zshrc; then
		echo 'export LC_ALL=en_US.UTF-8' >>~/.zshrc
	fi

	# Add JAVA_HOME if it doesn't exist
	if ! grep -qxF 'export JAVA_HOME=$(/usr/libexec/java_home)' ~/.zshrc; then
		echo 'export JAVA_HOME=$(/usr/libexec/java_home)' >>~/.zshrc
	fi

	# Source the updated .zshrc
	source ~/.zshrc

	# Inform the user
	echo "Java environment variables have been configured in ~/.zprofile and ~/.zshrc."
	echo "Please run 'source ~/.zshrc' or restart your terminal session to apply the changes."

	echo ""
	echo "Java configuration finished."
	echo ""

	# Run pod setup for CocoaPods
	echo "Setting up CocoaPods..."
	pod setup

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

################################################################################
######                          Node.JS
################################################################################

install_nodejs() {

	local options="${1:-}"

	#🌐 Networking & Downloads
	#sudo apt install -y --no-install-recommends curl

	##########
	# Node.js
	##########
	#https://www.jemrf.com/pages/how-to-install-nvm-and-node-js-on-raspberry-pi
	echo "Installing Node.js..."
	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
	command -v nvm
	nvm install stable
	npm install -g npm@11.2.0
	node -v

	# Reinstall TileServer GL from source
	# git clone https://github.com/maptiler/tileserver-gl.git
	# cd tileserver-gl/
	# nvm install 18
	# nvm use 18

	# echo "18" > .nvmrc
	# nvm use

	# npm install

	#npm install -g --build-from-source tileserver-gl
	#sudo ln -s /usr/lib/aarch64-linux-gnu/libjpeg.so.62 /usr/lib/aarch64-linux-gnu/libjpeg.so.8
	#sudo apt install -y libvips libvips-dev build-essential

	#sudo apt install -y --no-install-recommends nodejs
	echo "Installation of Node.js complete..."
}

install_powershell() {

	if command -v pwsh >/dev/null 2>&1; then
		echo "Powershell already installed."
		return 0
	fi

	cd ~/Downloads

	ARCH="$(uname -m)"
	if [ "$ARCH" = "arm64" ]; then
		PKG="powershell-7.5.4-osx-arm64.pkg"
	else
		PKG="powershell-7.5.4-osx-x64.pkg"
	fi

	curl -L -o "$PKG" "https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/$PKG"

	sudo installer -pkg "$PKG" -target /

	cd ${SCRIPT_DIR}

}

enable_pf() {

	IF_OVERRIDE="${1:-}"
	if [[ "$IF_OVERRIDE" == "--if" ]]; then
		IFACE="$2"
	else
		IFACE="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
	fi

	if [[ -z "${IFACE:-}" ]]; then
		echo "Could not determine network interface. Run as: $0 --if en0"
		exit 1
	fi

	# --- ask user which services to allow ---
	read -rp "Allow SSH access (port 22)? [y/N]: " ALLOW_SSH
	read -rp "Allow mDNS service discovery (port 5353/udp)? [y/N]: " ALLOW_MDNS
	read -rp "Allow ping (ICMP echo)? [y/N]: " ALLOW_PING

	ANCHOR_NAME="sscom"
	ANCHOR_FILE="/etc/pf.anchors/${ANCHOR_NAME}"
	PF_CONF="/etc/pf.conf"

	echo "Using interface: ${IFACE}"
	echo "Writing PF anchor: ${ANCHOR_FILE}"

	sudo bash -c "cat > '${ANCHOR_FILE}'" <<EOF
# ===== ${ANCHOR_NAME} (generated) =====
set block-policy drop
set skip on lo0
block in all
pass out all keep state

# ---- IPv4 rules on ${IFACE} ----
EOF

	# Conditionally add rules
	if [[ "$ALLOW_SSH" =~ ^[Yy]$ ]]; then
		echo "# SSH 22/tcp" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
		echo "pass in on ${IFACE} inet proto tcp to (${IFACE}) port 22 keep state" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
	fi

	if [[ "$ALLOW_MDNS" =~ ^[Yy]$ ]]; then
		echo "# mDNS 5353/udp" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
		#echo "pass in on ${IFACE} inet proto udp to (${IFACE}) port 5353 keep state" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
		# Allow mDNS (Bonjour/Avahi)
		echo "pass in  quick on ${IFACE} inet  proto udp from any to 224.0.0.251 port 5353 keep state" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
		echo "pass out quick on ${IFACE} inet  proto udp from any to 224.0.0.251 port 5353 keep state" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
	fi

	if [[ "$ALLOW_PING" =~ ^[Yy]$ ]]; then
		echo "# ICMP echo-request (ping)" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
		echo "pass in on ${IFACE} inet proto icmp icmp-type echoreq keep state" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
	fi

	# IPv6 mirrors
	sudo bash -c "cat >> '${ANCHOR_FILE}'" <<EOF
# ---- IPv6 rules on ${IFACE} ----
EOF

	if [[ "$ALLOW_SSH" =~ ^[Yy]$ ]]; then
		echo "pass in on ${IFACE} inet6 proto tcp to (${IFACE}) port 22 keep state" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
	fi

	if [[ "$ALLOW_MDNS" =~ ^[Yy]$ ]]; then
		#echo "pass in on ${IFACE} inet6 proto udp to (${IFACE}) port 5353 keep state" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
		# For IPv6 mDNS (optional)
		echo "pass in  quick on ${IFACE} inet6 proto udp from any to ff02::fb port 5353 keep state" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
		echo "pass out quick on ${IFACE} inet6 proto udp from any to ff02::fb port 5353 keep state" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
	fi

	if [[ "$ALLOW_PING" =~ ^[Yy]$ ]]; then
		echo "pass in on ${IFACE} inet6 proto icmp6 icmp6-type echoreq keep state" | sudo tee -a "${ANCHOR_FILE}" >/dev/null
	fi

	echo "# =====================================" | sudo tee -a "${ANCHOR_FILE}" >/dev/null

	# Ensure /etc/pf.conf loads our anchor (idempotent)
	if ! grep -q "anchor \"${ANCHOR_NAME}\"" "$PF_CONF"; then
		echo "Updating ${PF_CONF} to load anchor \"${ANCHOR_NAME}\"..."
		sudo bash -c "printf '\nanchor \"${ANCHOR_NAME}\"\nload anchor \"${ANCHOR_NAME}\" from \"${ANCHOR_FILE}\"\n' >> '${PF_CONF}'"
	fi

	echo "Validating PF syntax..."
	sudo pfctl -nf "$PF_CONF"
	echo "Loading PF rules..."
	sudo pfctl -E >/dev/null 2>&1 || true
	sudo pfctl -f "$PF_CONF"

	echo "✅ PF rules loaded successfully for interface ${IFACE}."
	sudo pfctl -sr | head -n 40
}

disable_pf() {
	sudo pfctl -d >/dev/null 2>&1 || true
}

###################
### SSH SIGNING ###
###################

setup_git_ssh_signing() {

	# ---- edit these (or export NAME/EMAIL before running) ----
	#: "${NAME:=""}"
	#: "${EMAIL:=""}"
	# ---------------------------------------------------------

	local NAME="${1:-}"
	local EMAIL="${2:-}"

	local SIGNING_KEY="$HOME/.ssh/id_ecdsa"
	local GITHUB_IDENTITY="$HOME/.ssh/id_ecdsa_auth"
	local ALLOWED_SIGNERS_DIR="$HOME/.config/git"
	local ALLOWED_SIGNERS_FILE="$ALLOWED_SIGNERS_DIR/allowed_signers"
	local SSHCONF="$HOME/.ssh/config"

	echo ""
	echo "Provide GITHUB account information for GIT config."
	[[ -z "$NAME" ]] && read -r -p "Enter account name: " NAME
	[[ -z "$EMAIL" ]] && read -r -p "Enter account email: " EMAIL
	echo ""

	# Required keys
	[[ -f "$SIGNING_KEY" ]] || {
		echo "Missing signing key: $SIGNING_KEY"
		return 1
	}
	[[ -f "$SIGNING_KEY.pub" ]] || {
		echo "Missing public key: $SIGNING_KEY.pub"
		return 1
	}
	[[ -f "$GITHUB_IDENTITY" ]] || {
		echo "Missing GitHub identity key: $GITHUB_IDENTITY"
		return 1
	}

	# SSH dir + config
	mkdir -p "$HOME/.ssh"
	chmod 700 "$HOME/.ssh"
	touch "$SSHCONF"
	chmod 600 "$SSHCONF" || true

	# Key perms (don’t die if a .pub is missing)
	chmod 600 "$SIGNING_KEY" "$GITHUB_IDENTITY" 2>/dev/null || true
	chmod 644 "$SIGNING_KEY.pub" "$GITHUB_IDENTITY.pub" 2>/dev/null || true

	# allowed_signers (for local verification of ssh-signed commits/tags)
	mkdir -p "$ALLOWED_SIGNERS_DIR"
	(
		umask 077
		awk -v email="$EMAIL" '{print email, $1, $2}' "$SIGNING_KEY.pub" >"$ALLOWED_SIGNERS_FILE"
	)

	# Git config (does NOT overwrite ~/.gitconfig)
	git config --global user.name "$NAME"
	git config --global user.email "$EMAIL"
	git config --global gpg.format ssh
	git config --global user.signingkey "$SIGNING_KEY"
	git config --global gpg.ssh.allowedSignersFile "$ALLOWED_SIGNERS_FILE"
	git config --global commit.gpgsign true
	git config --global tag.gpgsign true

	# Ensure github.com uses your preferred identity key
	if ! grep -qE '^[[:space:]]*Host[[:space:]]+github\.com([[:space:]]|$)' "$SSHCONF"; then
		cat >>"$SSHCONF" <<EOF

Host github.com
  HostName github.com
  User git
  IdentityFile $GITHUB_IDENTITY
  IdentitiesOnly yes
EOF
	fi

	echo ""
	echo "Testing GitHub SSH..."
	ssh -T git@github.com || true
	echo ""

	#git log --show-signature -1 || true
}

##################
###### DNS #######
##################

enable_cloudflare_dns() {

	brew install cloudflared

	##Needed?
	sudo mkdir -p /usr/local/etc/cloudflared

	sudo tee /usr/local/etc/cloudflared/config.yml >/dev/null <<EOF
logDirectory: /var/log/cloudflared

proxy-dns: true
proxy-dns-address: 127.0.0.1
proxy-dns-port: 53

proxy-dns-upstream:
  - https://1.1.1.1/dns-query
  - https://1.0.0.1/dns-query
  - https://dns.quad9.net/dns-query
EOF
	##END Needed?

	#
	sudo tee /Library/LaunchDaemons/com.mac.cloudflared.dns.plist >/dev/null <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.mac.cloudflared.dns</string>

    <key>ProgramArguments</key>
    <array>
      <string>/usr/local/opt/cloudflared/bin/cloudflared</string>
      <string>--config</string>
      <string>/usr/local/etc/cloudflared/config.yml</string>
      <string>proxy-dns</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/usr/local/var/log/cloudflared.plist.log</string>

    <key>StandardErrorPath</key>
    <string>/usr/local/var/log/cloudflared.plist.log</string>
  </dict>
</plist>
PLIST

	sudo chown root:wheel /Library/LaunchDaemons/com.mac.cloudflared.dns.plist
	sudo chmod 644 /Library/LaunchDaemons/com.mac.cloudflared.dns.plist

	# Nicely ensure the LaunchDaemon is loaded
	if sudo launchctl list | grep 'cloudflared.dns'; then
		echo "cloudflared LaunchDaemon already loaded."
	else
		echo "Loading cloudflared LaunchDaemon..."
		#sudo launchctl load /Library/LaunchDaemons/com.mac.cloudflared.dns.plist
		sudo launchctl bootout system /Library/LaunchDaemons/com.mac.cloudflared.dns.plist 2>/dev/null || true
		sudo launchctl bootstrap system /Library/LaunchDaemons/com.mac.cloudflared.dns.plist
	fi

}

enable_cloudflare_dns_local() {

	# Set DNS for all enabled macOS network services to 127.0.0.1

	DNS_IP="127.0.0.1"

	echo "Setting DNS for all enabled network services to ${DNS_IP} ..."
	echo

	# Read network services and loop over them
	networksetup -listallnetworkservices | while IFS= read -r service; do
		# Skip header line
		[[ "$service" == "An asterisk"* ]] && continue
		# Skip blank lines
		[[ -z "$service" ]] && continue

		# Disabled services start with '*'
		if [[ "$service" == \** ]]; then
			echo "Skipping disabled service: ${service#\* }"
			continue
		fi

		echo "Configuring DNS for: ${service}"
		networksetup -setdnsservers "${service}" "${DNS_IP}"
	done

	echo
	echo "Finished"
	echo
	echo "Current DNS per service:"
	networksetup -listallnetworkservices | while IFS= read -r service; do
		[[ "$service" == "An asterisk"* ]] && continue
		[[ -z "$service" ]] && continue
		[[ "$service" == \** ]] && continue
		echo "${service}:"
		networksetup -getdnsservers "${service}"
	done

}

disable_cloudflare_dns() {

	sudo launchctl bootout system /Library/LaunchDaemons/com.mac.cloudflared.dns.plist 2>/dev/null ||
		sudo launchctl unload /Library/LaunchDaemons/com.mac.cloudflared.dns.plist 2>/dev/null

	sudo rm /Library/LaunchDaemons/com.mac.cloudflared.dns.plist

	sudo rm -rf /usr/local/etc/cloudflared
	sudo rm -f /usr/local/var/log/cloudflared.plist.log
	# Read network services and loop over them
	networksetup -listallnetworkservices | while IFS= read -r service; do
		# Skip header line
		[[ "$service" == "An asterisk"* ]] && continue
		# Skip blank lines
		[[ -z "$service" ]] && continue

		# Disabled services start with '*'
		if [[ "$service" == \** ]]; then
			echo "Skipping disabled service: ${service#\* }"
			continue
		fi

		echo "Configuring DNS for: ${service}"
		networksetup -setdnsservers "${service}" empty
	done
	echo
	echo "Removing Cloudflare DNS..."
	echo
	brew remove cloudflared

}

menu_dns() {

	while true; do

		clear
		echo $hr_line
		echo "🌐 Cloudflare DoH DNS Menu 🌐"
		echo $hr_line
		echo "1) Add Cloudflare DoH DNS"
		echo "2) Remove Cloudflare DoH DNS"
		echo "3) 🔙 Back to Main Menu"
		echo ""
		read -p "Enter your choice: " dns_choice

		case "$dns_choice" in
		1)
			echo
			echo "Installing Cloudflare DoH DNS..."
			echo

			if ! command -v brew &>/dev/null; then
				install_homebrew
			fi

			enable_cloudflare_dns

			echo
			echo "Setting DNS servers to localhost..."
			echo
			enable_cloudflare_dns_local
			echo
			echo "Cloudflare DoH DNS is now enabled. You can check the status with 'launchctl list'."
			echo
			echo "✅ You can verify your encrypted DNS here: https://one.one.one.one/help/"
			echo
			sudo launchctl list | grep cloudflared
			;;
		2)
			disable_cloudflare_dns
			echo
			echo "✅ You can verify your standard DNS here: https://one.one.one.one/help/"
			echo
			;;
		3)
			menu_main
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		pause
	done
}

################################################################################
######       MENUs
################################################################################

hr_line="────────────────────────────────────────────"

menu_remote() {

	while true; do

		# Check current status
		local status
		status=$(sudo systemsetup -getremotelogin 2>/dev/null | awk '{print $3}')

		# Determine icon
		local icon
		if [[ "$status" == "On" ]]; then
			icon="🟢"
		else
			icon="🔴"
		fi

		clear
		echo $hr_line
		echo "🧱 Remote Login (SSH) Menu 🧱"
		echo $hr_line
		echo "*Terminal requires Full Disk Access"
		echo "1) 🔒 Enable Remote Login (SSH)"
		echo "2) 🔓 Disable Remote Login (SSH)"
		echo $hr_line
		echo "📋 Remote Login (SSH) status: ${icon} (State = ${status:-unknown})"
		echo $hr_line
		echo "4) Toggle Remote Login (SSH)"
		echo "5) 🔙 Back to Main Menu"
		echo ""
		read -rp "Please select an option [1-5]: " remote_choice

		case "$remote_choice" in
		1 | on | enable)
			echo "🧩 Enabling Remote Login (SSH)..."
			sudo systemsetup -setremotelogin on
			echo "🔒 Remote Login is now ON 🟢"
			;;
		2 | off | disable)
			echo "🧩 Disabling Remote Login (SSH)..."
			sudo systemsetup -setremotelogin off
			echo "🔓 Remote Login is now OFF 🔴"
			;;
		3 | status | "")
			echo "📡 Remote Login status: $icon ($status)"
			;;
		4 | toggle)
			if [[ "$status" == "On" ]]; then
				sudo systemsetup -setremotelogin off
				echo "🔴 Remote Login disabled."
			else
				sudo systemsetup -setremotelogin on
				echo "🟢 Remote Login enabled."
			fi
			;;
		5 | exit)
			echo "Exiting."
			menu_main
			;;
		*)
			echo "Usage: {on|off|toggle|status}"
			;;
		esac
		pause
	done
}

menu_firewall() {

	while true; do

		# Query macOS firewall state, update state
		fw_state=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate |
			awk -F'[()]' '/State/{print $2}' |
			awk -F'=' '{gsub(/ /,""); print $2}')

		# Convert to icon
		if [[ "$fw_state" == "1" ]]; then
			fw_icon="🟢"
		elif [[ "$fw_state" == "0" ]]; then
			fw_icon="🔴"
		else
			fw_icon="⚪"
		fi

		pf_state=$(sudo pfctl -s info | awk '/Status:/{print $2}')
		if [[ "$pf_state" == "Enabled" ]]; then
			pf_icon="🟢"
		else
			pf_icon="🔴"
		fi

		clear
		echo $hr_line
		echo "🧱 Firewall / Packet Filtering Menu 🧱"
		echo $hr_line
		echo "1) 🔒 Enable Firewall"
		echo "2) 🔓 Disable Firewall"
		echo $hr_line
		echo "📋 Firewall status: ${fw_icon} (State = ${fw_state:-unknown})"
		echo $hr_line
		echo "4) Enable Packet Filtering"
		echo "5) Disable Packet Filtering"
		echo $hr_line
		echo "📋 Packet Filtering status: ${pf_icon} (${pf_state:-unknown})"
		echo $hr_line
		echo "7) 🔙 Back to Main Menu"
		echo ""
		read -rp "Please select an option [1-7]: " fw_choice

		# Toggle macOS Application Firewall
		# Requires sudo (admin)

		case "$fw_choice" in
		1 | on | enable)
			echo "🟢 Enabling macOS Application Firewall..."
			sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
			;;
		2 | off | disable)
			echo "🔴 Disabling macOS Application Firewall..."
			sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
			;;
		3 | status) #I left this for no reason :)
			echo "📋 Firewall status:"
			/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
			;;
		4 | pf)
			enable_pf
			;;
		5 | pfdisable)
			disable_pf
			;;
		7 | exit)
			echo "Exiting."
			menu_main
			;;
		*)
			echo "Invalid option. Please try again."
			echo "Usage: on|off|status|pf|exit or 1-7"
			;;
		esac
		pause
	done

}

menu_dev() {

	while true; do

		clear
		echo $hr_line
		echo "💻 Development Applications Menu 💻"
		echo $hr_line
		echo "1) Development Tools (includes kdoctor)"
		echo "2) Android Studio"
		echo "3) Visual Studio Code"
		echo "4) IntelliJ IDEA"
		echo "5) JetBrains WebStorm"
		echo "6) Arduino"
		echo "7) Glade (GTK+ UI Designer)"
		echo "8) Deploy zsh shell tools → ~/.zshrc"
		echo "9) Setup GIT ssh signing/authentication keys"
		echo "10) 🔙 Back to Main Menu"
		echo ""
		read -rp "Please select an option [1-10]: " remote_choice

		case "$remote_choice" in
		1)
			install_formulae wget
			install_formulae telnet
			install_formulae kdoctor
			;;
		2)
			install_cask "android-studio"
			;;
		3)
			#brew install --cask vscodium

			# Install via Homebrew
			#brew install --cask visual-studio-code

			install_cask "visual-studio-code"

			if [ ! -f "/usr/local/bin/code" ]; then
				sudo ln -sfn "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code >/dev/null 2>&1
			fi

			install_formulae shfmt

			brew install shfmt
			# Install extensions
			while IFS= read -r ext; do
				[[ -z "$ext" ]] && continue
				[[ "$ext" =~ ^# ]] && continue
				code --install-extension "$ext"
			done <"$SCRIPT_DIR/vscode-extensions.txt"

			install_powershell

			;;
		4)
			install_cask "intellij-idea"
			;;
		5)
			install_cask "webstorm"
			;;
		6)
			install_cask "arduino-ide"
			;;
		7)
			install_formulae glade
			;;
		8)
			# Copy examples only if the target file doesn't exist yet
			[[ -f "$HOME/.zshrc" ]] || cp -n "./zshrc.example" "$HOME/.zshrc"
			;;
		9)
			setup_git_ssh_signingw
			;;
		10 | exit)
			echo "Exiting."
			menu_main
			;;
		*)
			echo ""
			;;
		esac
		pause
	done
}

# Main Menu
menu_main() {

	while true; do

		clear
		#echo $hr_line
		echo "           🍎 Mac Setup Menu 🍎"
		echo $hr_line
		echo "1) 🍺 Install/Update Homebrew"
		echo "2) Install Homebrew Applications"
		echo "3) Install btop"
		echo "4) Install Veracrypt"
		echo $hr_line
		echo "5) 🛠️ Development Applications"
		echo "6) Install Java/Cocoapods"
		echo "7) Install Node.js®"
		echo $hr_line
		echo "8) Setup Finder"
		echo "9) Setup System"
		echo "10) Setup Dock"
		echo $hr_line
		echo "11) LibreOffice (Office Suite)"
		echo "12) DBeaver (Database Manager)"
		echo $hr_line
		echo "13) Manage Remote Login (SSH)"
		echo "14) 🧱 Manage Firewall / Packet Filtering"
		echo "15) 🌐 Manage DoH DNS"
		echo $hr_line
		echo "16) 📺 Install OpenShot"
		echo "17) 🖼️ Install Blender/Gimp/Inkscape"
		echo "18) Install Freecad"
		echo "19) Install OrcaSlicer"
		echo "20) Install RP-Imager"
		echo $hr_line
		echo "21) Exit"
		echo ""
		read -rp "Please select an option [1-21]: " choice
		case "$choice" in
		1)
			install_homebrew
			;;
		2)
			# Install Homebrew and applications

			# Install Homebrew if not already installed
			if ! command -v brew &>/dev/null; then
				install_homebrew
			fi

			install_apps

			echo "Installed applications:"
			echo "Homebrew packages from Brewfile"
			echo ""

			;;
		3)
			install_formulae btop
			;;
		4)
			install_cask "veracrypt"
			;;
		5)
			menu_dev
			;;
		6)
			install_java
			;;
		7)
			install_nodejs
			;;
		8)
			setup_finder
			echo "Finder configuration finished."
			;;
		9)
			setup_system
			echo "System configuration finished."
			;;
		10)
			setup_dock
			echo "Dock configuration finished."
			;;
		11)
			install_cask "libreoffice"
			;;
		12)
			install_cask "dbeaver-community"
			;;
		13)
			menu_remote
			#sudo systemsetup -getremotelogin
			#ifconfig | grep inet
			;;
		14)
			menu_firewall
			echo "Firewall setup finished."
			;;
		15)
			menu_dns
			echo "DoH DNS setup finished."
			;;
		16)
			install_cask "openshot-video-editor"
			;;
		17)
			install_cask "blender"
			install_cask "gimp"
			install_cask "inkscape"
			install_cask "upscayl"
			;;
		18)
			install_cask "freecad"
			;;
		19)
			install_cask "orcaslicer"
			;;
		20)
			install_cask "raspberry-pi-imager"
			;;
		21)
			echo "Exiting."
			exit 0
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		pause
	done
}

menu_main
