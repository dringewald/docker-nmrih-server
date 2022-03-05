#!/bin/bash

###################################
######## RUN AS nmrih USER ########
###################################
if [ "$EUID" -ne 1000 ]
  then echo "Please run as user \"nmrih\"!"
  exit
fi

# Download-Steamcmd
if [ ! -d /home/nmrih/steamcmd ]; then
	mkdir -p /home/nmrih/steamcmd
	cd /home/nmrih/steamcmd
	curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
	mv -v steamcmd.sh steamcmd
	export PATH=$PATH:/home/nmrih/steamcmd
fi

# Update Steamcmd
if [ -z "$NMRIH_STEAMCMDCHECK" ]; then
	if [[ "$NMRIH_STEAMCMDCHECK" = "true" || "$NMRIH_STEAMCMDCHECK" = "1" ]]; then
		rm -vfR /home/nmrih/steamcmd
		mkdir -p /home/nmrih/steamcmd
		cd /home/nmrih/steamcmd
		curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
		mv -v steamcmd.sh steamcmd
		export PATH=$PATH:/home/nmrih/steamcmd	
	fi
fi

# Install the Game if it's not found
if [[ ! -d /home/nmrih/server && ! -d /home/nmrih/server/nmrih ]]; then
	steamcmd +force_install_dir /home/nmrih/server +login anonymous +app_update 317670 validate +quit
fi

# Update the Game
if [ -z "$NMRIH_UPDATECHECK" ]; then
	if [[ "$NMRIH_UPDATECHECK" = "true" || "$NMRIH_UPDATECHECK" = "1" ]]; then
		steamcmd.sh  +force_install_dir /home/nmrih/server +login anonymous +app_update 317670 +quit
	fi
fi

# Validate the Game
if [ -z "$NMRIH_VALIDATECHECK" ]; then
	if [[ "$NMRIH_VALIDATECHECK" = "true" || "$NMRIH_VALIDATECHECK" = "1" ]]; then
		steamcmd +force_install_dir /home/nmrih/server +login anonymous +app_update 317670 validate +quit
	fi
fi

# Change Ownership of Pubkey
chown -vR nmrih:root /etc/ssh/keyfiles

# Change permissions of Pubkey
chmod -v 0770 /etc/ssh/keyfiles
chmod -vR 0660 /etc/ssh/keyfiles/*

# exit gracefully
exit 0