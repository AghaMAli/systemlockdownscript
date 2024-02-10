#!/bin/bash

# Function to display the banner
display_banner() {
    echo "***********************************************"
    echo "*                                             *"
    echo "*          SYSTEM LOCKDOWN MANAGER            *"
    echo "*                                             *"
    echo "***********************************************"
    echo ""
}

# Function to lock down the system for 3 hours
lock_system() {
    # Lockdown duration in seconds (3 hours)
    lockdown_duration=$((3 * 60 * 60))

    restart_ssh_service() {
    if command -v systemctl > /dev/null && systemctl list-units --full --no-pager | grep -q 'sshd.service'; then
        systemctl restart sshd
    elif command -v service > /dev/null && service --status-all 2>&1 | grep -q 'sshd'; then
        service ssh restart
    else
        echo "WARNING: OpenSSH server not found or unsupported init system."
    fi
}

    # Temporary directory to store original configurations
    temp_dir="/tmp/lockdown_temp"

    # Create temporary directory if it doesn't exist
    mkdir -p "$temp_dir"

    # Store original SSH configuration
    cp /etc/ssh/sshd_config "$temp_dir/sshd_config"

    # Update SSH configuration to disallow remote access
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

    # Restart SSH service to apply changes
    systemctl restart sshd

    # Enable firewall and block incoming connections
    ufw enable
    ufw default deny incoming

    # Set message for users attempting to log in during lockdown
    lockdown_message="System is currently under security lockdown. Access is restricted for maintenance. Please try again later."
    echo "$lockdown_message" > /etc/nologin.txt

    # Disable Wi-Fi
    nmcli radio wifi off

    echo "System locked down for 3 hours."
    echo "Please wait for the lockdown duration to expire."
    echo ""
    sleep $lockdown_duration
    restart_ssh_service

    # Restore original SSH configuration
    cp "$temp_dir/sshd_config" /etc/ssh/sshd_config

    # Restart SSH service to apply changes
    systemctl restart sshd

    # Disable firewall
    ufw disable

    # Enable Wi-Fi
    nmcli radio wifi on

    # Remove lockdown message
    rm /etc/nologin.txt

    # Remove temporary directory
    rm -r "$temp_dir"

    echo "System lockdown lifted."
}

# Function to unlock the system with a password
unlock_system() {
    echo "Enter the unlock password (8 letters):"
    read -s password
    if [ "$password" == "password" ]; then
        echo "Unlocking the system..."
        # Restore original SSH configuration
        cp "$temp_dir/sshd_config" /etc/ssh/sshd_config

        # Restart SSH service to apply changes
        systemctl restart sshd

        # Disable firewall
        ufw disable

        # Enable Wi-Fi
        nmcli radio wifi on

        # Remove lockdown message
        rm /etc/nologin.txt

        # Remove temporary directory
        rm -r "$temp_dir"

        echo "System unlocked."
    else
        echo "Incorrect password. System remains locked."
    fi
}

# Main function to display menu and process user input
main() {
    while true; do
        display_banner
        echo "1. Lock the system for 3 hours"ufw
        echo "2. Unlock the system (requires password)"
        echo "3. Exit"
        echo ""
        read -p "Select an option: " choice
        case $choice in
            1) lock_system;;
            2) unlock_system;;
            3) echo "Exiting..."; exit;;
            *) echo "Invalid option. Please select again.";;
        esac
        sleep 2
    done
}

# Start the script
main
