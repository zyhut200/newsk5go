#!/usr/bin/env bash

# Ensure the script is being run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Variables
PORT=11688
USER="10010"
PASSWORD="10010"

# Check if the OS is supported
if ! [ -e /etc/redhat-release ] && ! [ -e /etc/debian_version ]; then
    echo "This script is only supported on CentOS, Debian, and Ubuntu"
    exit 1
fi

# Function to install necessary dependencies
install_dependencies() {
    if [[ -e /etc/redhat-release ]]; then
        yum install -y wget unzip
        if ! command -v wget &>/dev/null || ! command -v unzip &>/dev/null; then
            echo "Failed to install dependencies"
            exit 1
        fi
    elif [[ -e /etc/debian_version ]]; then
        apt update && apt install -y wget unzip
        if ! command -v wget &>/dev/null || ! command -v unzip &>/dev/null; then
            echo "Failed to install dependencies"
            exit 1
        fi
    fi
}

# Function to install Xray
install_xray() {
    wget -O /usr/local/bin/xray https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
    if [ $? -ne 0 ]; then
        echo "Failed to download Xray"
        exit 1
    fi
    unzip /usr/local/bin/xray -d /usr/local/bin/
    chmod +x /usr/local/bin/xray
}

# Function to configure Xray as a SOCKS5 proxy
configure_xray() {
    mkdir -p /etc/xray
    cat << EOF > /etc/xray/config.json
{
    "inbounds": [
        {
            "port": $PORT,
            "protocol": "socks",
            "settings": {
                "auth": "password",
                "accounts": [
                    {
                        "user": "$USER",
                        "pass": "$PASSWORD"
                    }
                ],
                "udp": true
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        }
    ]
}
EOF
    if [ $? -ne 0 ]; then
        echo "Failed to write the configuration file for Xray"
        exit 1
    fi
}

# Function to create a systemd service for Xray
create_service() {
    cat << EOF > /etc/systemd/system/xray.service
[Unit]
Description=Xray - A unified platform for anti-censorship
Documentation=https://xtls.github.io

[Service]
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartSec=5
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable xray
    systemctl start xray
    if ! systemctl is-active --quiet xray; then
        echo "Failed to start the Xray service"
        exit 1
    fi
}

# Main function to orchestrate the installation
main() {
    install_dependencies
    install_xray
    configure_xray
    create_service

    echo "Xray SOCKS5 has been installed."
    echo "IP: $(curl -s ifconfig.me)"
    echo "Port: $PORT"
    echo "User: $USER"
    echo "Password: $PASSWORD"
}

main
