#minecraft-backup.sh
#by FO

#!/bin/bash
set -euo pipefail

# Pfad zur Minecraft-Welt
WORLD_PATH=/home/pi/mcs/mc_server

# Pfad zur Sicherungsdatei
BACKUP_PATH=/home/pi/mcs/mcs_backup

SERVICE_NAME="minecraft.service"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_PATH/world_$DATE.tar.gz"
WAS_RUNNING=false
PATHS_TO_BACKUP=()

cleanup() {
  # Failsafe: Wenn der Dienst vor dem Backup lief, nach Fehlern wieder starten.
  if [ "$WAS_RUNNING" = true ] && ! sudo systemctl is-active --quiet "$SERVICE_NAME"; then
    if sudo systemctl start "$SERVICE_NAME"; then
      echo "Failsafe: Minecraft-Dienst wurde nach Fehlerfall wieder gestartet."
    else
      echo "Warnung: Minecraft-Dienst konnte im Failsafe nicht gestartet werden." >&2
    fi
  fi
}

collect_world_dirs() {
  local level_name="world"
  local props_file="$WORLD_PATH/server.properties"

  if [ -f "$props_file" ]; then
    level_name="$(grep -E '^level-name=' "$props_file" | tail -n1 | cut -d= -f2-)"
    if [ -z "$level_name" ]; then
      level_name="world"
    fi
  fi

  local candidates=("$level_name" "${level_name}_nether" "${level_name}_the_end")
  for dir in "${candidates[@]}"; do
    if [ -d "$WORLD_PATH/$dir" ]; then
      PATHS_TO_BACKUP+=("$WORLD_PATH/$dir")
    fi
  done

  # Fallback: Suche alle Weltordner über level.dat
  if [ "${#PATHS_TO_BACKUP[@]}" -eq 0 ]; then
    local d
    for d in "$WORLD_PATH"/*; do
      if [ -d "$d" ] && [ -f "$d/level.dat" ]; then
        PATHS_TO_BACKUP+=("$d")
      fi
    done
  fi
}

trap cleanup EXIT

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
collect_world_dirs

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
