#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    clear
    echo "You should run this script with root!"
    echo "Use sudo -i to change user to root"
    exit 1
fi

function block_ips {
    clear
    if ! command -v iptables &> /dev/null; then
        apt-get update
        apt-get install -y iptables
    fi
    if ! dpkg -s iptables-persistent &> /dev/null; then
        apt-get update
        apt-get install -y iptables-persistent
    fi

    if ! iptables -L abuse-defender -n >/dev/null 2>&1; then
        iptables -N abuse-defender
    fi

    if ! iptables -L OUTPUT -n | grep -q "abuse-defender"; then
        iptables -I OUTPUT -j abuse-defender
    fi

    iptables -F abuse-defender

    IP_LIST=$(curl -s 'https://raw.githubusercontent.com/desprdo/hetzner_cloud-init/main/abuse-ip-list.ipv4')

    if [ $? -ne 0 ]; then
        echo "Failed to fetch the IP-Ranges list"
        exit 1
    fi

    for IP in $IP_LIST; do
        iptables -A abuse-defender -d $IP -j DROP
    done

    iptables-save > /etc/iptables/rules.v4

    clear
    echo "Abuse IP-Ranges blocked successfully."
}

function block_torrent {
    clear
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/090ebier/torrent-blocking-script/main/block_torrent.sh)"
    clear
    echo "Torrent blocked successfully."
}

block_ips
block_torrent
