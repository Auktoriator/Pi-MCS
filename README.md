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

2. Führe das Installationsskript aus:
    ```sh
    sudo ./install_mcs.sh
    ```

Dieses Skript wird alle notwendigen Verzeichnisse und Dateien einrichten, die erforderliche Software installieren und den Minecraft-Server konfigurieren und starten.

## Verwendung

### Starten des Servers

Um den Minecraft-Server zu starten, führe folgendes Skript aus:
```sh
./startmcs.sh