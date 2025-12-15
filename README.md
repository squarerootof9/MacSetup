# MacSetup

# **macOS Setup and Hosts Updater Scripts**

This repository contains scripts to automate the setup of a macOS system with preferred settings and applications, and to enhance system security and privacy by updating the hosts file to block ads, phishing sites, and other malicious domains. The scripts are designed to work seamlessly on a fresh install and do not require an Apple ID or any login credentials.

---

## **Table of Contents**

* [Overview](#overview)
* [Setup Script (`setup.sh`)](#setup-script-setupsh)

  * [Features](#features)
  * [Usage](#usage)
  * [Menu Options](#menu-options)
* [Brewfile](#brewfile)

  * [Purpose](#purpose)
  * [Contents](#contents)
* [Hosts Updater Script (`hosts_updater.sh`)](#hosts-updater-script-hosts_updatersh)
* [Important Notes](#important-notes)
* [License](#license)

---

## **Overview**

This project aims to simplify the initial setup of a macOS system by automating the installation of essential applications, configuring system preferences, and improving privacy by updating the system's hosts file.

---

## **Setup Script (`setup.sh`)**

### **Features**

* **Interactive Menu:**
  A user-friendly terminal menu allows automated configuration of the system and installation of applications.

* **Application Management:**

  * Installs Homebrew if not already present.
  * Uses a `Brewfile` to install a curated list of CLI and GUI apps.
  * Supports Java setup, Node.js, and Cocoapods installation.

* **System Configuration:**

  * **Finder:** Adjusts view, visibility, and behavior preferences.
  * **System:** Tweaks scrolling, speed, sleep, and visibility settings.
  * **Dock:** Clears and resets dock items and preferences.

* **Security & Remote Access:**

  * Adds a simple option to enable the macOS SSH server for remote access.

### **Usage**

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/squarerootof9/MacSetup.git
   cd MacSetup
   ```

2. **Make the Script Executable:**

   ```bash
   chmod +x setup.sh
   ```

3. **Run the Script:**

   ```bash
   ./setup.sh
   ```

4. **Follow the Menu Prompt:**

   Select an option by number and follow the on-screen instructions. Some changes may require a restart.

---

### **Menu Options**

When run, the script presents the following:

```
--------------------------------------------
🍎 Mac Setup Menu 🍎
--------------------------------------------
1) 🍺 Install Homebrew
2) Homebrew Applications
--------------------------------------------
3) Visual Studio Code
4) Install Java/Cocoapods
5) Install Node.js®
--------------------------------------------
6) Setup Finder
7) Setup System
8) Setup Dock
--------------------------------------------
9) Manage Remote Login (SSH)
10) 🧱 Manage Firewall / Packet Filtering
11) 🌐 Manage DoH DNS
--------------------------------------------
12) Exit

Please select an option [1-12]: 
```

Each section can be run independently, allowing for modular and repeatable setup processes.

---

## **Brewfile**

### **Purpose**

Defines the list of packages and applications to install via Homebrew.

### **Contents**

```ruby
# CLI Tools
brew "wget"
brew "curl"
brew "git"

# GUI Apps
cask "firefox"
cask "vlc"
cask "geany"
```

You can modify the `Brewfile` to suit your needs.

---

## **Hosts Updater Script (`hosts_updater.sh`)**

This optional script updates your `/etc/hosts` file to block malicious or annoying domains. It presents its own simple menu for adding or removing entries, and automatically backs up your original hosts file before changes.

See [Hosts Updater Script](#hosts-updater-script-hosts_updatersh) in the original for full details.

---

## **Important Notes**

* Scripts may require `sudo` to perform system-level changes.
* Designed to work without needing Apple ID login.
* Backups are made before any changes to critical files.
* Great for use on fresh installations or clean setups.

---

## **License**

MIT License. See full text in the original [README.md](./README.md).

---
