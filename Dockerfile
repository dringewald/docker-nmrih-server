# Use ubuntu as base image for nmrih gameserver
FROM ubuntu:latest

# Author
MAINTAINER "Holt | NoX-Eagles.de"

# Label
LABEL version="1.0"

# Environments
ENV LC_ALL=C.UTF-8
ENV FTPPWD=www-data-user-pw
ENV TZ=Europe/Berlin
ENV SFTP_USERS=www-data

# Arguments
ARG DEBIAN_FRONTEND=noninteractive

# Runsection
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN echo "exit 0" > /usr/sbin/policy-rc.d
RUN apt-get -qy update && \
    apt-get -qy install openssh-server rsync unzip curl lib32gcc1 lib32z1 curl git gdb libc6-i386 lib32stdc++6 tar wget sudo && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd && \
    rm -f /etc/ssh/ssh_host_*key*
RUN apt-get -qy upgrade
RUN mkdir -p /etc/ssh/keyfiles
RUN rm -v /etc/ssh/sshd_config
RUN useradd -ms /bin/bash nmrih
RUN mkdir /opt/nmrih

# Copy files
COPY files/entrypoint.sh /
COPY files/nmrih-setup.sh /opt/nmrih/nmrih-setup.sh
COPY files/startgame.sh /opt/nmrih/startgame.sh
COPY files/keyfiles/id_ed25519.pub /etc/ssh/keyfiles/id_ed25519.pub
COPY files/ssh/sshd_config /etc/ssh/sshd_config

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
