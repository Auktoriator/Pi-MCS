#start-minecraft.sh
#by FO

#!/bin/bash

# Pfad zur Java-Installation
JAVA_HOME=/home/pi/.sdkman/candidates/java/current

# Pfad zum Minecraft-Server-Verzeichnis
MC_SERVER_DIR=/home/pi/mcs/mc_server

# Heap-Größe
MC_HEAP_SIZE=2G

# Name der Screen-Sitzung
SCREEN_SESSION_NAME="minecraft_server"

# PID-Datei (muss mit dem Eintrag in der .service übereinstimmen)
PID_FILE="/home/pi/mcs/mc_server/minecraft.pid"

cd "$MC_SERVER_DIR" || {
  echo "Error: Could not change to directory $MC_SERVER_DIR"
  exit 1
}

echo "=== Starting Minecraft server in screen session: $SCREEN_SESSION_NAME ==="

# 1. Starte den Server (Java) in einer detach-ten Screen-Sitzung
#    (Wichtig: & braucht man hier nicht unbedingt, screen selbst forkt bereits.)
screen -S "$SCREEN_SESSION_NAME" -dm \
  "$JAVA_HOME/bin/java" -Xms"$MC_HEAP_SIZE" -Xmx"$MC_HEAP_SIZE" -XX:+UseG1GC -jar "$MC_SERVER_DIR/paper.jar" nogui

# 2. Kurze Pause, damit screen sicher gestartet ist
sleep 2

# 3. Ermittle die PID des Screen-Prozesses (nicht des Java-Prozesses!)
SCREEN_PID=$(pgrep -f "SCREEN.*$SCREEN_SESSION_NAME")

if [ -n "$SCREEN_PID" ]; then
  echo "$SCREEN_PID" > "$PID_FILE"
  echo "Minecraft server started with screen PID: $SCREEN_PID"
else
  echo "Error: Could not find screen PID!"
  exit 1
fi

exit 0

