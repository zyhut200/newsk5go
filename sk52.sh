#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

install_dependencies() {
    if [ -f /etc/debian_version ]; then
        apt update
        apt install -y git gcc make
    elif [ -f /etc/redhat-release ]; then
        yum groupinstall -y "Development Tools"
        yum install -y git
    else
        echo "Unsupported operating system"
        exit 1
    fi
}

install_microsocks() {
    git clone https://github.com/rofl0r/microsocks.git
    cd microsocks
    make
    cp microsocks /usr/local/bin
}

create_systemd_service() {
    cat > /etc/systemd/system/microsocks.service <<EOL
[Unit]
Description=MicroSocks SOCKS5 Proxy
After=network.target

[Service]
ExecStart=/usr/local/bin/microsocks -1 -i 0.0.0.0 -p 11688 -u 10010 -P 10010
User=nobody
Restart=always

[Install]
WantedBy=multi-user.target
EOL

    systemctl enable microsocks
    systemctl start microsocks
}

install_dependencies
install_microsocks
create_systemd_service

echo "MicroSocks is installed and running on port 11688 with username and password as 10010"
