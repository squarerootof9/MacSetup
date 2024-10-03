#!/usr/bin/env bash
# hosts_updater.sh
# Script to add/update or remove entries in /etc/hosts for mac or linux from a remote hosts file
# Hosts Source: https://winhelp2002.mvps.org/hosts.txt
# Author: oneofthree
# Date: 2024-10-01

# This script is licensed under the MIT License.
# See the LICENSE file in the project root for license information.

HOSTS_URL="https://winhelp2002.mvps.org/hosts.txt"
HOSTS_FILE="/etc/hosts"
BACKUP_FILE="/etc/hosts.backup.$(date +%Y%m%d%H%M%S)"
TEMP_FILE="/tmp/hosts_downloaded_$$"
SCRIPT_TAG="# BEGIN MVPS HOSTS BLOCK"
SCRIPT_END_TAG="# END MVPS HOSTS BLOCK"

function add_update_hosts() {
    echo "Downloading hosts file from $HOSTS_URL..."
    if ! curl -s -o "$TEMP_FILE" "$HOSTS_URL"; then
        echo "Error: Failed to download hosts file."
        exit 1
    fi

    # Remove carriage returns in case the file uses Windows line endings
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS uses BSD sed
        sed -i '' 's/\r$//' "$TEMP_FILE"
    else
        # Linux uses GNU sed
        sed -i 's/\r$//' "$TEMP_FILE"
    fi

    # Remove existing entries added by this script
    remove_hosts_entries

    # Backup the original hosts file
    echo "Backing up the original hosts file to $BACKUP_FILE"
    sudo cp "$HOSTS_FILE" "$BACKUP_FILE"

    # Append the downloaded entries to the hosts file with identifiable comments
    echo "Adding new entries to $HOSTS_FILE..."
    {
        echo "$SCRIPT_TAG"
        # Exclude any entries that are comments or localhost entries
        grep -vE '^(#|$|[[:space:]]*#|127\.0\.0\.1[[:space:]]|::1[[:space:]])' "$TEMP_FILE"
        echo "$SCRIPT_END_TAG"
    } | sudo tee -a "$HOSTS_FILE" > /dev/null

    # Clean up temporary file
    rm -f "$TEMP_FILE"

    # Flush DNS cache
    echo "Flushing DNS cache..."
    flush_dns_cache

    echo "Hosts file updated successfully."
}


function remove_hosts_entries() {
    if grep -q "$SCRIPT_TAG" "$HOSTS_FILE"; then
        echo "Removing existing entries added by this script..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS uses BSD sed
            sudo sed -i '' "/$SCRIPT_TAG/,/$SCRIPT_END_TAG/d" "$HOSTS_FILE"
        else
            # Linux uses GNU sed
            sudo sed -i "/$SCRIPT_TAG/,/$SCRIPT_END_TAG/d" "$HOSTS_FILE"
        fi
    else
        echo "No entries to remove."
    fi
}

flush_dns_cache() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo "Flushing DNS cache on macOS..."
        if command -v dscacheutil >/dev/null 2>&1 && command -v killall >/dev/null 2>&1; then
            sudo dscacheutil -flushcache
            sudo killall -HUP mDNSResponder
            echo "DNS cache flushed on macOS."
        else
            echo "Required commands not found on macOS. Failed to flush DNS cache."
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        flushed=false
        echo "Flushing DNS cache on Linux..."

        if command -v resolvectl >/dev/null 2>&1; then
            sudo resolvectl flush-caches
            echo "DNS cache flushed using resolvectl."
            flushed=true
        elif command -v systemd-resolve >/dev/null 2>&1; then
            sudo systemd-resolve --flush-caches
            echo "DNS cache flushed using systemd-resolve."
            flushed=true
        elif systemctl is-active --quiet systemd-resolved; then
            sudo systemctl restart systemd-resolved
            echo "DNS cache flushed by restarting systemd-resolved."
            flushed=true
        fi

        if systemctl is-active --quiet nscd; then
            sudo systemctl restart nscd
            echo "DNS cache flushed by restarting nscd."
            flushed=true
        fi
        if systemctl is-active --quiet dnsmasq; then
            sudo systemctl restart dnsmasq
            echo "DNS cache flushed by restarting dnsmasq."
            flushed=true
        fi
        if [ "$flushed" = false ]; then
            echo "No known DNS caching services found. Failed to flush DNS cache."
        fi
    else
        echo "Unsupported OS type: $OSTYPE. Cannot flush DNS cache."
    fi
}


function show_menu() {
    echo "--------------------------------------------"
    echo "Hosts File Updater Script"
    echo "--------------------------------------------"
    echo "1) Add/Update hosts entries"
    echo "2) Remove hosts entries"
    echo "3) Exit"
    echo "--------------------------------------------"
    read -rp "Please select an option [1-3]: " choice
    case $choice in
        1)
            add_update_hosts
            ;;
        2)
            remove_hosts_entries
            # Flush DNS cache after removal
            echo "Flushing DNS cache..."
            #sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
            flush_dns_cache
            echo "Entries removed successfully."
            ;;
        3)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            show_menu
            ;;
    esac
}

# Main script execution
show_menu
