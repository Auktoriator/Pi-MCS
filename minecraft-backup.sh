#minecraft-backup.sh
#by FO

#!/bin/bash
set -euo pipefail

# Pfad zur Minecraft-Welt
WORLD_PATH=/home/pi/mcs/mc_server

# Pfad zur Sicherungsdatei
BACKUP_PATH=/home/pi/mcs/mcs_backup

SERVICE_NAME="minecraft.service"
WORLD_DIRS=("MCSWorld" "MCSWorld_nether" "MCSWorld_the_end")
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_PATH/world_$DATE.tar.gz"
WAS_RUNNING=false

mkdir -p "$BACKUP_PATH"

# Minecraft-Server nur stoppen, wenn er läuft
if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
  WAS_RUNNING=true
  sudo systemctl stop "$SERVICE_NAME"

  # Auf sauberen Stop warten (max. 120 Sekunden)
  for _ in {1..24}; do
    if ! sudo systemctl is-active --quiet "$SERVICE_NAME"; then
      break
    fi
    sleep 5
  done

  if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Fehler: Minecraft-Dienst konnte nicht sauber gestoppt werden."
    exit 1
  fi
fi

# Nur vorhandene Welten sichern
PATHS_TO_BACKUP=()
for dir in "${WORLD_DIRS[@]}"; do
  if [ -d "$WORLD_PATH/$dir" ]; then
    PATHS_TO_BACKUP+=("$WORLD_PATH/$dir")
  fi
done

if [ "${#PATHS_TO_BACKUP[@]}" -eq 0 ]; then
  echo "Fehler: Keine Weltordner gefunden. Backup abgebrochen."
  exit 1
fi

# Sicherungskopie der Minecraft-Welt erstellen
tar -czf "$BACKUP_FILE" "${PATHS_TO_BACKUP[@]}"
echo "Backup erstellt: $BACKUP_FILE"

# Dienst wieder starten, wenn er vor dem Backup lief
if [ "$WAS_RUNNING" = true ]; then
  sudo systemctl start "$SERVICE_NAME"
  echo "Minecraft-Dienst wurde nach dem Backup wieder gestartet."
fi
