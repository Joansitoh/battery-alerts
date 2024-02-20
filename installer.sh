#!/bin/bash

# Variables
SCRIPT_NAME="battery-monitor"
DEPENDENCIES=("acpi" "notify-send")
MAN_PAGE="/usr/local/share/man/man1/$SCRIPT_NAME.1"
SERVICE_NAME="battery-monitor.service"
SYSTEMD_PATH="/etc/systemd/system/$SERVICE_NAME"

# Constants for colored output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

show_help() {
    echo "Usage: $SCRIPT_NAME [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help        Show this help message and exit"
    echo "  -r, --run         Run battery monitor"
    echo "  -t, --start       Start $SCRIPT_NAME systemd service"
    echo "  -i, --install     Install $SCRIPT_NAME as systemd service"
    echo "  -u, --uninstall   Uninstall $SCRIPT_NAME and systemd service"
    echo "  -up, --update     Update $SCRIPT_NAME from GitHub"
    echo "  -c, --check       Check dependencies"
    echo "  -s, --status      Show status of dependencies, systemd service, and execution"
}

print_error() {
    echo -e "[${RED}ERROR${NC}] $1"
}

print_success() {
    echo -e "[${GREEN}SUCCESS${NC}] $1"
}

print_warning() {
    echo -e "[${YELLOW}WARNING${NC}] $1"
}

send_notification() {
    notify-send -u critical -i "$2" -r 10 "Battery: $1" "$3"
}

start_service() {
    echo "Starting $SERVICE_NAME..."
    
    # Check if the systemd service is installed
    if systemctl is-enabled --quiet $SERVICE_NAME; then
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "[${YELLOW}WARNING${NC}] $SERVICE_NAME is already running."
        else
            sudo systemctl start $SERVICE_NAME
            echo -e "[${GREEN}SUCCESS${NC}] $SERVICE_NAME started successfully."
        fi
    else
        echo -e "[${RED}ERROR${NC}] $SERVICE_NAME is not installed. Please install it first."
    fi
}
run_battery_monitor() {
    echo "Running battery monitor..."
    while true; do
        check_battery_status
        sleep 1  # Check battery status every second
    done
}

check_dependencies() {
    echo "Checking dependencies..."
    for dep in "${DEPENDENCIES[@]}"; do
        if command -v "$dep" &>/dev/null; then
            echo -e "[${GREEN}OK${NC}] $dep is installed."
        else
            echo -e "[${RED}MISSING${NC}] $dep is not installed. You can install it using: ${YELLOW}sudo apt-get install -y $dep${NC}"
        fi
    done
}

install_service() {
    echo "Installing $SCRIPT_NAME..."

    # Check if the script is already in /usr/bin
    if [[ -f /usr/bin/$SCRIPT_NAME ]]; then
        echo -e "[${YELLOW}WARNING${NC}] The script is already located in /usr/bin."
        read -p "Do you want to update the current version? (u for uninstall, up for update, any other key to cancel) " action
        case "$action" in
            u)
                uninstall_service
                exit 0
                ;;
            up)
                update_script
                exit 0
                ;;
            *)
                echo "Installation cancelled."
                exit 0
                ;;
        esac
    fi

    # Move the script to /usr/bin
    read -p "Do you want to move the script to /usr/bin for easy execution? (y/n) " move_script
    if [[ $move_script == "y" || $move_script == "Y" ]]; then
        sudo cp $0 /usr/bin/$SCRIPT_NAME
        echo -e "[${GREEN}SUCCESS${NC}] Script moved to /usr/bin."
    fi

    # Add alias to .bashrc
    read -p "Do you want to add an alias for the command in .bashrc? (y/n) " add_alias
    if [[ $add_alias == "y" || $add_alias == "Y" ]]; then
        echo "alias $SCRIPT_NAME='/usr/bin/$SCRIPT_NAME'" >> ~/.bashrc
        source ~/.bashrc
        echo -e "[${GREEN}SUCCESS${NC}] Alias added to .bashrc."
    fi

    # Install systemd service
    read -p "Do you want to install the systemd service? (y/n) " install_service
    if [[ $install_service == "y" || $install_service == "Y" ]]; then
        # Create systemd service file
        cat << EOF > $SERVICE_NAME
[Unit]
Description=Battery Monitor Service
After=network.target

[Service]
ExecStart=/usr/bin/$SCRIPT_NAME -r
Restart=always
User=$USER
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/$USER/.Xauthority

[Install]
WantedBy=multi-user.target
EOF

        # Move the service file to the correct location
        sudo mv $SERVICE_NAME $SYSTEMD_PATH

        # Reload systemd, enable and start the service
        sudo systemctl daemon-reload
        sudo systemctl enable $SERVICE_NAME
        echo -e "[${GREEN}SUCCESS${NC}] $SERVICE_NAME installed successfully."
    fi

    # Auto start the service
    read -p "Do you want to auto start the service? (y/n) " auto_start
    if [[ $auto_start == "y" || $auto_start == "Y" ]]; then
        sudo systemctl start $SERVICE_NAME
        echo -e "[${GREEN}SUCCESS${NC}] $SERVICE_NAME started successfully."
    fi
}

uninstall_service() {
    echo "Uninstalling $SCRIPT_NAME..."

    # Check if the systemd service is installed
    if systemctl is-enabled --quiet $SERVICE_NAME; then
        # Stop the service if it's running
        if systemctl is-active --quiet $SERVICE_NAME; then
            sudo systemctl stop $SERVICE_NAME
        fi

        # Disable the service
        sudo systemctl disable $SERVICE_NAME

        # Remove the service file
        sudo rm $SYSTEMD_PATH

        # Reload systemd
        sudo systemctl daemon-reload

        echo -e "[${GREEN}SUCCESS${NC}] $SERVICE_NAME uninstalled successfully."
    fi

    # Check if the script is in /usr/bin
    if [[ -f /usr/bin/$SCRIPT_NAME ]]; then
        sudo rm /usr/bin/$SCRIPT_NAME
        echo -e "[${GREEN}SUCCESS${NC}] Script removed from /usr/bin."
    fi

    # Check if the alias is in .bashrc
    if grep -q "alias $SCRIPT_NAME='/usr/bin/$SCRIPT_NAME'" ~/.bashrc; then
        sed -i "\|alias $SCRIPT_NAME='/usr/bin/$SCRIPT_NAME'|d" ~/.bashrc
        source ~/.bashrc
        echo -e "[${GREEN}SUCCESS${NC}] Alias removed from .bashrc."
    fi

    echo -e "[${GREEN}SUCCESS${NC}] $SCRIPT_NAME uninstalled successfully."
}

update_script() {
    echo "Updating $SCRIPT_NAME from GitHub..."
    temp_dir=$(mktemp -d)
    git clone https://github.com/Joansitoh/battery-monitor.git "$temp_dir"
    if cmp -s "$0" "$temp_dir/$SCRIPT_NAME.sh"; then
        echo -e "[${GREEN}SUCCESS${NC}] $SCRIPT_NAME is up to date."
    else
        mv "$temp_dir/$SCRIPT_NAME.sh" "$0"
        chmod +x "$0"
        echo -e "[${GREEN}SUCCESS${NC}] $SCRIPT_NAME updated successfully."
    fi
    rm -rf "$temp_dir"
}

check_battery_status() {
    battery_info=$(acpi)
    battery_level=$(echo "$battery_info" | grep -oP '\d+(?=%)')
    battery_charging=$(echo "$battery_info" | grep -oP 'Charging|Discharging')

    # Send notifications only if battery status changes
    if [ "$battery_level" != "$prev_battery_level" ]; then
        # Notify if battery is decreasing below 25%, 15%, 10%, or 5%
        if [ $battery_level -le 25 ] && [ $battery_level -gt 15 ] || [ $battery_level -eq 15 ] || [ $battery_level -eq 10 ] || [ $battery_level -eq 5 ]; then
            notify-send "Low battery level" "Your current battery level is at $battery_level%. Connect your charger." -u critical -i "battery-low" -t 5000 -r 778
        fi

        prev_battery_level=$battery_level  # Update previous battery level
    fi

    # Notify if device changes charging status
    if [ "$battery_charging" == "Charging" ] && [ "$prev_battery_charging" != "Charging" ]; then
        notify-send "Charging" "$battery_level% of battery charged." -u low -i "battery-charging" -t 5000 -r 777
    elif [ "$battery_charging" == "Discharging" ] && [ "$prev_battery_charging" == "Charging" ]; then
        notify-send "Discharging" "$battery_level% of battery remaining." -u low -i "battery-full-charged" -t 5000 -r 777
    elif [ "$battery_charging" == "Discharging" ] && [ "$prev_battery_charging" != "Discharging" ]; then
        notify-send "Discharging" "$battery_level% of battery remaining." -u low -i "battery-low" -t 5000 -r 777
    fi

    # Save current charging status for next check
    prev_battery_charging=$battery_charging
}


check_systemd_service() {
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "  [${GREEN}RUNNING${NC}] $SERVICE_NAME is running."
    else
        echo -e "  [${RED}NOT RUNNING${NC}] $SERVICE_NAME is not running."
    fi

    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        echo -e "  [${GREEN}ENABLED${NC}] $SERVICE_NAME is enabled for auto-start."
    else
        echo -e "  [${RED}NOT ENABLED${NC}] $SERVICE_NAME is not enabled for auto-start."
    fi
}

check_script_execution() {
    if pgrep -f "$SCRIPT_NAME" >/dev/null; then
        echo -e "  [${GREEN}RUNNING${NC}] $SCRIPT_NAME is running."
    else
        echo -e "  [${RED}NOT RUNNING${NC}] $SCRIPT_NAME is not running."
    fi
}

show_status() {
    echo -e "Status of $SCRIPT_NAME:\n"
    echo "Dependencies:"
    for dep in "${DEPENDENCIES[@]}"; do
        if command -v "$dep" &>/dev/null; then
            echo -e "  [${GREEN}INSTALLED${NC}] $dep"
        else
            echo -e "  [${RED}MISSING${NC}] $dep"
        fi
    done
    echo ""
    echo "Systemd Service:"
    check_systemd_service
    echo ""
    echo "Script Execution:"
    check_script_execution
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -r|--run)
            run_battery_monitor
            exit 0
            ;;
        -t|--start)
            start_service
            exit 0
            ;;
        -up|--update)
            update_script
            exit 0
            ;;
        -u|--uninstall)
            uninstall_service
            exit 0
            ;;
        -c|--check)
            check_dependencies
            exit 0
            ;;
        -s|--status)
            show_status
            exit 0
            ;;
        -i|--install)
            install_service
            exit 0
            ;;
        *)
            echo "Error: Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

show_help
exit 0
