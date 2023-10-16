#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

install_dependencies() {
    if [ -f /etc/debian_version ]; then
        apt update
        apt install -y build-essential git
    elif [ -f /etc/redhat-release ]; then
        yum groupinstall -y "Development Tools"
        yum install -y git
    else
        echo "Unsupported operating system"
        exit 1
    fi
}

install_3proxy() {
    git clone https://github.com/z3APA3A/3proxy.git
    cd 3proxy
    make -f Makefile.Linux
    cp src/3proxy /usr/local/bin
}

configure_3proxy() {
    cat > /etc/3proxy.cfg <<EOL
nserver 8.8.8.8
nserver 8.8.4.4
nscache 65536

users 10010:CL:10010

daemon
log /var/log/3proxy/3proxy.log D
logformat "- +_L%t.%. %N.%p %E %U %C:%c %R:%r %O %I %h %T"

auth strong
allow 10010
proxy -p3128 -i127.0.0.1 -e127.0.0.1
socks -p11688 -i0.0.0.0 -e0.0.0.0
flush
EOL

    mkdir -p /var/log/3proxy
}

create_systemd_service() {
    cat > /etc/systemd/system/3proxy.service <<EOL
[Unit]
Description=3proxy Proxy Server
After=network.target

[Service]
ExecStart=/usr/local/bin/3proxy /etc/3proxy.cfg
User=nobody
Restart=always

[Install]
WantedBy=multi-user.target
EOL

    systemctl enable 3proxy
    systemctl start 3proxy
}

install_dependencies
install_3proxy
configure_3proxy
create_systemd_service

echo "3proxy is installed and running on port 11688 with username and password as 10010"
