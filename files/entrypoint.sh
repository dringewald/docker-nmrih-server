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

# Making sure to preserve env for the nmrih-user for the nmrih variables
if [[ $(grep -L "NMRIH_UPDATEPACKAGES" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_UPDATEPACKAGES\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_USERPWD" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_USERPWD\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_UPDATECHECK" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_UPDATECHECK\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_VALIDATECHECK" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_VALIDATECHECK\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_SETPERMS" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_SETPERMS\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_RCONPW" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_RCONPW\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_PW" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_PW\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_CLIENT_PORT" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_CLIENT_PORT\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_PORT" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_PORT\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_TV_PORT" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_TV_PORT\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_IP_ADDRESS" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_IP_ADDRESS\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_NET_PUBLIC_ADDRESS" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_NET_PUBLIC_ADDRESS\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_MAXPLAYERS" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_MAXPLAYERS\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_STARTMAP" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_STARTMAP\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_REGION" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_REGION\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_TOKEN" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_TOKEN\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_AUTH_KEY" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_AUTH_KEY\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_CONFIG_FILE" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_CONFIG_FILE\"" >> /etc/sudoers
fi
if [[ $(grep -L "NMRIH_ADDITIONAL_ARGS" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_ADDITIONAL_ARGS\"" >> /etc/sudoers
fi

# Run the game as nmrih user
sudo -i -u nmrih /opt/nmrih/startgame.sh
