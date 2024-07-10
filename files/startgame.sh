#!/bin/bash

###################################
######## RUN AS nmrih USER ########
###################################

if [ "$EUID" -ne 1000 ]; then
    echo "------------------------"
	echo "Your EUID is $EUID! It should be $(id -u nmrih)"
	echo "Please run as user \"nmrih\"!"
	echo "------------------------"
	exit
fi

# Check if .steam-Folder exists
if [ ! -d /home/nmrih/.steam ]; then
	mkdir -vp /home/nmrih/.steam
fi

# Check if Symlink exists
if [ ! -L /home/nmrih/.steam/sdk32 ]; then
	ln -s /home/nmrih/steamcmd/linux32 /home/nmrih/.steam/sdk32
fi

# Check if Variables are empty
if [ -z "$NMRIH_IP_ADDRESS" ]; then
	export NMRIH_IP_ADDRESS="0.0.0.0"
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

if [ ! -z "$NMRIH_DISABLEVAC" ]; 
then
  if [[ "$NMRIH_DISABLEVAC" = "true" || "$NMRIH_DISABLEVAC" = "1" ]]; 
  then
    export VACFLAG="-insecure"
  else
    export VACFLAG="-secure"
  fi
else
  export VACFLAG="-secure"
fi

echo "-------------------"
echo "Start up the Server"
echo "-------------------"
/home/nmrih/server/srcds_run \
	-game nmrih \
	$VACFLAG \
	-usercon \
	-console \
	-strictportbind \
	-ip $NMRIH_IP_ADDRESS \
	-port $NMRIH_PORT \
	+clientport $NMRIH_CLIENT_PORT \
	+tv_port $NMRIH_TV_PORT \
	+map $NMRIH_STARTMAP \
	+servercfgfile $NMRIH_CONFIG_FILE \
	-maxplayers $NMRIH_MAXPLAYERS \
	+sv_region $NMRIH_REGION \
	-authkey $NMRIH_AUTH_KEY \
	+sv_setsteamaccount $NMRIH_TOKEN \
	+sv_password $NMRIH_PW \
	+rcon_password $NMRIH_RCONPW \
	$NMRIH_ADDITIONAL_ARGS