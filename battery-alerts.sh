#!/bin/bash

# Variables
SCRIPT_NAME="battery-alerts"
DEPENDENCIES=("acpi" "notify-send")
SERVICE_NAME="battery-alerts.service"
SYSTEMD_PATH="/etc/systemd/system/$SERVICE_NAME"

# Constants for colored output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

show_help() {
    cat << EOF
Usage: ${SCRIPT_NAME} [options]
    
Options:
  -h, --help      Show this help message and exit
  -r, --run       Start ${SCRIPT_NAME} systemd service
  -u, --uninstall Uninstall ${SCRIPT_NAME} and systemd service
  -v, --update    Update ${SCRIPT_NAME} from GitHub
  -c, --check     Check dependencies
  -s, --status    Show status of dependencies, systemd service, and execution
EOF
}

print_message() {
    local type=$1
    local message=$2
    local color

    case ${type} in
        "error") color=${RED} ;;
        "success") color=${GREEN} ;;
        "warning") color=${YELLOW} ;;
    esac

    echo -e "[${color}${type^^}${NC}] ${message}"
}

check_dependencies() {
    echo "Checking dependencies..."
    for dep in "${DEPENDENCIES[@]}"; do
        if command -v "${dep}" &> /dev/null; then
            print_message "success" "${dep} is installed."
        else
            print_message "error" "${dep} is not installed. You can install it using: sudo apt-get install -y ${dep}"
        fi
    done
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

check_battery_status() {
    battery_info=$(acpi)
    battery_level=$(echo "$battery_info" | grep -oP '\d+(?=%)')
    battery_charging=$(echo "$battery_info" | grep -oP 'Charging|Discharging')

    # Send notifications only if battery status changes
    if [ "$battery_level" != "$prev_battery_level" ]; then
        # Notify if battery is decreasing below 25%, 15%, 10%, or 5% and battery is not charging
        if [ "$battery_charging" != "Charging" ] && ([ $battery_level -le 25 ] && [ $battery_level -gt 15 ] || [ $battery_level -eq 15 ] || [ $battery_level -eq 10 ] || [ $battery_level -eq 5 ]); then
            # Check if notification for this range has already been sent
            if [ "${battery_low_notified[$battery_level]}" != "true" ]; then
                notify-send "Low battery level" "Your current battery level is at $battery_level%. Connect your charger." -u critical -i "battery-low" -t 5000 -r 778
                battery_low_notified[$battery_level]="true"
            fi
        else
            # Reset notification flag for this range
            unset battery_low_notified[$battery_level]
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


run_monitor() {
    print_message "info" "Running battery monitor..."

    prev_battery_level=""
    prev_battery_charging=""

    while true; do
        check_battery_status
        sleep 1
    done
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

uninstall_service() {
    echo "Uninstalling $SCRIPT_NAME..."

    # Check if the systemd service is installed
    if systemctl is-enabled --quiet $SERVICE_NAME; then
        # Stop the service if it's running
        if systemctl is-active --quiet $SERVICE_NAME; then
            sudo systemctl stop $SERVICE_NAME
        fi

        sudo systemctl disable $SERVICE_NAME
        sudo rm $SYSTEMD_PATH
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
    SCRIPT_NAME="/usr/bin/battery-alerts"
    if [ ! -f "$SCRIPT_NAME" ]; then
        echo "The script $SCRIPT_NAME is not installed on the system. Please install it before trying to update."
        exit 1
    fi

    echo "Updating $SCRIPT_NAME from GitHub..."
    temp_dir=$(mktemp -d)
    git clone https://github.com/Joansitoh/battery-alerts.git "$temp_dir" &>/dev/null
    if cmp -s "$SCRIPT_NAME" "$temp_dir/installer.sh"; then
        echo -e "[${GREEN}SUCCESS${NC}] $SCRIPT_NAME is up to date."
    else
        sudo mv "$temp_dir/installer.sh" "$SCRIPT_NAME"
        sudo chmod +x "$SCRIPT_NAME"
        echo -e "[${GREEN}SUCCESS${NC}] $SCRIPT_NAME has been successfully updated."
    fi
    rm -rf "$temp_dir"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t) run_monitor; exit 0 ;;
        -h|--help) show_help; exit 0 ;;
        -r|--run) start_service; exit 0 ;;
        -v|--update) update_script; exit 0 ;;
        -u|--uninstall) uninstall_service; exit 0 ;;
        -c|--check) check_dependencies; exit 0 ;;
        -s|--status) show_status; exit 0 ;;
        -i|--install) install_service; exit 0 ;;
        *)
            echo "Error: Unknown option: $1"
            show_help;
            exit 1 ;;
    esac
    shift
done

show_help
exit 0
