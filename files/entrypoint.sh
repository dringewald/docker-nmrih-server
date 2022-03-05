#!/bin/bash

# Tell APT to run without interaction
DEBIAN_FRONTEND=noninteractive
DEBCONF_NONINTERACTIVE_SEEN=true
DEBIAN_PRIORITY=critical

# Update packages at the start of the image to ensure that they are uptodate
if [ -z "$UPDATE_PACKES" ]; then
	apt-get -qy update
	apt-get -qy full-upgrade
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

(echo "${FTPPWD}"; echo "${FTPPWD}") | passwd www-data
passwd -u www-data

# Change Ownership of files whenever the container starts
chown -vR www-data.www-data /etc/nginx/ssl/

# Change Permissions of files whenever the container starts
chmod -vR 0770 /etc/nginx/ssl/

# Change Ownership of Pubkey
chown -vR www-data.root /etc/ssh/keyfiles

# Change permissions of Pubkey
chmod -v 0770 /etc/ssh/keyfiles
chmod -vR 0660 /etc/ssh/keyfiles/*

# Starting up everything
echo "------------------------"
/usr/sbin/service php7.4-fpm restart
echo "------------------------"
/usr/sbin/service php8.0-fpm restart
echo "------------------------"
/usr/sbin/service ssh restart
echo "------------------------"
/usr/sbin/nginx -g "daemon off;"
