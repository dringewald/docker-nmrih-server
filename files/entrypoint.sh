#!/bin/bash

# Tell APT to run without interaction
DEBIAN_FRONTEND=noninteractive
DEBCONF_NONINTERACTIVE_SEEN=true
DEBIAN_PRIORITY=critical
UBUNTU_VERSION=$(. /etc/os-release && echo "$VERSION_ID")

# Commands are run as nmrih user via setpriv, which keeps the environment (all NMRIH_* variables)
NMRIH_SETPRIV=(setpriv --reuid=nmrih --regid=nmrih --init-groups)

# Read a secret file from /run/secrets (secrets are preferred over the variables)
# Line breaks are removed (e.g. from files created with echo or on Windows)
read_secret() {
    local file="/run/secrets/$1"
    if [ -s "$file" ]; then
        tr -d '\r\n' < "$file"
        return 0
    fi
    return 1
}

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
if [[ "$UBUNTU_VERSION" == "26.04" ]] || [[ "$UBUNTU_VERSION" == "24.04" ]] || [[ "$UBUNTU_VERSION" == "22.04" ]]; then
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

# Set the password for the nmrih user
# Priority: secret /run/secrets/nmrih_userpwd > variable NMRIH_USERPWD > random password (stored in a root-only file, not in the log)
NMRIH_USERPWD_FILE="/root/nmrih_userpwd"
if NMRIH_SECRET=$(read_secret nmrih_userpwd); then
    NMRIH_USERPWD="$NMRIH_SECRET"
    echo "Password for nmrih user set from secret /run/secrets/nmrih_userpwd."
elif [ -n "$NMRIH_USERPWD" ]; then
    echo "Custom Password is set via variable NMRIH_USERPWD"
else
    # Reuse the generated password on container restarts
    if [ ! -s "$NMRIH_USERPWD_FILE" ]; then
        (umask 077; tr -dc A-Za-z0-9 </dev/urandom | head -c 16 > "$NMRIH_USERPWD_FILE")
    fi
    NMRIH_USERPWD=$(cat "$NMRIH_USERPWD_FILE")
    echo "------------------------"
    echo ""
    echo "No password is set for the nmrih user, so a random password was generated."
    echo "You can read it with:"
    echo "  docker exec <container> cat $NMRIH_USERPWD_FILE"
    echo "  kubectl exec <pod> -- cat $NMRIH_USERPWD_FILE"
    echo ""
    echo "Set the variable NMRIH_USERPWD or the secret \"nmrih_userpwd\" to use your own password."
    echo ""
    echo "------------------------"
fi
echo "nmrih:${NMRIH_USERPWD}" | chpasswd
passwd -u nmrih > /dev/null
# Don't pass the password on to the game server
unset NMRIH_USERPWD

# RCON and server password
# Priority: secret /run/secrets/nmrih_rconpw or /run/secrets/nmrih_pw > variable NMRIH_RCONPW or NMRIH_PW
if NMRIH_SECRET=$(read_secret nmrih_rconpw); then
    export NMRIH_RCONPW="$NMRIH_SECRET"
    echo "RCON password set from secret /run/secrets/nmrih_rconpw."
fi
if NMRIH_SECRET=$(read_secret nmrih_pw); then
    export NMRIH_PW="$NMRIH_SECRET"
    echo "Server password set from secret /run/secrets/nmrih_pw."
fi
unset NMRIH_SECRET

# Check if steamcmd-Folder is empty and delete contents for proper access
if [ -d /home/nmrih/steamcmd ]; then
    if [ ! "$(ls -A /home/nmrih/steamcmd)" ]; then
        rm -vR /home/nmrih/steamcmd/*
    fi
else
    mkdir -p /home/nmrih/steamcmd || exit 1
fi

# Check if server-Folder is empty and delete contents for proper access
if [ -d /home/nmrih/server ]; then
    if [[ ! "$(ls -A /home/nmrih/server)" && ! -d /home/nmrih/server/nmrih ]]; then
        rm -vR /home/nmrih/server/*
    fi
else
    mkdir -p /home/nmrih/server || exit 1
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
cd /home/nmrih || exit 1
HOME=/home/nmrih USER=nmrih LOGNAME=nmrih "${NMRIH_SETPRIV[@]}" /opt/nmrih/nmrih-setup.sh

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

    # Authorized keys are stored in one file per user:
    # /etc/ssh/nmrih-keyfiles/pubkey.pub and /etc/ssh/root-keyfiles/pubkey.pub
    mkdir -p /etc/ssh/nmrih-keyfiles /etc/ssh/root-keyfiles
    touch /etc/ssh/nmrih-keyfiles/pubkey.pub /etc/ssh/root-keyfiles/pubkey.pub

    # Add Pubkeys from the variable (only if they are not already in the file)
    if [ -n "$SSHKEY" ]; then
        IFS=';' read -r -a keys <<< "$SSHKEY"
        for key in "${keys[@]}"; do
            [ -z "$key" ] && continue
            for keyfile in /etc/ssh/nmrih-keyfiles/pubkey.pub /etc/ssh/root-keyfiles/pubkey.pub; do
                grep -qxF -- "$key" "$keyfile" || echo "$key" >> "$keyfile"
            done
        done
    fi

    # Ownership and permissions (sshd rejects keyfiles in group/world writable directories)
    chown -R nmrih:nmrih /etc/ssh/nmrih-keyfiles
    chown -R root:root /etc/ssh/root-keyfiles
    chmod 700 /etc/ssh/nmrih-keyfiles /etc/ssh/root-keyfiles
    chmod 600 /etc/ssh/nmrih-keyfiles/pubkey.pub /etc/ssh/root-keyfiles/pubkey.pub

    # Allow Access as root (disabled on default)
    if [[ "$ENABLEROOT" = "true" || "$ENABLEROOT" = "1" ]]; then
      PERMITROOTLOGIN="prohibit-password"
    else
      PERMITROOTLOGIN="no"
    fi

    # Allow Password Auth (disabled on default)
    if [[ "$ENABLEPWD" = "true" || "$ENABLEPWD" = "1" ]]; then
      PASSWORDAUTHENTICATION="yes"
    else
      PASSWORDAUTHENTICATION="no"
    fi

    # Write the SSH config to a drop-in file (overwritten on every start instead of appended to sshd_config)
    mkdir -p /etc/ssh/sshd_config.d
    cat > /etc/ssh/sshd_config.d/nmrih.conf <<EOF
HostKey /etc/ssh/host-keyfiles/ssh_host_ed25519_key
HostKey /etc/ssh/host-keyfiles/ssh_host_rsa_key
AuthorizedKeysFile /etc/ssh/%u-keyfiles/pubkey.pub
PermitRootLogin $PERMITROOTLOGIN
PasswordAuthentication $PASSWORDAUTHENTICATION
EOF
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

# Run the game as nmrih user (exec, so signals like SIGTERM reach the server)
cd /home/nmrih || exit 1
export HOME=/home/nmrih USER=nmrih LOGNAME=nmrih
exec "${NMRIH_SETPRIV[@]}" /opt/nmrih/startgame.sh