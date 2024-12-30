#!/bin/bash

# Überprüfe, ob der Minecraft-Server-Service läuft
if sudo systemctl is-active --quiet minecraft.service; then
  read -p "Möchtest du den Minecraft-Server stoppen? [j/n]: " stop_server

  if [[ $stop_server =~ ^[jJ]$ ]]; then
    echo "Stoppe den Minecraft-Server..."
    sudo systemctl stop minecraft.service
    echo "Fertig!"
    
  else
    echo "Minecraft-Server wird nicht gestoppt."
  fi
else
  echo "Der Minecraft-Server-Service läuft nicht."
fi
