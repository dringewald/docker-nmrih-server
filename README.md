# No More Room in Hell - Dockerimage
Dieses Image stellt einen vollfunktionsfähigen No more room in Hell-Server bereit.

## Variablen
|Variable|Wert|Beschreibung|Default|
| ------------- |:-------------:| -----:|
|UPDATEPACKAGES|true / 1|Aktualisiert beim Starten des Images alle Pakete|Nicht gesetzt|
|USERPWD|Passwort|Setzt ein Nutzerpasswort für die Nutzung via SFTP|Nicht gesetzt|
|UPDATECHECK|true / 1|Aktualisiert beim Starten des Images den NMRIH-Server|true|
|VALIDATECHECK|true/ 1|Validiert beim Starten des Images die NMRIH-Dateien|Nicht gesetzt|
|SETPERMS|true / 1|Setzt beim Starten des Images die korrekten Berechtigungen|true|
|SRCDS_RCONPW|Passwort|Setzt das RCON-Passwort|Nicht gesetzt|
|SRCDS_PW|Passwort|Setzt ein Server-Passwort|Nicht gesetzt|
|SRCDS_CLIENT_PORT|Port|Setzt den Client-Port|27010|
|SRCDS_PORT|Port|Setzt den Game-Port|27015|
|SRCDS_TV_PORT|Port|Setzt den TV-Port|27020|
|SRCDS_NET_PUBLIC_ADDRESS|IP-Adresse|Öffentliche IP-Adresse des Servers|Nicht gesetzt|
|SRCDS_MAXPLAYERS|Anzahl Spieler (max 8)|Definiert die maximale Anzahl der Spieler auf dem Server|8|
|SRCDS_STARTMAP|Mapname|Setzt die Startmap|nmo_cabin|
|SRCDS_REGION|Zahl|Setzt die öffentliche Region|3|
|SRCDS_HOSTNAME|Hostname|Setzt den Hostnamen des Servers|Nicht gesetzt|
|SRCDS_TOKEN|Steam Gameserver Login Token|Steamserver-Login-Token für öffentliche Server|Nicht gesetzt|