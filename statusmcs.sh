#!/bin/bash

# Überprüfe, ob der Minecraft-Server-Service läuft
if sudo systemctl is-active --quiet minecraft.service; then
  echo "Der Minecraft-Server-Service läuft."

  read -p "Möchtest du den Status des Minecraft-Server-Dienstes anzeigen? [j/n]: " view_status

  if [[ $view_status =~ ^[jJ]$ ]]; then
    echo "Zeige den Status des Minecraft-Server-Dienstes an."
    sudo systemctl status minecraft.service
  else
    echo "Status wird nicht angezeigt."
  fi
else
  echo "Der Minecraft-Server-Service läuft nicht."
fi
