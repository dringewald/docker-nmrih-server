# No More Room in Hell - Docker Image
This image provides a fully functional No More Room in Hell Server.

* Built on the secure Ubuntu Linux distribution (Ubuntu 26.04 LTS)
* Uses the latest optimizations for the best performance, low CPU usage & memory footprint
* Optimized for multiple concurrent users
* Allows the use of SFTP to easy access the gameserver files for modification
* The gameserver runs under a non-privileged user (nmrih) to make it more secure
* The logs of the game are redirected to the output of the Docker container (visible with docker logs -f <container name>)
* The gameserver shuts down gracefully when the container is stopped
* Follows the KISS principle (Keep It Simple, Stupid) to make it easy to understand and adjust the image to your needs
* Optimized to be run as a single pod in a kubernetes cluster

You can find a docker-compose.yml and a kubernetes-nmrih.yml in the [GitHub repository](https://github.com/dringewald/docker-nmrih-server/).

## Goal of this project
The goal of this container image is to provide an easy to run No More Room in Hell gameserver in a container which follows the best practices.
I did not find images that were easy to understand. Most were optimized for their own needs. With this image I try to provide you an easy container for your favorite game.

## How the image works (in a nutshell)
When the image is started, the container downloads steamcmd.  
This in turn downloads the game files.  
The game server is then started with the variables you used.  

## Usage
No More Room in Hell only supports anonymous game servers.  
You don't need a [Game Server Login Token (GSLT)](https://steamcommunity.com/dev/managegameservers) to get listed on the master server or to get Steam achievements.  
It is not recommend to use a GSLT, because it breaks server-side Workshop and could lead to an error (check the [Custom information and errors](#custom-information-and-errors-good-to-know) section).

Start the Docker container and make sure to mount a directory or volume to keep the files persistent:

    docker run -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    holt31/nmrih-server:latest

Or if you want to use a different startmap, you could set that via a variable as follows:

    docker run -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -e NMRIH_STARTMAP="nmo_broadway" \
    holt31/nmrih-server:latest

#### User Password for the nmrih user

---
You should set a user password for the nmrih user via the NMRIH_USERPWD variable, otherwise a random password will be generated.  
The random password will not be shown in the log. It is stored in the file /root/nmrih_userpwd, which can only be read by root.  
The password stays the same when the container is restarted. It will only be generated again when the container is recreated.  
You can read the password with the following commands:

    docker exec <container name> cat /root/nmrih_userpwd

    kubectl exec <pod name> -- cat /root/nmrih_userpwd

It is highly recommand to use a secret for the password. The image reads the password from the file /run/secrets/nmrih_userpwd.  
This works with Docker, Docker Compose, Docker Swarm and Kubernetes.  
If the file exists, the variable NMRIH_USERPWD will be ignored.  

With a normal docker run, you could mount a file with the password into the container. Please make sure to adjust the password correctly.  

    echo "your_password_here" > ~/nmrih_userpwd.txt
    chmod 600 ~/nmrih_userpwd.txt

Now run the container with the following command:

    docker run -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -v ~/nmrih_userpwd.txt:/run/secrets/nmrih_userpwd:ro \
    holt31/nmrih-server:latest

If you use Docker Compose or Kubernetes, you can find an example for the secret in the docker-compose.yml and kubernetes-nmrih.yml in the [GitHub repository](https://github.com/dringewald/docker-nmrih-server/).  
If you use Docker Swarm, you could create the secret with the following command and add "--secret nmrih_userpwd" to your "docker service create" command.

    echo "your_password_here" | docker secret create nmrih_userpwd -

If you don't want to use a secret, then you could also manually set the variable NMRIH_USERPWD.  
It is not advised to do so, due to security risks.  
Even if it isn't recommand, it is needed in some cases.  

    docker run -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -e NMRIH_USERPWD="yourpassword" \
    holt31/nmrih-server:latest

#### RCON and server password

---
The RCON password and the server password could also be set via a secret.  
The image reads them from the following files. If a file exists, the variable will be ignored.  

|Secret file|Description|Variable (used if the file doesn't exist)|
| ------------- | ------------- | ------------- |
|/run/secrets/nmrih_userpwd|Password of the nmrih user|NMRIH_USERPWD|
|/run/secrets/nmrih_rconpw|RCON password|NMRIH_RCONPW|
|/run/secrets/nmrih_pw|Server password|NMRIH_PW|

With a normal docker run, you could create the files and mount them into the container.  

    echo "your_rcon_password_here" > ~/nmrih_rconpw.txt
    echo "your_server_password_here" > ~/nmrih_pw.txt
    chmod 600 ~/nmrih_rconpw.txt ~/nmrih_pw.txt

    docker run -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -v ~/nmrih_rconpw.txt:/run/secrets/nmrih_rconpw:ro \
    -v ~/nmrih_pw.txt:/run/secrets/nmrih_pw:ro \
    holt31/nmrih-server:latest

You can find examples for Docker Compose and Kubernetes in the docker-compose.yml and kubernetes-nmrih.yml in the [GitHub repository](https://github.com/dringewald/docker-nmrih-server/).  
If you don't want to use a secret, you could still use the variables NMRIH_RCONPW and NMRIH_PW.

Please note that the server.cfg is executed after the start parameters of the server.  
If you set the RCON password or the server password via a secret or a variable, make sure that there is no "rcon_password" or "sv_password" in your server.cfg.  
Otherwise the passwords from the server.cfg will override the passwords from the secret or the variable.

#### server.cfg

---
The image does not create a server.cfg, so the server starts with the default settings.  
You can find a template for the server.cfg (examples/server.cfg) in the [GitHub repository](https://github.com/dringewald/docker-nmrih-server/tree/master/examples).  
Copy it to /home/nmrih/server/nmrih/cfg/server.cfg and adjust it to your needs.  
The file is stored in the volume of the game files, so it stays when the container is recreated.  
If you want to use another name for the file, you could set it via the variable NMRIH_CONFIG_FILE.

You can copy the file into the container with the following commands:

    docker cp server.cfg <container name>:/home/nmrih/server/nmrih/cfg/server.cfg
    docker exec <container name> chown nmrih:nmrih /home/nmrih/server/nmrih/cfg/server.cfg

    kubectl cp server.cfg games/<pod name>:/home/nmrih/server/nmrih/cfg/server.cfg
    kubectl exec -n games <pod name> -- chown nmrih:nmrih /home/nmrih/server/nmrih/cfg/server.cfg

The server.cfg is executed on every map start, so you don't need to restart the container after a change.  
Please don't set "sv_password" or "rcon_password" in the server.cfg, if you use the secrets or the variables (check the [RCON and server password](#rcon-and-server-password) section).

#### SFTP Usage

---
In some environments, for example in kubernetes clusters, it is needed or more comfortable to access the gameserver files via SFTP.  
This methode is the most convient one in some special cases.  
The image has an OpenSSH server included, to use SFTP.  
By default it is disabled and will not start when the image is started, but it can be activated by the use of variables.  
You should atleast include the /etc/ssh/host-keyfiles as a volume, to have consistent hostkeys.

If you enter one or more public keys, these are stored for both the "root" and "nmrih" users.
The keys are stored in /etc/ssh/nmrih-keyfiles/pubkey.pub for the "nmrih" user and in /etc/ssh/root-keyfiles/pubkey.pub for the "root" user.  
Keys which are already in the file will not be added again.  
A login via "root" is deactivated by default and can be activated using the ENABLEROOT variable.

This example allows login via your provided SSH public key.

    docker run -p 22:22/tcp -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \ 
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -v ~/nmrih-hostkeys-folder:/etc/ssh/host-keyfiles \
    -e ENABLESSH="true" \
    -e SSHKEY="ecdsa-sha2-nistp521 AAAAE2... user1@example.com" \
    holt31/nmrih-server:latest

It is also possible to specify multiple public SSH keys by using a semicolon (;) as a separator between the keys.

    docker run -p 22:22/tcp -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \ 
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -v ~/nmrih-hostkeys-folder:/etc/ssh/host-keyfiles \
    -e ENABLESSH="true" \
    -e SSHKEY="ecdsa-sha2-nistp521 AAAAE2... user1@example.com;ssh-rsa AAAAB3... user2@example.com" \
    holt31/nmrih-server:latest

The following example allows the use of your password via the secret.

    docker run -p 22:22/tcp -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \ 
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -v ~/nmrih-hostkeys-folder:/etc/ssh/host-keyfiles \
    -e ENABLESSH="true" \
    -e ENABLEPWD="true" \
    -v ~/nmrih_userpwd.txt:/run/secrets/nmrih_userpwd:ro \
    holt31/nmrih-server:latest

The following run command lets the ssh server start with a password set via the variable and allows the use of the password for login as the nmrih user.

    docker run -p 22:22/tcp -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -v ~/nmrih-hostkeys-folder:/etc/ssh/host-keyfiles \
    -e NMRIH_USERPWD="yourpassword" \
    -e ENABLESSH="true" \
    -e ENABLEPWD="true" \
    holt31/nmrih-server:latest

You could also combine the login via your SSH public key and your password.  
This could be useful if you need it for automatitions were programs can't use your ssh key.

    docker run -p 22:22/tcp -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -v ~/nmrih-hostkeys-folder:/etc/ssh/host-keyfiles \
    -e ENABLESSH="true" \
    -e ENABLEPWD="true" \
    -e SSHKEY="ecdsa-sha2-nistp521 AAAAE2... user1@example.com" \
    -v ~/nmrih_userpwd.txt:/run/secrets/nmrih_userpwd:ro \
    holt31/nmrih-server:latest

## Volumes
This image has 3 directories for which it makes sense to make them persistent.
Make sure to set the correct permissions for the user and group (1000) of both nmrih gameserver files.  
With the help of the NMRIH_FIXPERMS variable, the container should set the correct permissions on startup for all important folders.
If NMRIH_FIXPERMS is used, the startup of the container will be slighter longer.

|Directory|Description|Required/Optional|Permissions|
| ------------- | ------------- | ------------- | ------------- |
|/home/nmrih/server|This directory contains all files relevant to the game. This includes all maps, models etc. The game files are downloaded at the first start. If this folder is not specified as a volume, the game will be downloaded again each time it is started.|Required|nmrih:nmrih (1000:1000)|
|/home/nmrih/steamcmd|Backs up the steamcmd files. Not absolutely necessary, but recommended for a faster start of the container. Otherwise, steamcmd will be downloaded per start.|Optional (recommend)|nmrih:nmrih (1000:1000)|
|/etc/ssh/host-keyfiles|You should create a Volume for the SSH host keys when SSH/SFTP is being used.<br/>Creating a volume for /etc/ssh/host-keyfiles ensures that SSH host keys persist across container restarts and are not lost when containers are recreated.<br/>SSH host keys should not be recreated to maintain consistent host identity, ensuring uninterrupted and secure SSH connections without triggering security warnings for clients.|Optional (recommend when using SSH)|root:root|

## Variables
Here you'll find a list of every variable that can be set in the container.  
Almost every start parameter of the gameserver is settable via a variable.  
You could also specify missing parameters (like -debug etc.) via the variable "NMRIH_ADDITIONAL_ARGS".  
Just include them in you docker run command.  

|Variable|Value|Description|Default|
| ------------- | ------------- | ------------- | ------------- |
|TZ|Europe/Berlin|Sets the time zone of the container. A list can be found at https://en.wikipedia.org/wiki/List_of_tz_database_time_zones|Not set|
|ENABLESSH|true / 1|Enables the SSH service in the container so that files can be edited via SSH/SFTP|false|
|ENABLEROOT|true / 1|Allows access to the root user via SSH|false|
|ENABLEPWD|true / 1|Allows SSH access via password|false|
|NMRIH_UPDATEPACKAGES|true / 1|Updates all packages when starting the image|Not set|
|NMRIH_USERPWD|Password|Sets a user password for the nmrih user. If none is entered, one is generated randomly and stored in /root/nmrih_userpwd. You should use the secret if possible |Random generated Password|
|NMRIH_UPDATECHECK|true / 1|Updates the NMRIH server when the image is started|true|
|NMRIH_STEAMCMDCHECK|true / 1|Downloads a fresh copy of steamcmd when the image is started|false|
|NMRIH_VALIDATECHECK|true/ 1|Validates the NMRIH files when the image is started|false|
|NMRIH_FIXPERMS|true / 1|Sets the correct permissions when starting the image|false|
|NMRIH_RCONPW|Password|Sets the RCON password. The secret /run/secrets/nmrih_rconpw is preferred, if it exists|Not set|
|NMRIH_PW|Password|Sets a server password. The secret /run/secrets/nmrih_pw is preferred, if it exists|Not set|
|NMRIH_CLIENT_PORT|Port|Sets the client port (UDP)|27010|
|NMRIH_PORT|Port|Sets the game port (TCP/UDP)|27015|
|NMRIH_TV_PORT|Port|Sets the TV port (UDP)|27020|
|NMRIH_IP_ADDRESS|IP address|IP address to which the server should bind. If it is empty or 0.0.0.0, the server listens on all interfaces. Only set it if you really need it, because it could break the connection to Steam when used with Docker or Kubernetes|Not set|
|NMRIH_MAXPLAYERS|Number of players (max 8)|Defines the maximum number of players on the server|8|
|NMRIH_STARTMAP|Mapname|Sets the start map|nmo_cabin|
|NMRIH_REGION|Number|Sets the public region|3|
|NMRIH_TOKEN|Steam Game Server Login Token (GSLT)|Not recommend. NMRIH only supports anonymous game servers, so a GSLT is not needed. It breaks server-side Workshop and could lead to the error "Result = 15"|Not set|
|NMRIH_AUTH_KEY|Steam Web API key|Not needed for NMRIH. Only exists for older setups|Not set|
|NMRIH_DISABLEVAC|true / 1|Disables VAC for the server (useful if plugins or mods are being used that could trigger VAC)|false|
|NMRIH_CONFIG_FILE|Config file|Determines the name of the config file|server.cfg|
|NMRIH_ADDITIONAL_ARGS|Other configuration parameters|Determines other, non-existent parameters|Not set|

## Additional Information

This image was created to the best of my knowledge and belief. It may and probably will contain some errors.
Some may also not be satisfied with the packages used (nano / net-tools) or similar. 
Please note that this image was primarily created for my needs.
If you have any problems with the image, please don't hesitate to contact me or fork the repository. The source code is publicly available. 

#### Useful Links

---
* GitHub repository: https://github.com/dringewald/docker-nmrih-server/
* GitLab repository: https://gitlab.holydev.net/gameserver/docker-nmrih-server/
* Docker Hub: https://hub.docker.com/r/holt31/nmrih-server
* Discord: https://discord.gg/jymDumdFVU 
* Steam documentation: https://developer.valvesoftware.com/wiki/Source_Dedicated_Server
* No More Room in Hell Steam page: https://store.steampowered.com/app/224260/No_More_Room_in_Hell/
* Game Server Login Token (GSLT) Page: https://steamcommunity.com/dev/managegameservers

#### Custom information and errors (good to know)

---
1. If the following error message appears, the server will not be listed on the master server and Steam achievements will not work.
    ```
    Could not establish connection to Steam servers.  (Result = 15)
    ```
    The error code 15 means "Access Denied".  
    No More Room in Hell only supports anonymous game servers, so you shouldn't use a [Game Server Login Token (GSLT)](https://steamcommunity.com/dev/managegameservers).  
    To fix the error, make sure to do the following:
    * Remove the variable NMRIH_TOKEN
    * Remove the variable NMRIH_AUTH_KEY
    * Leave the variable NMRIH_IP_ADDRESS empty, so the server doesn't bind to a specific IP address (important for Docker and Kubernetes)

    Thanks to the NMRIH developers for the help in the [Ticket](https://discord.com/channels/211900829307895819/1260547075016495156) on the official [NMRIH Discord Server](https://discord.gg/nmrih).

2. The following error codes are related to an expired or invalid [Game Server Login Token (GSLT)](https://steamcommunity.com/dev/managegameservers).
    ```
    Could not establish connection to Steam servers.  (Result = 18)
    ```
    ```
    Could not establish connection to Steam servers.  (Result = 106)
    ```
    NMRIH doesn't need a GSLT, so just remove the variable NMRIH_TOKEN.

3. If you get the error "Permission denied", then make sure you assign the correct permission to the volumes.  
    The error message on startup of the container may look like this.
    ```
    rm: cannot remove '/home/nmrih/steamcmd': Device or resource busy
    rm: cannot remove '/home/nmrih/server': Device or resource busy
    steamcmd.sh
    tar: steamcmd.sh: Cannot open: Permission denied
    ```
    Make sure to create and set the permissions correctly.
    Check the [Volumes](#volumes) section about the correct permissions. 

4. No More Room in Hell needs the 32-bit library libtinfo5 for the server console, otherwise the following warning appears.
    ```
    WARNING: Failed to load 32-bit libtinfo.so.5 or libncurses.so.5.
    ```
    Since Ubuntu 24.04 this library is not available anymore.  
    The image adds the Ubuntu 22.04 repository and only installs libtinfo5 from it. All other packages are still installed from Ubuntu 26.04.  
    You can find the settings for this in the files files/apt/jammy.sources and files/apt/jammy.pref in the [GitHub repository](https://github.com/dringewald/docker-nmrih-server/).

5. With the update from 13.09.2026 the image supports secrets for the passwords (check the [RCON and server password](#rcon-and-server-password) section).  
    If you used the image in Kubernetes before and now mount the secrets into /run/secrets, the pod may not start anymore.  
    The pod shows the status "RunContainerError" and the log of the container is empty.
    ```
    NAME                    READY   STATUS              RESTARTS      AGE
    nmrih-7cc765c89-wpx7l   0/1     RunContainerError   3 (19s ago)   78s
    ```
    With "kubectl describe pod" you will find an error with "read-only file system" in the events.  
    The reason is that /var/run is a link to /run in the container. Kubernetes tries to mount the service account token into /var/run/secrets/kubernetes.io/serviceaccount, which is inside the read-only secret.  
    The gameserver doesn't need access to the Kubernetes API, so just add the following line to the spec of the pod in your deployment:
    ```
    automountServiceAccountToken: false
    ```
    You could also change your running deployment with the following command:
    ```
    kubectl patch deployment nmrih -n games -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":false}}}}'
    ```
    The kubernetes-nmrih.yml in the [GitHub repository](https://github.com/dringewald/docker-nmrih-server/) already contains this setting.  
    If you don't mount the secrets into /run/secrets, nothing needs to be changed.