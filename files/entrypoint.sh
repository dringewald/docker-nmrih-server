#!/bin/bash

# Tell APT to run without interaction
DEBIAN_FRONTEND=noninteractive
DEBCONF_NONINTERACTIVE_SEEN=true
DEBIAN_PRIORITY=critical

# Update packages at the start of the image to ensure that they are uptodate
if [ -z "$UPDATEPACKAGES" ]; then
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
if [ -z "$NMRIH_USERPWD" ]; then	
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

# Run some commands as nmrih user
sudo -i -u nmrih /opt/nmrih/nmrih-setup.sh

# Last but not Least run Permission Check as root to set correct permissions
# Change Ownership of files whenever the container starts
if [ -z "$NMRIH_SETPERMS" ]; then
	if [[ "$NMRIH_SETPERMS" = "true" || "$NMRIH_SETPERMS" = "1" ]]; then
		chown -vR nmrih:nmrih /home/nmrih
		chmod -vR 0770 /home/nmrih
	fi
fi

echo "Sleep 3600 for testing"
sleep 3600
#sudo -i -u nmrih /home/nmrih/server/srcds_run