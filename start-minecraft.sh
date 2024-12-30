#start-minecraft.sh
#by FO

#!/bin/bash

# Setze den Pfad zur Java-Installation
JAVA_HOME=/home/pi/.sdkman/candidates/java/current

# Setze den Pfad zum Minecraft-Server-Verzeichnis
MC_SERVER_DIR=/home/pi/mcs/mc_server

# Setze die Heap-Größe für den Minecraft-Server
MC_HEAP_SIZE=3G

# Setze den Namen der screen-Sitzung
SCREEN_SESSION_NAME="minecraft_server"

# Ermittle die Anzahl der verfügbaren CPU-Kerne
CPU_CORES=$(nproc)

# Konsolenausgabe vor dem Start des Minecraft-Servers
echo "Starting Minecraft server in a screen session with session name: $SCREEN_SESSION_NAME"

# Starte den Minecraft-Server in einer screen-Sitzung
screen -S $SCREEN_SESSION_NAME -dm $JAVA_HOME/bin/java -Xms$MC_HEAP_SIZE -Xmx$MC_HEAP_SIZE -XX:+UseG1GC -jar $MC_SERVER_DIR/paper.jar nogui

# Konsolenausgabe nach dem Start des Minecraft-Servers
echo "Minecraft server started. To attach to the screen session, run:"
echo "screen -r $SCREEN_SESSION_NAME"
