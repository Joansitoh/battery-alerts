#!/bin/bash

# Variables
SCRIPT_NAME="battery-alerts"
SERVICE_NAME="battery-alerts.service"
SYSTEMD_PATH="/etc/systemd/system/$SERVICE_NAME"

# Constants for colored output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

install_service() {
    echo "Installing $SCRIPT_NAME..."

    # Verificar si el script ya está en /usr/bin
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

    # Mover el script a /usr/bin
    read -p "Do you want to move the script to /usr/bin for easy execution? (y/n) " move_script
    if [[ $move_script == "y" || $move_script == "Y" ]]; then
        if [[ -f ./battery-alerts.sh ]]; then
            sudo cp ./battery-alerts.sh /usr/bin/$SCRIPT_NAME
            echo -e "[${GREEN}SUCCESS${NC}] Script moved to /usr/bin."
        else
            echo -e "[${RED}ERROR${NC}] The file battery-alerts.sh does not exist in the current directory."
            exit 1
        fi
    fi

    # Añadir alias a .bashrc
    read -p "Do you want to add an alias for the command in .bashrc? (y/n) " add_alias
    if [[ $add_alias == "y" || $add_alias == "Y" ]]; then
        echo "alias $SCRIPT_NAME='/usr/bin/$SCRIPT_NAME'" >> ~/.bashrc
        source ~/.bashrc
        echo -e "[${GREEN}SUCCESS${NC}] Alias added to .bashrc."
    fi

    # Instalar servicio systemd
    read -p "Do you want to install the systemd service? (y/n) " install_service
    if [[ $install_service == "y" || $install_service == "Y" ]]; then
        # Crear archivo de servicio systemd
        cat << EOF > $SERVICE_NAME
[Unit]
Description=Battery Monitor Service
After=network.target

[Service]
ExecStart=/usr/bin/$SCRIPT_NAME -t
Restart=always
User=$USER
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/$USER/.Xauthority

[Install]
WantedBy=multi-user.target
EOF

        # Mover el archivo de servicio al lugar correcto
        sudo mv $SERVICE_NAME $SYSTEMD_PATH

        # Recargar systemd, habilitar y iniciar el servicio
        sudo systemctl daemon-reload
        sudo systemctl enable $SERVICE_NAME
        echo -e "[${GREEN}SUCCESS${NC}] $SERVICE_NAME installed successfully."
    fi

    # Iniciar automáticamente el servicio
    read -p "Do you want to auto start the service? (y/n) " auto_start
    if [[ $auto_start == "y" || $auto_start == "Y" ]]; then
        sudo systemctl start $SERVICE_NAME
        echo -e "[${GREEN}SUCCESS${NC}] $SERVICE_NAME started successfully."
    fi
}

install_service
