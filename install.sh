#!/bin/bash

set -e

CONF_DIR="${TARGET_CONF_DIR:-/etc/vmnet}"
BIN_DIR="${TARGET_BIN_DIR:-/usr/local/bin}"
BIN_NAME="${TARGET_BIN_NAME:-vmnetctl}"
LOG_DIR="${TARGET_LOG_DIR:-/var/log/vmnet}"
SYSTEMD_DIR="/etc/systemd/system"

function print_note() {
    echo "This purpose of this package is to replace libvirt's native network controls. Although they typically work great, I experienced multiple issues with dnsmasq. In order to use dhcpcd for dhcp, I wrote these custom systemd files and a small script (vmnetctl) to manage them. Eventually I decided to post them on github. You should only use this package if necessity compels it. Even then, I recommend reviewing all files and ensure that they suit your needs. They basically just create a nat network. Nothing special. Chances are these scripts/services are worthless to you, but I had fun writing them so enjoy!"
    echo ""
    echo "I also included an example 'net' configuration you can use in the example directory"
}
function print_dependencies() {
    echo "This package has the following dependencies. Please make sure they are installed to avoid unwanted behavior."
    echo "Dependencies:"
    echo "    - dhcpcd"
    echo "    - dnsmasq"
    echo "    - ip (iproute2)"
    echo "    - brctl"
    echo "    - firewalld"
    echo ""
    echo "Note! The systemd files use absolute paths! Please update the files to ensure that the paths match the dependencies. For example, you should ensure that the paths to dhcpcd and dnsmasq are correct in vmdhcp and vmdns"
}
function print_usage() {
    echo "Usage: [FOO=BAR] install.sh [command] (install, help)"
    echo ""
    echo "Current Environment:"
    echo "    TARGET_CONF_DIR=$CONF_DIR"
    echo "    TARGET_BIN=$BIN_DIR"
    echo "    TARGET_BIN_NAME=$BIN_NAME"
    echo "    TARGET_LOG_DIR=$LOG_DIR"
    echo ""
    echo "Note! If the environment is customized, the systemd files and vmnetctl script must be updated!"

    echo ""
    print_dependencies
    echo ""
    print_note
}

if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
    print_usage
    exit $?
fi

if (( $EUID != 0 )); then
    print_usage
    echo ""
    echo "[!] Please run as root"
    exit 1
fi

if [[ ! -f "./vmnetctl" ]]; then
    echo "[!] Please run in the project directory with the 'vmnetctl' file!"
    echo "[!] Aborting..."
    exit 1
fi

if [[ ! -d "./template" ]]; then
    echo "[!] Please run in the project directory with the 'template' directory!"
    echo "[!] Aborting..."
    exit 1
fi

function congrats_message() {
    echo "Congrats! It's all installed and what not. But as of now, it's pretty useless. You need to customize your networks"
    echo "You can start by copying the 'example' folder to $CONF_DIR/networks/virbr0"
    echo "If you want a more bare bones template you can review the template directory. All networks need to go in the $CONF_DIR/networks/."
    echo ""
    echo "If you have vpn running on your host. You may experience problems. You can fix this by adding the vpn's interface (like tun0) to the external zone with 'firewall-cmd --zone=external --add-interface=tun0'."
    echo "You'll probably want to add your main LAN to the same zone anyways. You can do this by running 'firewall-cmd --zone=external --add-interface=eth0'. This takes care of masquerading."
    echo ""
    echo "Remember, it's your network so don't be afraid to configure it how you want."
    echo "This package was inspired by this post: https://jamielinux.com/docs/libvirt-networking-handbook/custom-nat-based-network.html"
}
function cp_service() {
    name="$1"
    service_name="$name@.service"
    if [[ -f "$SYSTEMD_DIR/$service_name" ]]; then
        echo "[!] Systemd file $SYSTEMD_DIR/$service_name exists! Overwriting!"
    fi
    echo "[*] Copying $service_name to $SYSTEMD_DIR/$service_name"
    cp "./systemd/$service_name" $SYSTEMD_DIR/$service_name
}

function install () {
    print_dependencies
    echo ""
    if [[ ! -d "$BIN_DIR" ]]; then
        echo "[*] Making $BIN_DIR"
        mkdir -p "$BIN_DIR"
    fi

    if [[ -f "$BIN_DIR/$BIN_NAME" ]]; then
        echo "[!] The $BIN_DIR/$BIN_NAME file exists! Overwriting!"
    fi

    echo "[*] Copying vmnetctl to $BIN_DIR/$BIN_NAME"
    cp "./vmnetctl" "$BIN_DIR/$BIN_NAME"
    chmod +x "$BIN_DIR/$BIN_NAME"

    if [[ -d "$CONF_DIR" ]]; then
        echo "[!] The $CONF_DIR directory exists! Some files may be overwritten. Already configured networks will be untouched but may need to be updated!"
    else
        echo "[*] Making $CONF_DIR"
        mkdir -p "$CONF_DIR"
    fi

    if [[ ! -d "$CONF_DIR/networks" ]]; then
        echo "[*] Making $CONF_DIR/networks"
        echo "[*] This is where your configurations go! Reference 'template' and 'example' to get started"
        mkdir "$CONF_DIR/networks"
    fi

    if [[ -d "$CONF_DIR/template" ]]; then
        echo "[!] Template directory exists! Overwriting!"
    fi
    echo "[*] Copying template directory to $CONF_DIR/template"
    echo "[*] The template directory may be used in the future to automate setting up new networks. As of now it serves as a reference. You can also check the example directory."

    cp -r "./template" "$CONF_DIR/template"

    if [[ ! -d "$LOG_DIR" ]]; then
        echo "[*] Making $LOG_DIR"
    fi

    if [[ -f "$SYSTEMD_DIR/vmfwzones.service" ]]; then
        echo "[!] Systemd file $SYSTEMD_DIR/vmfwzones.service exists! Overwriting!"
    fi
    echo "[*] Copying vmfwzones.service to $SYSTEMD_DIR/vmfwzones.service"
    cp "./systemd/vmfwzones.service" "$SYSTEMD_DIR/vmfwzones.service"

    cp_service "vmnet"
    cp_service "vmdhcp"
    cp_service "vmdns"
    cp_service "vmfw"
    echo "[*] Reloading Systemd"
    systemctl daemon-reload
    echo ""
    congrats_message
}

if [[ "$1" == "install" || "$1" == "-i" || "$1" == "--install" ]]; then
    install
else
    print_usage
    echo ""
    echo "[!] Incorrect command given!"
    exit 1
fi
