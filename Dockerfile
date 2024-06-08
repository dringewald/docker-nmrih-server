# Use ubuntu as base image for nmrih gameserver
FROM ubuntu:24.04

# Author
MAINTAINER "Holt | NoX-Eagles.de"

# Label
LABEL version="1.0"

# Environments
ENV LC_ALL=C.UTF-8
ENV TZ=Europe/Berlin
ENV ENABLESSH=false
ENV ENABLEROOT=false
ENV ENABLEPWD=false
ENV SSHKEY=
ENV NMRIH_UPDATEPACKAGES=false
ENV NMRIH_USERPWD=
ENV NMRIH_UPDATECHECK=
ENV NMRIH_VALIDATECHECK=
ENV NMRIH_FIXPERMS=
ENV NMRIH_RCONPW=
ENV NMRIH_PW=
ENV NMRIH_CLIENT_PORT=
ENV NMRIH_PORT=
ENV NMRIH_TV_PORT=
ENV NMRIH_IP_ADDRESS=
ENV NMRIH_NET_PUBLIC_ADDRESS=
ENV NMRIH_MAXPLAYERS=
ENV NMRIH_STARTMAP=
ENV NMRIH_REGION=
ENV NMRIH_TOKEN=
ENV NMRIH_AUTH_KEY=
ENV NMRIH_CONFIG_FILE=
ENV NMRIH_ADDITIONAL_ARGS=

# Arguments
ARG DEBIAN_FRONTEND=noninteractive

# Set Frontend and Timezone
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install default packages 
RUN apt-get -qy update
RUN apt-get -qy install curl ca-certificates software-properties-common dialog apt-utils sudo wget gnupg2 rsync unzip lsof nano net-tools

# Install OpenSSH Server
RUN apt-get -qy update && \
    apt-get -qy install openssh-server && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd && \
    rm -f /etc/ssh/ssh_host_*key*

# Add nmrih server and optional directiories
RUN useradd -ms /bin/bash nmrih
RUN mkdir -v /opt/nmrih

# Upgrade all other packages
RUN apt-get -qy upgrade

# Copy files
COPY files/entrypoint.sh /
COPY --chown=nmrih files/nmrih-setup.sh /opt/nmrih/nmrih-setup.sh
COPY --chown=nmrih files/startgame.sh /opt/nmrih/startgame.sh

# Set permissions
RUN chmod 770 /entrypoint.sh
RUN chown -vR nmrih:nmrih /opt/nmrih/
RUN chmod -vR 770 /opt/nmrih/

# Workdir
WORKDIR /home/nmrih

# Exposesection
EXPOSE 22/tcp

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# User
USER nmrih