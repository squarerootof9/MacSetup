# MacSetup
# **macOS Setup and Hosts Updater Scripts**

This repository contains scripts to automate the setup of a macOS system with preferred settings and applications, and to enhance system security and privacy by updating the hosts file to block ads, phishing sites, and other malicious domains. The scripts are designed to work seamlessly on a fresh install and do not require an Apple ID or any login credentials.

---

## **Table of Contents**

- [Overview](#overview)
- [Setup Script (`setup.sh`)](#setup-script-setupsh)
  - [Features](#features)
  - [Usage](#usage)
- [Brewfile](#brewfile)
  - [Purpose](#purpose)
  - [Contents](#contents)
- [Hosts Updater Script (`hosts_updater.sh`)](#hosts-updater-script-hosts_updatersh)
  - [Purpose](#purpose-1)
  - [Usage](#usage-1)
  - [How It Works](#how-it-works)
  - [Compatibility](#compatibility)
- [Important Notes](#important-notes)
- [License](#license)

---

## **Overview**

This project aims to simplify the initial setup of a macOS system by automating the installation of essential applications and configuring system preferences to your liking. Additionally, it enhances your system's security and privacy by updating the hosts file to block unwanted domains.

---

## **Setup Script (`setup.sh`)**

### **Features**

- **Automates Installation of Applications:**
  - Installs Homebrew if not already installed.
  - Uses a `Brewfile` to install a list of applications and packages.
  - Installs additional applications like OrcaSlicer directly from their sources.

- **Configures System Preferences:**
  - **Finder Configuration:**
    - Shows hidden files, path bar, and status bar.
    - Sets default search scope and view style.
    - Disables animations and warning dialogs.
  - **System Configuration:**
    - Adjusts mouse and scroll wheel speed.
    - Disables natural scrolling.
    - Configures sleep and screen saver settings.
    - Shows the Library folder.
  - **Dock Configuration:**
    - Removes all existing Dock items.
    - Adds a predefined list of applications to the Dock.
    - Adjusts Dock preferences.

- **Java Configuration:**
  - Sets up Java environment variables.
  - Creates symbolic links for Java installations.

- **Runs on a Fresh Install:**
  - Designed to work best on a fresh macOS installation.
  - Does not require an Apple ID or any login credentials.

### **Usage**

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/yourusername/yourrepository.git
   cd yourrepository
   ```

2. **Make the Script Executable:**

   ```bash
   chmod +x setup.sh
   ```

3. **Run the Script:**

   ```bash
   ./setup.sh
   ```

   - The script will prompt for your password when necessary (e.g., when using `sudo`).

4. **Follow On-Screen Instructions:**

   - The script will output progress messages.
   - At the end, it will advise you to restart your computer to apply all changes.

---

## **Brewfile**

### **Purpose**

The `Brewfile` is used by Homebrew to install a predefined list of applications and packages. It simplifies the installation process by allowing you to specify all desired applications in one place.

### **Contents**

The `Brewfile` typically includes taps and a list of applications to install. For example:

```ruby

# Homebrew Packages
brew "wget"
brew "curl"
brew "git"

# Cask Applications
cask "firefox"
cask "vlc"
cask "geany"
```

- **Taps:** Additional repositories from which to install packages.
- **Brews:** Command-line tools and utilities.
- **Casks:** GUI applications.

**Note:** The actual contents of the `Brewfile` can be customized to include the applications and packages you prefer.

---

## **Hosts Updater Script (`hosts_updater.sh`)**

### **Purpose**

The `hosts_updater.sh` script updates your system's hosts file to block ads, phishing sites, malware domains, and other malicious websites. This enhances your privacy and security while browsing the internet.

### **Usage**

1. **Make the Script Executable:**

   ```bash
   chmod +x hosts_updater.sh
   ```

2. **Run the Script:**

   ```bash
   ./hosts_updater.sh
   ```

3. **Select an Option:**

   The script presents a menu with three options:

   ```
   --------------------------------------------
   Hosts File Updater Script
   --------------------------------------------
   1) Add/Update hosts entries
   2) Remove hosts entries
   3) Exit
   --------------------------------------------
   Please select an option [1-3]:
   ```

   - **1) Add/Update hosts entries:** Downloads the latest hosts file and updates your system's hosts file.
   - **2) Remove hosts entries:** Removes the entries added by this script.
   - **3) Exit:** Exits the script.

4. **Follow On-Screen Instructions:**

   - The script will inform you of the progress and any actions taken.
   - It will backup your original hosts file before making changes.

### **How It Works**

- **Downloading Hosts File:**

  - The script downloads a hosts file from a trusted source: [MVPS Hosts](https://winhelp2002.mvps.org/hosts.htm).
  - The hosts file contains mappings of known malicious domains to `0.0.0.0`, effectively blocking them.

- **Updating the Hosts File:**

  - The script backs up your existing `/etc/hosts` file.
  - It removes any previous entries added by itself to avoid duplicates.
  - It appends the new entries, enclosed within identifiable comments for easy management.

- **Flushing DNS Cache:**

  - After updating the hosts file, the script flushes the DNS cache to ensure changes take effect immediately.
  - Works on both macOS and Linux by detecting the operating system and using the appropriate commands.

### **Compatibility**

- **Cross-Platform Support:**

  - The script is designed to work on both **macOS** and **Linux** systems.
  - It automatically detects the operating system and adjusts its operations accordingly.

- **No Dependencies on Apple ID or Logins:**

  - The script does not require any Apple ID, login credentials, or additional setup.
  - Ideal for fresh installations where minimal configuration has been done.

---

## **Important Notes**

- **Administrative Privileges:**

  - Both the `setup.sh` and `hosts_updater.sh` scripts may require `sudo` privileges to execute certain commands (e.g., modifying system files).

- **Backups:**

  - The `hosts_updater.sh` script creates backups of your hosts file before making any changes. Backup files are stored with a timestamp (e.g., `/etc/hosts.backup.YYYYMMDDHHMMSS`).

- **Customizations:**

  - You can customize the `Brewfile` to include or exclude applications as per your preference.
  - The list of applications added to the Dock in `setup.sh` can be modified within the script.

- **Testing:**

  - It is recommended to test the scripts in a controlled environment or virtual machine before running them on a production system.

- **No Apple ID Required:**

  - All installations and configurations are performed without the need for an Apple ID or any form of login.
  - The scripts are designed to fetch applications and updates from open-source repositories and trusted sources.

---

## **License**

This project is licensed under the MIT License.

```
MIT License

Copyright (c) YEAR Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

[Full MIT License Text]
```

Replace `YEAR` and `Your Name` with the appropriate information.

---

## **Contributing**

Contributions are welcome! If you have suggestions, improvements, or fixes, feel free to open an issue or submit a pull request.

---

## **Acknowledgements**

- **Homebrew:** The missing package manager for macOS.
- **dockutil:** A tool for managing macOS Dock items.
- **MVPS Hosts:** Provides a comprehensive hosts file to block unwanted domains.

---

## **Contact**

For questions or support, please open an issue on the repository or contact [Your Email].

---

**Note:** Always review scripts and understand their functions before running them, especially when they modify system files or require administrative privileges.
