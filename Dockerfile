# Use ubuntu as base image for nmrih gameserver
FROM ubuntu:26.04

# Labels
LABEL maintainer="Dustin \"Holt\" Ringewald" \
      version="1.0" \
      org.opencontainers.image.title="nmrih-server" \
      org.opencontainers.image.description="No More Room in Hell dedicated server" \
      org.opencontainers.image.authors="Dustin \"Holt\" Ringewald" \
      org.opencontainers.image.source="https://github.com/dringewald/docker-nmrih-server" \
      org.opencontainers.image.licenses="MIT"

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
ENV NMRIH_IP_ADDRESS=
ENV NMRIH_MAXPLAYERS=8
ENV NMRIH_STARTMAP=nmo_cabin
ENV NMRIH_REGION=3
ENV NMRIH_TOKEN=
ENV NMRIH_AUTH_KEY=
ENV NMRIH_CONFIG_FILE=server.cfg
ENV NMRIH_ADDITIONAL_ARGS=
ENV NMRIH_DISABLEVAC=false
ENV NMRIH_STEAMCMDCHECK=false

# Arguments
ARG DEBIAN_FRONTEND=noninteractive

# Set Frontend and Timezone
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Add the Ubuntu 22.04 repository, only for libtinfo5 (no longer available since Ubuntu 24.04)
COPY files/apt/jammy.sources /etc/apt/sources.list.d/jammy.sources
COPY files/apt/jammy.pref /etc/apt/preferences.d/jammy.pref

# Install packages (incl. OpenSSH Server and tini as init process) in one layer and clean up the apt cache
RUN dpkg --add-architecture i386 && \
    apt-get -qy update && \
    apt-cache policy libtinfo5 libtinfo5:i386 && \
    apt-get -qy upgrade && \
    apt-get -qy install curl ca-certificates software-properties-common dialog apt-utils sudo wget gnupg2 rsync unzip lsof nano net-tools git tar tzdata tini \
        lib32gcc-s1 lib32z1 gdb libc6-i386 lib32stdc++6 libncurses-dev libtinfo5 \
        libc6:i386 libtinfo5:i386 libstdc++6:i386 \
        openssh-server && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd && \
    rm -f /etc/ssh/ssh_host_*key*

# Remove the default ubuntu user (uses UID 1000 since Ubuntu 24.04)
# Add nmrih user with UID 1000, directories and Docker secrets directory
RUN (userdel -r ubuntu 2>/dev/null || true) && \
    useradd -ms /bin/bash -u 1000 nmrih && \
    mkdir -v /opt/nmrih && \
    mkdir -p /run/secrets

# Copy files
COPY files/entrypoint.sh /
COPY --chown=nmrih files/nmrih-setup.sh /opt/nmrih/nmrih-setup.sh
COPY --chown=nmrih files/startgame.sh /opt/nmrih/startgame.sh

# Set permissions
RUN chmod 770 /entrypoint.sh && \
    chown -vR nmrih:nmrih /opt/nmrih/ && \
    chmod -vR 770 /opt/nmrih/

# Workdir
WORKDIR /home/nmrih

# Exposesection
EXPOSE 22/tcp
EXPOSE 27010/udp
EXPOSE 27015/tcp
EXPOSE 27015/udp
EXPOSE 27020/udp

# Entrypoint (tini forwards signals to the whole process group, so the server shuts down gracefully)
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/entrypoint.sh"]
