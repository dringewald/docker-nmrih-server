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

## Goal of this project
The goal of this container image is to provide an easy to run No More Room in Hell gameserver in a container which follows the best practices.
I did not find images that were easy to understand. Most were optimized for their own needs. With this image I try to provide you an easy container for your favorite game.

## Usage
Start the Docker container and make sure to mount a directory or volume to keep the files persistent:

    docker run -p 27010:27010 -p 27015:27015 -p 27820:27020 \
    -v ~/nmrih-persistent-folder:/home/nmrih/server \
    holt31/nmrih-server:latest

Or if you want to use a different startmap, you could set that via a variable as follows:

    docker run -p 27010:27010 -p 27015:27015 -p 27820:27020 \
    -v ~/nmrih-persistent-folder:/home/nmrih/server \
    -e NMRIH_STARTMAP=nmo_broadway \
    holt31/nmrih-server:latest

#### User Password for the nmrih user

---
You should set a user password for the nmrih user via the NMRIH_USERPWD variable, otherwise a random password will be generated at every start of the container.  
It is highly recommand to use a docker secret for the user. I created the image to support a secret with the name "nmrih_userpwd".  
You can achieve the use of the secret by using the following commands. Please make sure to adjust the password correctly.  

    echo "your_password_here" | docker secret create nmrih_userpwd -

Now run the container with the following command:

    docker run -p 27010:27010 -p 27015:27015 -p 27820:27020 \ 
    -v ~/nmrih-persistent-folder:/home/nmrih/server \
    --secret nmrih_userpwd \
    holt31/nmrih-server:latest

If you don't want to use a secret, then you could also manually set the variable NMRIH_USERPWD.  
It is not advised to do so, due to security risks.  
Even if it isn't recommand, it is needed in some cases.  

    docker run -p 27010:27010 -p 27015:27015 -p 27820:27020 \ 
    -v ~/nmrih-persistent-folder:/home/nmrih/server \
    -e NMRIH_USERPWD=yourpassword \
    holt31/nmrih-server:latest

#### SFTP Usage

---
In some environments, for example in kubernetes clusters, it is needed or more comfortable to access the gameserver files via SFTP.  
This methode is the most convient one in some special cases.  
The image has an openssh server included, to use SFTP.  
By default it is disabeld and will not start when the image is started, but it can be activated by the use of variables.  

This example allows login via your provided SSH public key.

    docker run -p 22:22 -p 27010:27010 -p 27015:27015 -p 27820:27020 \ 
    -v ~/nmrih-persistent-folder:/home/nmrih/server \
    -e ENABLESSH="true" \
    -e SSHKey="ecdsa-sha2-nistp521 AAAAE2... user1@example.com" \
    holt31/nmrih-server:latest

It is also possible to specify multiple SSH public keys by using ; as a delimiter beetween them.

    docker run -p 22:22 -p 27010:27010 -p 27015:27015 -p 27820:27020 \ 
    -v ~/nmrih-persistent-folder:/home/nmrih/server \
    -e ENABLESSH="true" \
    -e SSHKey="SSHKEY=ssh-rsa AAAAB3... user1@example.com;ssh-rsa AAAAB3... user2@example.com" \
    holt31/nmrih-server:latest

The following example allows the use of your password via the secret.

    docker run -p 22:22 -p 27010:27010 -p 27015:27015 -p 27820:27020 \ 
    -v ~/nmrih-persistent-folder:/home/nmrih/server \
    -e ENABLESSH="true" \
    -e ENABLEPWD="true" \
    --secret nmrih_userpwd \
    holt31/nmrih-server:latest

The following run command lets the ssh server start with a password set via the variable and allows the use of the password for login as the nmrih user.

    docker run -p 22:22 -p 27010:27010 -p 27015:27015 -p 27820:27020 \ 
    -v ~/nmrih-persistent-folder:/home/nmrih/server \
    -e NMRIH_USERPWD="yourpassword" \
    -e ENABLESSH="true" \
    -e ENABLEPWD="true" \
    holt31/nmrih-server:latest

You could also combine the login via your SSH public key and your password.  
This could be useful if you need it for automatitions were programs can't use your ssh key.

    docker run -p 22:22 -p 27010:27010 -p 27015:27015 -p 27820:27020 \ 
    -v ~/nmrih-persistent-folder:/home/nmrih/server \
    -e ENABLESSH="true" \
    -e ENABLEPWD="true" \
    -e SSHKey="ecdsa-sha2-nistp521 AAAAE2... user1@example.com" \
    --secret nmrih_userpwd \
    holt31/nmrih-server:latest

## Variables

Here you'll find a list of every variable that can be set in the container.  
Almost every start parameter of the gameserver is settable via a variable.  
You could also specify missing parameters via the variable "NMRIH_ADDITIONAL_ARGS".  
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
|NMRIH_SETPERMS|true / 1|Sets the correct permissions when starting the image|false|
|NMRIH_RCONPW|Password|Sets the RCON password|Not set|
|NMRIH_PW|Password|Sets a server password|Not set|
|NMRIH_CLIENT_PORT|Port|Sets the client port|27010|
|NMRIH_PORT|Port|Sets the game port|27015|
|NMRIH_TV_PORT|Port|Sets the TV port|27020|
|NMRIH_IP_ADDRESS|IP address|IP address to which the server should listen|0.0.0.0|
|NMRIH_NET_PUBLIC_ADDRESS|IP address|Public IP address of the server|0.0.0.0|
|NMRIH_MAXPLAYERS|Number of players (max 8)|Defines the maximum number of players on the server|8|
|NMRIH_STARTMAP|Mapname|Sets the start map|nmo_cabin|
|NMRIH_REGION|Number|Sets the public region|3|
|NMRIH_TOKEN|Steam Gameserver Login Token|Steamserver login token for public servers|Not set|
|NMRIH_AUTH_KEY|Workshop key|Workshop key for files from the workshop|Not set|
|NMRIH_CONFIG_FILE|Config file|Determines the name of the config file|server.cfg|
|NMRIH_ADDITIONAL_ARGS|Other configuration parameters|Determines other, non-existent parameters|Not set|