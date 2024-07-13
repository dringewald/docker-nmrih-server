# No More Room in Hell - Docker Image
This image provides a fully functional No More Room in Hell Server.

* Built on the secure Ubuntu Linux distribution
* Uses the latest optimizations for the best performance, low CPU usage & memory footprint
* Optimized for multiple concurrent users
* Allows the use of SFTP to easy access the gameserver files for modification
* The gameserver runs under a non-privileged user (nmrih) to make it more secure
* The logs of the game are redirected to the output of the Docker container (visible with docker logs -f <container name>)
* Follows the KISS principle (Keep It Simple, Stupid) to make it easy to understand and adjust the image to your needs
* Optimized to be run as a single pod in a kubernetes cluster

You can find a docker-compose.yml and a kubernetes-nmrih.yml in the [GitLab repository](#useful-links).

## Goal of this project
The goal of this container image is to provide an easy to run No More Room in Hell gameserver in a container which follows the best practices.
I did not find images that were easy to understand. Most were optimized for their own needs. With this image I try to provide you an easy container for your favorite game.

## How the image works (in a nutshell)
When the image is started, the container downloads steamcmd.  
This in turn downloads the game files.  
The game server is then started with the variables you used.  

## Usage
Before you can use this image, you must create at least one [Game Server Login Token (GSLT)](https://steamcommunity.com/dev/managegameservers).  
This must be specified in the NMRIH_TOKEN variable.  
The App ID for NMRIH is: 317670

Start the Docker container and make sure to mount a directory or volume to keep the files persistent:

    docker run -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -e NMRIH_TOKEN="GSLT" \
    holt31/nmrih-server:latest

Or if you want to use a different startmap, you could set that via a variable as follows:

    docker run -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -e NMRIH_TOKEN="GSLT" \
    -e NMRIH_STARTMAP="nmo_broadway" \
    holt31/nmrih-server:latest

#### User Password for the nmrih user

---
You should set a user password for the nmrih user via the NMRIH_USERPWD variable, otherwise a random password will be generated at every start of the container.  
It is highly recommand to use a docker secret for the user. I created the image to support a secret with the name "nmrih_userpwd".  
You can achieve the use of the secret by using the following commands. Please make sure to adjust the password correctly.  

    echo "your_password_here" | docker secret create nmrih_userpwd -

Now run the container with the following command:

    docker run -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -e NMRIH_TOKEN="GSLT" \
    --secret nmrih_userpwd \
    holt31/nmrih-server:latest

If you don't want to use a secret, then you could also manually set the variable NMRIH_USERPWD.  
It is not advised to do so, due to security risks.  
Even if it isn't recommand, it is needed in some cases.  

    docker run -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -e NMRIH_TOKEN="GSLT" \
    -e NMRIH_USERPWD="yourpassword" \
    holt31/nmrih-server:latest

#### SFTP Usage

---
In some environments, for example in kubernetes clusters, it is needed or more comfortable to access the gameserver files via SFTP.  
This methode is the most convient one in some special cases.  
The image has an OpenSSH server included, to use SFTP.  
By default it is disabled and will not start when the image is started, but it can be activated by the use of variables.  
You should atleast include the /etc/ssh/host-keyfiles as a volume, to have consistent hostkeys.

If you enter one or more public keys, these are stored for both the "root" and "nmrih" users.
A login via "root" is deactivated by default and can be activated using the ENABLEROOT variable.

This example allows login via your provided SSH public key.

    docker run -p 22:22/tcp -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \ 
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -v ~/nmrih-hostkeys-folder:/etc/ssh/host-keyfiles \
    -e ENABLESSH="true" \
    -e SSHKey="ecdsa-sha2-nistp521 AAAAE2... user1@example.com" \
    -e NMRIH_TOKEN="GSLT" \
    holt31/nmrih-server:latest

It is also possible to specify multiple public SSH keys by using a semicolon (;) as a separator between the keys.

    docker run -p 22:22/tcp -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \ 
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -v ~/nmrih-hostkeys-folder:/etc/ssh/host-keyfiles \
    -e ENABLESSH="true" \
    -e SSHKey="SSHKEY=ecdsa-sha2-nistp521 AAAAE2... user1@example.com;ssh-rsa AAAAB3... user2@example.com" \
    -e NMRIH_TOKEN="GSLT" \
    holt31/nmrih-server:latest

The following example allows the use of your password via the secret.

    docker run -p 22:22/tcp -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \ 
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -v ~/nmrih-hostkeys-folder:/etc/ssh/host-keyfiles \
    -e ENABLESSH="true" \
    -e ENABLEPWD="true" \
    -e NMRIH_TOKEN="GSLT" \
    --secret nmrih_userpwd \
    holt31/nmrih-server:latest

The following run command lets the ssh server start with a password set via the variable and allows the use of the password for login as the nmrih user.

    docker run -p 22:22/tcp -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -v ~/nmrih-hostkeys-folder:/etc/ssh/host-keyfiles \
    -e NMRIH_USERPWD="yourpassword" \
    -e ENABLESSH="true" \
    -e ENABLEPWD="true" \
    -e NMRIH_TOKEN="GSLT" \
    holt31/nmrih-server:latest

You could also combine the login via your SSH public key and your password.  
This could be useful if you need it for automatitions were programs can't use your ssh key.

    docker run -p 22:22/tcp -p 27010:27010/udp -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp \
    -v ~/nmrih-gamedata-folder:/home/nmrih/server \
    -v ~/nmrih-steamcmd-folder:/home/nmrih/steamcmd \
    -v ~/nmrih-hostkeys-folder:/etc/ssh/host-keyfiles \
    -e ENABLESSH="true" \
    -e ENABLEPWD="true" \
    -e SSHKey="ecdsa-sha2-nistp521 AAAAE2... user1@example.com" \
    -e NMRIH_TOKEN="GSLT" \
    --secret nmrih_userpwd \
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
|/etc/ssh/host-keyfiles|Your should create a Volume for the SSH host keys when SSH/SFTP is being used.<br/>Creating a volume for /etc/ssh/host-keyfiles ensures that SSH host keys persist across container restarts and are not lost when containers are recreated.<br/>SSH host keys should not be recreated to maintain consistent host identity, ensuring uninterrupted and secure SSH connections without triggering security warnings for clients.|Optional (recommend when using SSH)|root:root|

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
|NMRIH_USERPWD|Password|Sets a user password for the nmrih user. If none is entered, one is generated randomly and displayed in the log. You should use |Random generated Password|
|NMRIH_UPDATECHECK|true / 1|Updates the NMRIH server when the image is started|true|
|NMRIH_VALIDATECHECK|true/ 1|Validates the NMRIH files when the image is started|false|
|NMRIH_FIXPERMS|true / 1|Sets the correct permissions when starting the image|false|
|NMRIH_RCONPW|Password|Sets the RCON password|Not set|
|NMRIH_PW|Password|Sets a server password|Not set|
|NMRIH_CLIENT_PORT|Port|Sets the client port (UDP)|27010|
|NMRIH_PORT|Port|Sets the game port (TCP/UDP)|27015|
|NMRIH_TV_PORT|Port|Sets the TV port (UDP)|27020|
|NMRIH_IP_ADDRESS|IP address|IP address to which the server should listen|0.0.0.0|
|NMRIH_MAXPLAYERS|Number of players (max 8)|Defines the maximum number of players on the server|8|
|NMRIH_STARTMAP|Mapname|Sets the start map|nmo_cabin|
|NMRIH_REGION|Number|Sets the public region|3|
|NMRIH_TOKEN|Steam Game Server Login Token (GLST)|Steamserver login token for public servers|Not set|
|NMRIH_AUTH_KEY|Workshop key|Workshop key for files from the workshop|Not set|
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
* GitLab repository: https://gitlab.holydev.net/gameserver/docker-nmrih-server/
* Discord: https://discord.gg/jymDumdFVU 
* Steam documentation: https://developer.valvesoftware.com/wiki/Source_Dedicated_Server
* Docker Hub: https://hub.docker.com/repository/docker/holt31/nmrih-server/
* No More Room in Hell Steam page: https://store.steampowered.com/app/224260/No_More_Room_in_Hell/
* Game Server Login Token (GSLT) Page: https://steamcommunity.com/dev/managegameservers

#### Custom information and errors (good to know)

---
1. Unfortunately, No More Room in Hell does not have the +net_public_addr parameter, so it is not possible to specify a public IP address.
In a Kubernetes cluster, it could therefore happen that the error message appears. 
    ```
    Could not establish connection to Steam servers.  (Result = 15)
    ```
    Sadly, there is no fix for this yet.
    If VAC is disabled (variable NMRIH_DISABLEVAC), it is possible to connect to the server, but Steam messages and a listing on the master server are disabled. 
    
    I assume that this is some kind of network issue. However, since the error codes for this type of error are absolutely horribly documented by Steam, it is difficult to find a solution.

    For this case I have already created a support ticket on the official NMRIH discord server, unfortunately there is still no answer from the developers (as of 13.07.2024).
    You can find the [Ticket](https://discord.com/channels/211900829307895819/1260547075016495156) on the official [NMRIH Discord Server](https://discord.gg/nmrih)

2. If one of the following error codes appears, it is an expired or invalid [Game Server Login Token (GSLT)](https://steamcommunity.com/dev/managegameservers).
    ```
    Could not establish connection to Steam servers.  (Result = 18)
    ```
    ```
    Could not establish connection to Steam servers.  (Result = 106)
    ```
    In this case, a new [Game Server Login Token (GSLT)](https://steamcommunity.com/dev/managegameservers) must be created and specified.
    The App ID for NMRIH is: 317670