# No More Room in Hell - Dockerimage
Dieses Image stellt einen vollfunktionsfähigen No more room in Hell-Server bereit.

## Variablen
|Variable|Wert|Beschreibung|Default|
| ------------- | ------------- | ------------- | ------------- |
|NMRIH_UPDATEPACKAGES|true / 1|Aktualisiert beim Starten des Images alle Pakete|Nicht gesetzt|
|NMRIH_USERPWD|Passwort|Setzt ein Nutzerpasswort für die Nutzung via SFTP|asaferandomstring|
|NMRIH_UPDATECHECK|true / 1|Aktualisiert beim Starten des Images den NMRIH-Server|true|
|NMRIH_VALIDATECHECK|true/ 1|Validiert beim Starten des Images die NMRIH-Dateien|Nicht gesetzt|
|NMRIH_SETPERMS|true / 1|Setzt beim Starten des Images die korrekten Berechtigungen|true|
|NMRIH_RCONPW|Passwort|Setzt das RCON-Passwort|Nicht gesetzt|
|NMRIH_PW|Passwort|Setzt ein Server-Passwort|Nicht gesetzt|
|NMRIH_CLIENT_PORT|Port|Setzt den Client-Port|27010|
|NMRIH_PORT|Port|Setzt den Game-Port|27015|
|NMRIH_TV_PORT|Port|Setzt den TV-Port|27020|
|NMRIH_IP_ADDRESS|IP-Adresse|IP-Adresse auf die der Server lauschen soll|0.0.0.0|
|NMRIH_NET_PUBLIC_ADDRESS|IP-Adresse|Öffentliche IP-Adresse des Servers|0.0.0.0|
|NMRIH_MAXPLAYERS|Anzahl Spieler (max 8)|Definiert die maximale Anzahl der Spieler auf dem Server|8|
|NMRIH_STARTMAP|Mapname|Setzt die Startmap|nmo_cabin|
|NMRIH_REGION|Zahl|Setzt die öffentliche Region|3|
|NMRIH_TOKEN|Steam Gameserver Login Token|Steamserver-Login-Token für öffentliche Server|Nicht gesetzt|
|NMRIH_AUTH_KEY|Workshop-Key|Workshop-Key für Dateien aus dem Workshop|Nicht gesetzt|
|NMRIH_CONFIG_FILE|Config-Datei|Legt den Namen der Config-Datei fest|server.cfg|
|NMRIH_ADDITIONAL_ARGS|Weitere Konfigurationsparameter|Legt weitere, nicht vorhandene Parameter fest|Nicht gesetzt|