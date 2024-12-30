#!/bin/bash

# Setze den Pfad zur screen-Installation
SCREEN_BIN=/usr/bin/screen

# Setze den Namen der screen-Sitzung
SCREEN_SESSION_NAME="minecraft_server"

# Sende Nachricht, dass der Server heruntergefahren wird und die Karte gespeichert wird
echo "Server shutting down in 10 seconds. Saving map..."
$SCREEN_BIN -p 0 -S $SCREEN_SESSION_NAME -X eval 'stuff "say Server shutting down in 10 seconds. Saving map..."\015'

# Sende Befehl, um die Karte zu speichern
echo "Saving map..."
$SCREEN_BIN -p 0 -S $SCREEN_SESSION_NAME -X eval 'stuff "save-all"\015'

# Warte 20 Sekunden, um dem Speicherprozess genug Zeit zu geben
echo "Waiting 40 seconds for the save process to complete..."
sleep 40

# Sende Befehl, um den Minecraft-Server zu stoppen
echo "Stopping Minecraft server..."
$SCREEN_BIN -p 0 -S $SCREEN_SESSION_NAME -X eval 'stuff "stop"\015'

# Warte 60 Sekunden, um dem Server genug Zeit zum Herunterfahren zu geben
echo "Waiting 30 seconds for the server to shut down..."
sleep 30

# Ausgabe, dass der Server gestoppt wurde
echo "Minecraft server stopped."
