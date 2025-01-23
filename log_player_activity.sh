#!/bin/bash

# Pfade konfigurieren
MINECRAFT_LOG_DIR="/home/pi/mcs/mc_server/logs"
OUTPUT_LOG="/home/pi/mcs/player_activity.log"

# Falls nötig: Logdatei initialisieren
if [ ! -f "$OUTPUT_LOG" ]; then
    echo "Player Activity Log" > "$OUTPUT_LOG"
    echo "-------------------" >> "$OUTPUT_LOG"
fi

# Live-Verarbeitung des Logs
tail -F "$MINECRAFT_LOG_DIR/latest.log" | while read LINE
do
    # 1) UUID-Zeile z.B.:
    # [11:37:10] [User Authenticator #4/INFO]: UUID of player XXX is YYY
    if [[ "$LINE" =~ ^\[(.*)\]\ \[[^\]]*\]:\ UUID\ of\ player\ ([^[:space:]]+)\ is\ ([0-9a-fA-F-]+)$ ]]; then
        TIME="${BASH_REMATCH[1]}"
        PLAYER="${BASH_REMATCH[2]}"
        UUID="${BASH_REMATCH[3]}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [$TIME] Player $PLAYER has UUID $UUID" >> "$OUTPUT_LOG"
        continue
    fi

    # 2) Spieler betritt das Spiel:
    # [11:34:20] [Server thread/INFO]: XXX joined the game
    if [[ "$LINE" =~ ^\[(.*)\]\ \[[^\]]*\]:\ ([^[:space:]]+)\ joined\ the\ game$ ]]; then
        TIME="${BASH_REMATCH[1]}"
        PLAYER="${BASH_REMATCH[2]}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [$TIME] $PLAYER joined the game" >> "$OUTPUT_LOG"
        continue
    fi

    # 3) Spieler verliert Verbindung, inkl. Grund:
    # [11:34:30] [Server thread/INFO]: XXX lost connection: Disconnected
    if [[ "$LINE" =~ ^\[(.*)\]\ \[[^\]]*\]:\ ([^[:space:]]+)\ lost\ connection:\ (.*)$ ]]; then
        TIME="${BASH_REMATCH[1]}"
        PLAYER="${BASH_REMATCH[2]}"
        REASON="${BASH_REMATCH[3]}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [$TIME] $PLAYER lost connection: $REASON" >> "$OUTPUT_LOG"
        continue
    fi

    # 4) Spieler verlässt das Spiel (z. B. „left the game“):
    # [11:34:30] [Server thread/INFO]: XXX left the game
    if [[ "$LINE" =~ ^\[(.*)\]\ \[[^\]]*\]:\ ([^[:space:]]+)\ left\ the\ game$ ]]; then
        TIME="${BASH_REMATCH[1]}"
        PLAYER="${BASH_REMATCH[2]}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [$TIME] $PLAYER left the game" >> "$OUTPUT_LOG"
        continue
    fi

    # 5) „Disconnecting ...“ (Whitelist-Kick, etc.)
    # [11:37:10] [Server thread/INFO]: Disconnecting XXX (/IP): Grund ...
    if [[ "$LINE" =~ ^\[(.*)\]\ \[[^\]]*\]:\ Disconnecting\ ([^[:space:]]+)\ \(([^)]*)\):\ (.*)$ ]]; then
        TIME="${BASH_REMATCH[1]}"
        PLAYER="${BASH_REMATCH[2]}"
        ADDRESS="${BASH_REMATCH[3]}"
        REASON="${BASH_REMATCH[4]}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [$TIME] Disconnecting $PLAYER [$ADDRESS]: $REASON" >> "$OUTPUT_LOG"
        continue
    fi

done