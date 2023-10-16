#!/usr/bin/env bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Variables
PORT=11688
USER="10010"
PASSWORD="10010"

# Update the system and install necessary packages
if [[ -e /etc/redhat-release ]]; then
    yum update -y
    yum install -y wget unzip
elif [[ -e /etc/debian_version ]]; then
    apt update -y
    apt install -y wget unzip
fi

# Install Xray
wget -O /usr/local/bin/xray https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && unzip xray-linux-64.zip xray -d /usr/local/bin/
chmod +x /usr/local/bin/xray

# Create a configuration file for Xray
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
            },
            "sniffing": {
                "enabled": true,
                "destOverride": ["http", "tls"]
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

# Create a Systemd service file for Xray
cat << EOF > /etc/systemd/system/xray.service
[Unit]
Description=Xray Service
After=network.target nss-lookup.target

[Service]
User=nobody
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# Reload the systemd daemon, enable and start the Xray service
systemctl daemon-reload
systemctl enable xray
systemctl start xray

# Output the status of the Xray service
systemctl status xray

# Output the final details for the user
echo "Xray SOCKS5 proxy is installed."
echo "IP Address: $(curl -s https://ipinfo.io/ip)"
echo "Port: $PORT"
echo "Username: $USER"
echo "Password: $PASSWORD"
