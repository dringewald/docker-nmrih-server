#!/bin/bash

# Tell APT to run without interaction
DEBIAN_FRONTEND=noninteractive
DEBCONF_NONINTERACTIVE_SEEN=true
DEBIAN_PRIORITY=critical
UBUNTU_VERSION=$(lsb_release -rs)

# Making sure to preserve env for the nmrih-user for the nmrih variables
if [[ $(grep -L "TZ" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"TZ\"" >> /etc/sudoers
fi
if [[ $(grep -L "ENABLESSH" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"ENABLESSH\"" >> /etc/sudoers
fi
if [[ $(grep -L "ENABLEROOT" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"ENABLEROOT\"" >> /etc/sudoers
fi
if [[ $(grep -L "ENABLEPWD" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"ENABLEPWD\"" >> /etc/sudoers
fi
if [[ $(grep -L "SSHKEY" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"SSHKEY\"" >> /etc/sudoers
fi
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
if [[ $(grep -L "NMRIH_FIXPERMS" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_FIXPERMS\"" >> /etc/sudoers
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
if [[ $(grep -L "NMRIH_DISABLEVAC" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"NMRIH_DISABLEVAC\"" >> /etc/sudoers
fi
if [[ $(grep -L "VACFLAG" /etc/sudoers) ]]; then
	echo "Defaults env_keep += \"VACFLAG\"" >> /etc/sudoers
fi

# Function to set timezone
set_timezone() {
    if [ ! -z "$TZ" ]; then
        if [ -f "/usr/share/zoneinfo/$TZ" ]; then
            ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
            echo "Timezone set to $TZ"
        else
            echo "Error: Invalid timezone '$TZ'"
            exit 1
        fi
    else
        echo "No timezone specified. Using default."
    fi
}

# Main script
if [[ "$UBUNTU_VERSION" == "24.04" ]] || [[ "$UBUNTU_VERSION" == "22.04" ]]; then
    set_timezone
else
    echo "Unsupported Ubuntu version: $UBUNTU_VERSION"
    exit 1
fi

# Update packages at the start of the image to ensure that they are uptodate
if [ ! -z "$NMRIH_UPDATEPACKAGES" ]; then
	if [[ "$NMRIH_UPDATEPACKAGES" = "true" || "$NMRIH_UPDATEPACKAGES" = "1" ]]; then
		apt-get -qy update
		apt-get -qy full-upgrade
	fi
fi

# Check if the Docker secret for NMRIH user password exists
if [ -f "/run/secrets/nmrih_userpwd" ]; then
    NMRIH_USERPWD=$(cat /run/secrets/nmrih_userpwd)
    (echo "${NMRIH_USERPWD}"; echo "${NMRIH_USERPWD}") | passwd nmrih
    passwd -u nmrih
    echo "Password for nmrih user set from Docker secret."
else
    # Check if a User-PW is set
    if [ -z "$NMRIH_USERPWD" ]; then
        NMRIH_USERPWD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16; echo)
        (echo "${NMRIH_USERPWD}"; echo "${NMRIH_USERPWD}") | passwd nmrih
        passwd -u nmrih
        echo "------------------------"
        echo ""
        echo "Default Password set to:"
        echo "${NMRIH_USERPWD}"
        echo ""
        echo "Please set a static Password to the variable NMRIH_USERPWD to stop the random generation of a password on every start of the container"
        echo ""
        echo "------------------------"
    else
        (echo "${NMRIH_USERPWD}"; echo "${NMRIH_USERPWD}") | passwd nmrih
        passwd -u nmrih
        echo "Custom Password is set via variable NMRIH_USERPWD"
    fi
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

# Last but not Least run Permission Check as root to set correct permissions
# Change Ownership of files whenever the container starts
if [ ! -z "$NMRIH_FIXPERMS" ];
then
  if [[ "$NMRIH_FIXPERMS" = "true" || "$NMRIH_FIXPERMS" = "1" ]]; then
    chown -vR nmrih:nmrih /home/nmrih /opt/nmrih
    chmod -vR 770 /home/nmrih /opt/nmrih
  fi
fi

# Run some commands as nmrih user
sudo -i -u nmrih /opt/nmrih/nmrih-setup.sh

# Start SSH if Enabled
if [ ! -z "$ENABLESSH" ];
then
  if [[ "$ENABLESSH" = "true" || "$ENABLESSH" = "1" ]]; 
  then
    # Check if host-keyfile-dir exists - else create it
    if [ ! -d "/etc/ssh/host-keyfiles" ]; then
      # Create host-keyfile dir if not exist
      mkdir -p /etc/ssh/host-keyfiles
    fi

    # Check if Keyfiles are directories and remove them when necessary (could happen when mounted the first time with some Kubernetes-Storages)
    if [ -d /etc/ssh/host-keyfiles/ssh_host_ed25519_key ]; then
      rm -vfR /etc/ssh/host-keyfiles/ssh_host_ed25519_key
    fi
    if [ -d /etc/ssh/host-keyfiles/ssh_host_rsa_key ]; then
      rm -vfR /etc/ssh/host-keyfiles/ssh_host_rsa_key
    fi

    # Generate unique ssh keys for this container, if needed
    if [ ! -f /etc/ssh/host-keyfiles/ssh_host_ed25519_key ]; then
      ssh-keygen -t ed25519 -f /etc/ssh/host-keyfiles/ssh_host_ed25519_key -N ''
    fi
    if [ ! -f /etc/ssh/host-keyfiles/ssh_host_rsa_key ]; then
      ssh-keygen -t rsa -b 4096 -f /etc/ssh/host-keyfiles/ssh_host_rsa_key -N ''
    fi

    # Restrict access from other users
    chown -vR root:root /etc/ssh/host-keyfiles
    chmod -vR 700 /etc/ssh/host-keyfiles
    chmod -vR 600 /etc/ssh/host-keyfiles/ssh_host_ed25519_key
    chmod -vR 600 /etc/ssh/host-keyfiles/ssh_host_rsa_key

    # Create empty nmrih-keyfiles pubkeyfile if not exist
    if [ ! -f "/etc/ssh/nmrih-keyfiles/pubkey.pub" ]; then
      touch /etc/ssh/nmrih-keyfiles/pubkey.pub
    fi

    # Create empty root-keyfiles pubkeyfile if not exist
    if [ ! -f "/etc/ssh/root-keyfiles/pubkey.pub" ]; then
      touch /etc/ssh/root-keyfiles/pubkey.pub
    fi
    
    # Add Pubkey to file, if variable is set
    if [ ! -z "$SSHKEY" ]; then
        mkdir -p /etc/ssh/keyfiles
        touch /etc/ssh/keyfiles/pubkey.pub
        IFS=';' read -r -a keys <<< "$SSHKEY"
        for key in "${keys[@]}"; do
            echo "$key" >> /etc/ssh/nmrih-keyfiles/pubkey.pub
            echo "$key" >> /etc/ssh/root-keyfiles/pubkey.pub
        done
    fi

    # Add Ownership and permissions for nmrih
    chown -vR nmrih:nmrih /etc/ssh/nmrih-keyfiles
    chmod -v 770 /etc/ssh/nmrih-keyfiles
    chmod -v 600 /etc/ssh/nmrih-keyfiles/pubkey.pub

    # Add Ownership and permissions for root
    chown -vR root:root /etc/ssh/root-keyfiles
    chmod -v 770 /etc/ssh/root-keyfiles
    chmod -v 600 /etc/ssh/root-keyfiles/pubkey.pub

    # Add Trusted SSH-Keyfile to Keyfiles
    echo "" >> /etc/ssh/sshd_config
    echo "HostKey /etc/ssh/host-keyfiles/ssh_host_ed25519_key" >> /etc/ssh/sshd_config
    echo "HostKey /etc/ssh/host-keyfiles/ssh_host_rsa_key" >> /etc/ssh/sshd_config
    echo "AuthorizedKeysFile /etc/ssh/keyfiles/pubkey.pub" >> /etc/ssh/sshd_config

    # Allow Access as root (disabled on default)
    if [ -z "$ENABLEROOT" ];
    then
      echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    else
      if [[ "$ENABLEROOT" = "true" || "$ENABLEROOT" = "1" ]]; 
      then
        echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
      else
        echo "PermitRootLogin no" >> /etc/ssh/sshd_config
      fi
    fi
    # Allow Password Auth (disabled on default)
    if [ -z "$ENABLEPWD" ];
    then
      echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    else
      if [[ "$ENABLEPWD" = "true" || "$ENABLEPWD" = "1" ]]; 
      then
        echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
      else
        echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
      fi
    fi
    # Finally start up service
    echo "------------------------"
    /usr/sbin/service ssh start
  elif [[ "$ENABLESSH" = "false" || "$ENABLESSH" = "0" ]]; 
  then
    /usr/sbin/service ssh stop
  fi
else
  /usr/sbin/service ssh stop
fi

# Run the game as nmrih user
sudo -i -u nmrih /opt/nmrih/startgame.sh