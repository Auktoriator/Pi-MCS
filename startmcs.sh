#startmcs.sh
#by FO

#!/bin/bash

# Überprüfe, ob der Minecraft-Server-Service bereits läuft
if sudo systemctl is-active --quiet minecraft.service; then
  echo "Der Minecraft-Server-Service läuft bereits."
else
  read -p "Möchtest du den Minecraft-Server starten? [j/n]: " start_server

  if [[ $start_server =~ ^[jJ]$ ]]; then
    echo "=== Starte den Minecraft-Server... ==="
    sudo systemctl start minecraft.service
    #echo "=== Zeige die Logs des Minecraft-Server-Dienstes in Echtzeit an. Drücke Ctrl+C, um die Anzeige zu beenden. ==="
    #sudo journalctl -u minecraft.service -f
    sleep 60
    echo "Fertig!"
  else
    echo "Minecraft-Server wird nicht gestartet."
  fi
fi
