# minecraft_server_setup_raspberrypi
This is a repro for my Project of creating the perfect Minecraft Server for a RaspberryPi. 
# Minecraft Server Setup für Raspberry Pi

Dieses Repository enthält Skripte und Anweisungen zur Einrichtung eines Minecraft-Servers auf einem Raspberry Pi.

## Inhaltsverzeichnis

- [Voraussetzungen](#voraussetzungen)
- [Installation](#installation)
- [Verwendung](#verwendung)
- [Skripte](#skripte)
- [Service](#service)
- [Backup](#backup)
- [Updates](#updates)
- [Troubleshooting](#troubleshooting)
- [Admin Tool (Web UI)](#admin-tool-web-ui)

## Voraussetzungen

- Ein Raspberry Pi mit Raspbian OS installiert
- Internetverbindung
- Grundlegende Kenntnisse im Umgang mit der Kommandozeile

## Installation

1. Klone dieses Repository auf deinen Raspberry Pi:

    ```sh
    git clone <repository-url>
    cd <repository-name>
    ```

2. Führe das Installationsskript aus:

    ```sh
    sudo chmod +x install_mcs.sh

    sudo ./install_mcs.sh
    ```

Dieses Skript wird alle notwendigen Verzeichnisse und Dateien einrichten, die erforderliche Software installieren und den Minecraft-Server konfigurieren und starten.

## Verwendung

Installiere am besten noch ufw (Uncomplicated Firewall) und schließe alle Eingänge außer 22 (ssh) und der Port deines Minecraftserver (ggf. noch andere).

```sh
sudo apt install ufw

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow 22/tcp
sudo ufw allow 25565/tcp

sudo ufw enable

```

Außerdem macht es Sinn DuckDNS zu verwenden. Das ist alles auf deren Seite erklärt.

### Starten des Servers

Um den Minecraft-Server zu starten, führe folgendes Skript aus:

```sh
./startmcs.sh
```

## Skripte

- `install_mcs.sh`: Erstinstallation (Ordner, Service, Pakete, PaperMC, Cronjob).
- `startmcs.sh`: Startet den `minecraft.service` interaktiv.
- `stopmcs.sh`: Stoppt den `minecraft.service` interaktiv.
- `statusmcs.sh`: Zeigt bei Bedarf den Status von `minecraft.service`.
- `minecraft-backup.sh`: Erstellt ein Welt-Backup (für Cronjob gedacht).
- `paperupdate.sh`: Lädt die neueste PaperMC-Version herunter.
- `start-minecraft.sh` / `stop-minecraft.sh`: Interne Service-Skripte.
- `log_player_activity.sh`: Loggt Join/Leave/Disconnect-Ereignisse aus `latest.log`.

## Service

Der Server wird als `systemd`-Dienst (`minecraft.service`) betrieben.

```sh
sudo systemctl status minecraft.service
sudo systemctl start minecraft.service
sudo systemctl stop minecraft.service
sudo systemctl restart minecraft.service
```

## Backup

Bei der Installation wird ein täglicher Cronjob für den User `pi` eingetragen:

```cron
0 4 * * * /bin/bash /home/pi/mcs/mcs_backup/minecraft-backup.sh
```

Der Job stoppt den Dienst (falls aktiv), erstellt ein `.tar.gz`-Backup der Welten und startet den Dienst danach wieder.

## Updates

Für ein PaperMC-Update:

```sh
cd /home/pi/mcs/mc_server
./paperupdate.sh
sudo systemctl restart minecraft.service
```

## Troubleshooting

- Dienst startet nicht: `sudo journalctl -u minecraft.service -n 200 --no-pager`
- Java fehlt: `java -version` prüfen, ggf. Java erneut installieren.
- Screen-Konsole öffnen: `screen -r minecraft_server`
- Port nicht erreichbar: Router-Portfreigabe + UFW-Regeln prüfen.

## Admin Tool (Web UI)

Dieses Repo enthält eine einfache Admin-Oberfläche mit:

- Serverstatus, Online-Spieler, CPU/RAM/Disk/Temperatur
- Log-Ansichten (Errors, Player Activity, Chat, Service)
- Buttons für Start/Stop/Restart, Backup und Paper-Update
- Chat senden und Minecraft-Commands ausführen
- Bearbeiten von `server.properties`
- Terminal-Kommando für eine kompakte Statusübersicht

### Installation auf dem Pi

```sh
chmod +x install_admin_tool.sh
./install_admin_tool.sh
```

Danach:

1. Passwort setzen in `/home/pi/mcs/admin/.env` (`MCS_ADMIN_PASSWORD`).
2. Admin-Service neu starten: `sudo systemctl restart mcs-admin.service`
3. Web UI öffnen: `http://<raspberrypi-ip>:8080`
4. Status in CLI: `mcs-admin-status`
