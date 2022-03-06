#!/bin/bash

# Check if .steam-Folder exists
if [ ! -d /home/nmrih/.steam ]; then
	mkdir -vp /home/nmrih/.steam
fi

# Check if Symlink exists
if [ ! -L /home/nmrih/.steam/sdk32 ]; then
	ln -s /home/nmrih/steamcmd/linux32 /home/nmrih/.steam/sdk32
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

echo "-------------------"
echo "Start up the Server"
echo "-------------------"
/home/nmrih/server/srcds_run \
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
	+sv_password $NMRIH_PW \
	+rcon_password $NMRIH_RCONPW \
	$NMRIH_ADDITIONAL_ARGS