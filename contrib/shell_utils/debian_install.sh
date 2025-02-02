#!/usr/bin/env bash

# Netatalk install script for Debian Linux. May work on other flavors too.
# This script should be run from within the contrib/shell_utils directory.
# Example usage, compiling with four cores:
#   $ ./debian_install.sh -j=4
#
# By Daniel Markstedt
# Based on RsSCSI easyinstall.sh by sonique6784
# BSD 3-Clause License
# Copyright (c) 2022, Daniel Markstedt
# Copyright (c) 2020, sonique6784

set -e

USER=$(whoami)
BASE=$(dirname "$(readlink -f "${0}")")
AFP_SHARE_NAME="Netatalk File Server"
AFP_SHARE_PATH="$HOME/afpshare"
SYSCONFDIR="/etc"

# checks to run before installation
function initialChecks() {
    if [ "root" == "$USER" ]; then
        echo "Do not run this script as $USER or with 'sudo'."
        exit 1
    fi
    echo "Netatalk install script for Debian Linux. May work on other flavors too."
    echo "It attempts to set up a universally compatible AFP server:"
    echo " - Classic AppleTalk (DDP) support enabled"
    echo " - TCP/IP (DSI) support and service discovery with Zeroconf / Bonjour enabled"
    echo " - Cleartxt UAM to authenticate Classic Mac OS clients"
    echo " - DHX2 UAM to authenticate Mac OS X / macOS clients"
    echo " - Sharing $AFP_SHARE_PATH as $AFP_SHARE_NAME"
    echo ""
    echo "The following changes will be made to your system:"
    echo " - Modify user groups and permissions"
    echo " - Install packages with apt-get"
    echo " - Add and modify systemd services"
    echo " - Create a directory in the current user's home directory where shared files will be stored"
    echo " - Install binaries to /usr/local/sbin"
    echo " - Install manpages to /usr/local/share/man"
    echo " - Install configuration files to /etc"
    echo " - Install the CUPS printing system and modify its configuration"
    echo ""
    echo "Input your password to allow this script to make the above changes."
    sudo -v
}

function installNetatalk() {
    echo ""
    echo "Checking for previous versions of Netatalk..."
    sudo systemctl stop atalkd afpd || true

    if [ -f /etc/init.d/netatalk ]; then
        echo ""
        echo "WARNING: Legacy init scripts for a previous version of Netatalk was detected on your system. It is recommended to back up you configuration files and shared files before proceeding. Press CTRL-C to exit, or any other key to proceed."
        read
        sudo /etc/init.d/netatalk stop || true
    fi

    if [ -f /var/log/afpd.log ]; then
        echo "Cleaning up /var/log/afpd.log..."
        sudo rm /var/log/afpd.log
    fi

    if [[ `grep -c netatalk /etc/rc.local` -eq 1 ]]; then
        sudo sed -i "/netatalk/d" /etc/rc.local
        echo "Removed Netatalk from /etc/rc.local -- use systemctl to control Netatalk from now on."
    fi

    if [ -d "$AFP_SHARE_PATH" ]; then
        echo "Found a $AFP_SHARE_PATH directory; will use it for file sharing."
    else
        echo "Creating the $AFP_SHARE_PATH directory and granting read/write permissions to all users..."
        sudo mkdir -p "$AFP_SHARE_PATH"
        sudo chown -R "$USER:$USER" "$AFP_SHARE_PATH"
        chmod -R 2775 "$AFP_SHARE_PATH"
    fi

    echo ""
    echo "Installing dependencies..."
    sudo apt-get update || true
    sudo apt-get install libssl-dev libdb-dev libcups2-dev cups libavahi-client-dev autotools-dev automake libtool libgcrypt20-dev pkg-config --assume-yes </dev/null

    echo ""
    echo "Bootstrapping and configuring Netatalk..."
    cd "$BASE/../.." || exit 1
    ./bootstrap </dev/null
    ./configure --enable-systemd --enable-overwrite --sysconfdir="$SYSCONFDIR" --with-uams-path=/usr/lib/netatalk </dev/null

    echo ""
    echo "Compiling Netatalk with ${CORES:-1} simultaneous core(s)..."
    ( make clean && make all -j "${CORES:-1}" ) </dev/null

    sudo make install </dev/null

    if [[ `lsmod | grep -c appletalk` -eq 0 ]]; then
        echo ""
        echo "Your system may not have support for AppleTalk networking."
	echo "You can still use Netatalk with Macs that support AppleTalk over TCP/IP (DSI)."
        echo "In the Chooser, input the IP address of the network interface that is connected to the rest of your network:"
        echo `ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}'`
    fi

    echo ""
    echo "Modifying service configurations..."
    echo "AppleVolumes.default:"
    sudo sed -i /^~/d "$SYSCONFDIR/netatalk/AppleVolumes.default"
    echo "$AFP_SHARE_PATH \"$AFP_SHARE_NAME\"" | sudo tee -a "$SYSCONFDIR/netatalk/AppleVolumes.default"
    echo "afpd.conf:"
    echo "- -transall -uamlist uams_guest.so,uams_clrtxt.so,uams_dhx2.so -nosavepassword -noicon" | sudo tee -a "$SYSCONFDIR/netatalk/afpd.conf"
    echo "papd.conf:"
    echo "cupsautoadd:op=root:" | sudo tee -a "$SYSCONFDIR/netatalk/papd.conf"
    sudo usermod -a -G lpadmin $USER
    sudo cupsctl --remote-admin WebInterface=yes
    if [[ `sudo grep "PreserveJobHistory" /etc/cups/cupsd.conf` -eq 0 ]]; then
        echo "cupsd.conf:"
        sudo sed -i "/MaxLogSize/a PreserveJobHistory\ No" /etc/cups/cupsd.conf
    fi

    echo ""
    echo "Starting systemd services... (this may take a while)"
    sudo systemctl start afpd atalkd papd timelord a2boot cups

    echo ""
    echo "Netatalk daemons are now installed and running, and should be discoverable by your Macs."
    echo "To authenticate with the file server, use the current username ("$USER") and password."
    echo ""
    echo "IMPORTANT: "$USER" needs to have a password of 8 chars or less due to Classic Mac OS limitations."
    echo "Do you want to change your password now? [y/N]"
    read -r REPLY
    if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
        passwd
    fi
    echo ""
    echo "For more information on how to use the various Netatalk features, see README.md"
    echo "Enjoy Netatalk!"
    echo ""
}

# parse arguments passed to the script
while [ "$1" != "" ]; do
    PARAM=$(echo "$1" | awk -F= '{print $1}')
    VALUE=$(echo "$1" | awk -F= '{print $2}')
    case $PARAM in
        -j | --cores)
            CORES=$VALUE
            ;;
        -n | --share-name)
            AFP_SHARE_NAME=$VALUE
            ;;
        -p | --share-path)
            AFP_SHARE_PATH=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            exit 1
            ;;
    esac
    shift
done

initialChecks
installNetatalk
exit 0
