#stop-minecraft.sh
#by FO

#!/bin/bash

SCREEN_BIN=/usr/bin/screen
SCREEN_SESSION_NAME="minecraft_server"
PID_FILE="/home/pi/mcs/mc_server/minecraft.pid"

echo "Server shutting down in 10 seconds. Saving map..."
$SCREEN_BIN -p 0 -S $SCREEN_SESSION_NAME -X eval 'stuff "say Server shutting down in 10 seconds. Saving map..."\015'

echo "Saving map..."
$SCREEN_BIN -p 0 -S $SCREEN_SESSION_NAME -X eval 'stuff "save-all"\015'
echo "Waiting 40 seconds for the save process to complete..."
sleep 40

echo "Stopping Minecraft server..."
$SCREEN_BIN -p 0 -S $SCREEN_SESSION_NAME -X eval 'stuff "stop"\015'
echo "Waiting 30 seconds for the server to shut down..."
sleep 30

# Optional: Danach Screen-Sitzung killen, falls noch vorhanden
$SCREEN_BIN -ls | grep "$SCREEN_SESSION_NAME" && $SCREEN_BIN -S "$SCREEN_SESSION_NAME" -X quit

# Prüfen, ob PID-Datei existiert und ggf. löschen
if [ -f "$PID_FILE" ]; then
  rm -f "$PID_FILE"
  echo "PID file removed."
fi

echo "Minecraft server stopped."
