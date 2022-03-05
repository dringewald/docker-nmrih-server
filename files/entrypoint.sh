#!/bin/bash

# Tell APT to run without interaction
DEBIAN_FRONTEND=noninteractive
DEBCONF_NONINTERACTIVE_SEEN=true
DEBIAN_PRIORITY=critical

# Update packages at the start of the image to ensure that they are uptodate
if [ -z "$UPDATEPACKAGES" ]; then
	if [ "$UPDATEPACKAGES" = "true" ] || [ "$UPDATEPACKAGES" = "1" ]; then	
		apt-get -qy update
		apt-get -qy full-upgrade
	fi
fi

# Check if Keyfiles are directories and remove them when necessary (could happen when mounted the first time with some Kubernetes-Storages)
if [ -d /etc/ssh/ssh_host_ed25519_key ]; then
	rm -vR /etc/ssh/ssh_host_ed25519_key
fi
if [ -d /etc/ssh/ssh_host_rsa_key ]; then
	rm -vR /etc/ssh/ssh_host_rsa_key
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
if [ -z "$USERPWD" ]; then
	if [ "$USERPWD" = "true" ] || [ "$USERPWD" = "1" ]; then	
		(echo "${USERPWD}"; echo "${USERPWD}") | passwd nmrih
		passwd -u nmrih
	fi
fi

# Install the Game if it's not found
if [ ! -d /home/nmrih/server ]; then
	steamcmd +login anonymous +force_install_dir /home/nmrih/server +app_update 317670 validate +quit
fi

# Update the Game
if [ -z "$UPDATECHECK" ]; then
	if [ "$UPDATECHECK" = "true" ] || [ "$UPDATECHECK" = "1" ]; then
		steamcmd +login anonymous +force_install_dir /home/nmrih/server +app_update 317670 +quit
	fi
fi

# Validate the Game
if [ -z "$VALIDATECHECK" ]; then
	if [ "$VALIDATECHECK" = "true" ] || [ "$VALIDATECHECK" = "1" ]; then
		steamcmd +login anonymous +force_install_dir /home/nmrih/server +app_update 317670 validate +quit
	fi
fi

# Change Ownership of files whenever the container starts
if [ -z "$CHECKPERMS" ]; then
	if [ "$CHECKPERMS" = "true" ] || [ "$CHECKPERMS" = "1" ]; then
		chown -vR nmrih.nmrih /home/nmrih
		chmod -vR 0770 /home/nmrih
	fi
fi

# Change Ownership of Pubkey
chown -vR nmrih.root /etc/ssh/keyfiles

# Change permissions of Pubkey
chmod -v 0770 /etc/ssh/keyfiles
chmod -vR 0660 /etc/ssh/keyfiles/*

# Starting up everything
sleep 3600