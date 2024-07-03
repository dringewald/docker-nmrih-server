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
ENV NMRIH_UPDATECHECK=true
ENV NMRIH_VALIDATECHECK=false
ENV NMRIH_FIXPERMS=false
ENV NMRIH_RCONPW=
ENV NMRIH_PW=
ENV NMRIH_CLIENT_PORT=27010
ENV NMRIH_PORT=27015
ENV NMRIH_TV_PORT=27020
ENV NMRIH_IP_ADDRESS=0.0.0.0
ENV NMRIH_NET_PUBLIC_ADDRESS=0.0.0.0
ENV NMRIH_MAXPLAYERS=8
ENV NMRIH_STARTMAP=nmo_cabin
ENV NMRIH_REGION=3
ENV NMRIH_TOKEN=
ENV NMRIH_AUTH_KEY=
ENV NMRIH_CONFIG_FILE=server.cfg
ENV NMRIH_ADDITIONAL_ARGS=

# Arguments
ARG DEBIAN_FRONTEND=noninteractive

# Set Frontend and Timezone
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install default packages
RUN dpkg --add-architecture i386 
RUN apt-get -qy update
RUN apt-get -qy install curl ca-certificates software-properties-common dialog apt-utils sudo wget gnupg2 rsync unzip lsof nano net-tools git tar \
    lib32gcc-s1 lib32z1 gdb libc6-i386 lib32stdc++6 libtinfo5:i386

# Install OpenSSH Server
RUN apt-get -qy update && \
    apt-get -qy install openssh-server && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd && \
    rm -f /etc/ssh/ssh_host_*key*

# Add nmrih user and optional directiories - remove ubuntu user
RUN deluser ubuntu
RUN useradd -ms /bin/bash nmrih
RUN mkdir -v /opt/nmrih

# Upgrade all other packages
RUN apt-get -qy upgrade

# Create Docker secrets directory
RUN mkdir -p /run/secrets

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
EXPOSE 27010/UDP
EXPOSE 27015/tcp
EXPOSE 27015/udp
EXPOSE 27020/udp

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]