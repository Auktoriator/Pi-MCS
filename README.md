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

3. Führe das Installationsskript aus:

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

