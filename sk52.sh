#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

install_dante_debian() {
    apt update
    apt install -y dante-server
}

install_dante_centos() {
    yum install -y epel-release
    yum install -y dante-server
}

if [ -f /etc/debian_version ]; then
    install_dante_debian
elif [ -f /etc/redhat-release ]; then
    install_dante_centos
else
    echo "Unsupported operating system"
    exit 1
fi

cat > /etc/danted.conf <<EOL
logoutput: syslog
internal: 0.0.0.0 port = 11688
external: eth0
socksmethod: username
user.privileged: root
user.notprivileged: nobody
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error connect disconnect
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error connect disconnect
}
EOL

useradd -m 10010
echo "10010:10010" | chpasswd

if [ -f /etc/debian_version ]; then
    systemctl enable danted
    systemctl start danted
elif [ -f /etc/redhat-release ]; then
    systemctl enable danted
    systemctl start danted
fi

echo "Dante SOCKS5 server is installed and running on port 11688 with username and password as 10010"
