#!/bin/bash

# Pfade und Variablen
MINECRAFT_LOG_DIR="/home/pi/mcs/mc_server/logs"
OUTPUT_LOG="/home/pi/mcs/player_activity.log"

# Überprüfen, ob das Output-Log existiert, ansonsten erstellen
if [ ! -f "$OUTPUT_LOG" ]; then
    echo "Player Activity Log" > "$OUTPUT_LOG"
    echo "-------------------" >> "$OUTPUT_LOG"
fi

# Überwachung der Logs
tail -F "$MINECRAFT_LOG_DIR/latest.log" | while read LINE
do
    # Spieler-Login erfassen
    if echo "$LINE" | grep -q "joined the game"; then
        PLAYER=$(echo "$LINE" | awk '{print $5}')
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $PLAYER joined the game" >> "$OUTPUT_LOG"
    fi

    # Spieler-Logout erfassen
    if echo "$LINE" | grep -q "left the game"; then
        PLAYER=$(echo "$LINE" | awk '{print $5}')
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $PLAYER left the game" >> "$OUTPUT_LOG"
    fi
done