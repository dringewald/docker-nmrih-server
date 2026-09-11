#!/bin/bash

###################################
######## RUN AS nmrih USER ########
###################################

if [ "$EUID" -ne "$(id -u nmrih)" ]; then
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

# Base start parameters
SERVER_ARGS=(
	-game nmrih
	$VACFLAG
	-usercon
	-console
	-strictportbind
	-port "$NMRIH_PORT"
	+clientport "$NMRIH_CLIENT_PORT"
	+tv_port "$NMRIH_TV_PORT"
	+map "$NMRIH_STARTMAP"
	+servercfgfile "$NMRIH_CONFIG_FILE"
	-maxplayers "$NMRIH_MAXPLAYERS"
	+sv_region "$NMRIH_REGION"
)

# Only bind to a specific IP if one is set explicitly.
# Binding to an IP (even 0.0.0.0) breaks the Steam connection behind NAT (e.g. Docker/Kubernetes networking).
if [[ -n "$NMRIH_IP_ADDRESS" && "$NMRIH_IP_ADDRESS" != "0.0.0.0" ]]; then
	SERVER_ARGS+=(-ip "$NMRIH_IP_ADDRESS")
fi

# NMRIH only supports anonymous game servers, so a GSLT is not needed. It also breaks server-side Workshop
if [ -n "$NMRIH_TOKEN" ]; then
	echo "------------------------"
	echo "WARNING: NMRIH_TOKEN is set!"
	echo "NMRIH only supports anonymous game servers. A GSLT is not required and breaks server-side Workshop."
	echo "If you get \"Could not establish connection to Steam servers. (Result = 15)\", remove NMRIH_TOKEN."
	echo "------------------------"
	SERVER_ARGS+=(+sv_setsteamaccount "$NMRIH_TOKEN")
fi

# Not needed for NMRIH, only exists for older setups
if [ -n "$NMRIH_AUTH_KEY" ]; then
	SERVER_ARGS+=(-authkey "$NMRIH_AUTH_KEY")
fi

if [ -n "$NMRIH_PW" ]; then
	SERVER_ARGS+=(+sv_password "$NMRIH_PW")
fi

if [ -n "$NMRIH_RCONPW" ]; then
	SERVER_ARGS+=(+rcon_password "$NMRIH_RCONPW")
fi

echo "-------------------"
echo "Start up the Server"
echo "-------------------"
exec /home/nmrih/server/srcds_run "${SERVER_ARGS[@]}" $NMRIH_ADDITIONAL_ARGS
