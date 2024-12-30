#minecraft-backup.sh
#by FO

#!/bin/bash

# Pfad zur Minecraft-Welt
WORLD_PATH=/home/pi/mcs/mc_server

# Pfad zur Sicherungsdatei
BACKUP_PATH=/home/pi/mcs/mcs_backup

# Minecraft-Server herunterfahren
sudo systemctl stop minecraft.service

# Warten, bis der Minecraft-Server heruntergefahren ist
sleep 60

# Sicherungskopie der Minecraft-Welt erstellen
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
mkdir -p $BACKUP_PATH
tar -czvf $BACKUP_PATH/world_$DATE.tar.gz $WORLD_PATH/MCSWorld $WORLD_PATH/MCSWorld_nether $WORLD_PATH/MCSWorld_the_end

# Warten, bis das Backup erstellt wurde
sleep 60

# Raspberry Pi neu starten
sudo shutdown -r now
