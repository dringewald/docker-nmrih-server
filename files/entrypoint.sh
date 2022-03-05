#!/bin/bash

# Tell APT to run without interaction
DEBIAN_FRONTEND=noninteractive
DEBCONF_NONINTERACTIVE_SEEN=true
DEBIAN_PRIORITY=critical

# Update packages at the start of the image to ensure that they are uptodate
if [ ! -z "$UPDATEPACKAGES" ]; then
	if [[ "$UPDATEPACKAGES" = "true" || "$UPDATEPACKAGES" = "1" ]]; then	
		apt-get -qy update
		apt-get -qy full-upgrade
	fi
fi

# Check if Keyfiles are directories and remove them when necessary (could happen when mounted the first time with some Kubernetes-Storages)
if [ -d /etc/ssh/ssh_host_ed25519_key ]; then
	rm -vfR /etc/ssh/ssh_host_ed25519_key
fi
if [ -d /etc/ssh/ssh_host_rsa_key ]; then
	rm -vfR /etc/ssh/ssh_host_rsa_key
fi

# Generate unique ssh keys for this container (if they are not found)
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
	ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
fi
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
	ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ''
fi

# Restrict access from other users
chmod 600 /etc/ssh/ssh_host_ed25519_key
chmod 600 /etc/ssh/ssh_host_rsa_key

# Show Keyfile Permission in Log
ls -hali /etc/ssh/ssh_host_ed25519_key
ls -hali /etc/ssh/ssh_host_rsa_key

# Add Trusted SSH-Keyfile to Keyfiles
echo "" >> /etc/ssh/sshd_config
echo "AuthorizedKeysFile /etc/ssh/keyfiles/id_ed25519.pub" >> /etc/ssh/sshd_config

# Check if a User-PW is set
if [ -z "$NMRIH_USERPWD" ]; 
then
	export NMRIH_USERPWD=asaferandomstring
	(echo "${NMRIH_USERPWD}"; echo "${NMRIH_USERPWD}") | passwd nmrih
	passwd -u nmrih
else
	(echo "${NMRIH_USERPWD}"; echo "${NMRIH_USERPWD}") | passwd nmrih
	passwd -u nmrih
fi

# Check if steamcmd-Folder is empty and delete it for proper access
if [ -d /home/nmrih/steamcmd ]; then
	if [ ! "$(ls -A /home/nmrih/steamcmd)" ]; then
		rm -vR /home/nmrih/steamcmd
	fi
fi

# Check if server-Folder is empty and delete it for proper access
if [ -d /home/nmrih/server ]; then
	if [[ ! "$(ls -A /home/nmrih/server)" && ! -d /home/nmrih/server/nmrih ]]; then
		rm -vR /home/nmrih/server
	fi
fi

# Change Ownership of Pubkey
chown -vR nmrih:root /etc/ssh/keyfiles

# Change permissions of Pubkey
chmod -v 0770 /etc/ssh/keyfiles
chmod -vR 0660 /etc/ssh/keyfiles/*

# Run some commands as nmrih user
sudo -i -u nmrih /opt/nmrih/nmrih-setup.sh

# Last but not Least run Permission Check as root to set correct permissions
# Change Ownership of files whenever the container starts
if [ -z "$NMRIH_SETPERMS" ]; 
then
	chown -vR nmrih:nmrih /home/nmrih
	chmod -vR 0770 /home/nmrih
else
	if [[ "$NMRIH_SETPERMS" = "true" || "$NMRIH_SETPERMS" = "1" ]]; then
		chown -vR nmrih:nmrih /home/nmrih
		chmod -vR 0770 /home/nmrih
	fi
fi

# Check if Variables are empty
if [ -z "$NMRIH_NET_PUBLIC_ADDRESS" ]; then
	export NMRIH_NET_PUBLIC_ADDRESS="0.0.0.0"
fi

if [ -z "$NMRIH_CLIENT_PORT" ]; then
	export NMRIH_CLIENT_PORT="27010"
fi

if [ -z "$NMRIH_PORT" ]; then
	export NMRIH_PORT="27015"
fi

if [ -z "$NMRIH_TV_PORT" ]; then
	export NMRIH_TV_PORT="27020"
fi

if [ -z "$NMRIH_STARTMAP" ]; then
	export NMRIH_STARTMAP="nmo_cabin"
fi

if [ -z "$NMRIH_CONFIG_FILE" ]; then
	export NMRIH_CONFIG_FILE="server.cfg"
fi

if [ -z "$NMRIH_MAXPLAYERS" ]; then
	export NMRIH_MAXPLAYERS="8"
fi

if [ -z "$NMRIH_REGION" ]; then
	export NMRIH_REGION="3"
fi

if [ -z "$NMRIH_NET_PUBLIC_ADDRESS" ]; then
	export NMRIH_NET_PUBLIC_ADDRESS="0.0.0.0"
fi

echo "Start up the Server"
echo "-------------------"
sudo -i -u nmrih /home/nmrih/server/srcds_run \
	-game nmrih \
	-insecure \
	-strictportbind \
	-ip $NMRIH_NET_PUBLIC_ADDRESS \
	-port $NMRIH_PORT \
	+clientport $NMRIH_CLIENT_PORT \
	+tv_port $NMRIH_TV_PORT \
	+map $NMRIH_STARTMAP \
	+servercfgfile $NMRIH_CONFIG_FILE \
	-maxplayers $NMRIH_MAXPLAYERS \
	+sv_region $NMRIH_REGION \
	+net_public_adr $NMRIH_NET_PUBLIC_ADDRESS \
	-authkey $NMRIH_AUTH_KEY \
	+sv_setsteamaccount $NMRIH_TOKEN \
	$NMRIH_ADDITIONAL_ARGS