#install_mcs.sh
#by FO

#!/bin/bash

#Globale Variablen

  MC_DIR="/home/pi/mcs"
  MC_SERVER_DIR="/home/pi/mcs/mc_server"
  MC_BACKUP_DIR="/home/pi/mcs/mcs_backup"
  SERVICE_DIR="/etc/systemd/system"


#Funktionen

setup_directories(){

  echo "===== Setting up directories... ====="
  sleep 2

  # Verzeichnisse erstellen
  sudo mkdir -p $MC_DIR
  sudo mkdir -p $MC_SERVER_DIR
  sudo mkdir -p $MC_BACKUP_DIR

  # Skripte und Service in Verzeichnisse kopieren
  echo "==== Skripte kopieren... ===="
  sudo cp minecraft.service   $SERVICE_DIR
  sudo cp start-minecraft.sh  $MC_SERVER_DIR
  sudo cp stop-minecraft.sh   $MC_SERVER_DIR
  sudo cp paperupdate.sh   $MC_SERVER_DIR
  sudo cp startmcs.sh         $MC_DIR
  sudo cp stopmcs.sh          $MC_DIR
  sudo cp statusmcs.sh        $MC_DIR
  sudo cp minecraft-backup.sh $MC_BACKUP_DIR

  # Pi als Besitzer setzen
  sudo chown -R pi:pi $MC_DIR

  # Skripte ausführbar machen
  sudo chmod +x $MC_SERVER_DIR/start-minecraft.sh
  sudo chmod +x $MC_SERVER_DIR/stop-minecraft.sh
  sudo chmod +x $MC_SERVER_DIR/paperupdate.sh
  sudo chmod +x $MC_DIR/startmcs.sh
  sudo chmod +x $MC_DIR/stopmcs.sh
  sudo chmod +x $MC_DIR/statusmcs.sh
  sudo chmod +x $MC_BACKUP_DIR/minecraft-backup.sh
  echo "==== Skripte kopiert! ===="

  echo "===== Setting up directories done! ====="
  sleep 2

}

install_software(){

  echo "===== Installing software... ====="
  sleep 2

  # Update und Upgrade des Raspberry Pi
  echo "==== System updaten... ===="
  sudo apt update
  sudo apt upgrade -y
  echo "==== Update fertig! ===="

  # Installation von SDKMAN und Java
  echo "==== Lade SDKMAN herunter und installiere Java... ===="
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install java
  echo "==== Java installiert! ===="

  # Installation von screen und jq
  echo "==== Installiere screen und jq... ===="
  sudo apt-get install -y screen jq
  echo "==== Screen und jq installiert! ===="

  echo "===== Installing software done! ====="
  sleep 2

}

download_papermc(){

  echo "===== Downloading PaperMC... ====="
  sleep 2

  # Herunterladen des Minecraft-Servers
  cd $MC_SERVER_DIR
  LATEST_VERSION=$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions[-1]')
  BUILD_NUMBER=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/$LATEST_VERSION" | jq -r '.builds[-1]')
  DOWNLOAD_URL="https://papermc.io/api/v2/projects/paper/versions/$LATEST_VERSION/builds/$BUILD_NUMBER/downloads/paper-$LATEST_VERSION-$BUILD_NUMBER.jar"
  sudo wget -O paper.jar $DOWNLOAD_URL
  if [ $? -ne 0 ]; then
    echo "==== Failed to download the latest PaperMC version. Exiting. ===="
    exit 1
  fi
  echo "===== Downloading PaperMC done! ====="
  sleep 2

}

configure_minecraft_server(){

echo "===== Configuring the Minecraft-Server... ====="
sleep 2

#Konfigurieren des Minecraft-Servers
echo "==== Konfigurieren des Minecraft Servers... ===="
sleep 1
  # Eula erstellen
sudo bash -c 'echo "eula=true" > eula.txt'

sudo systemctl daemon-reload

  #Minecraft-Server automatisch beim Start hochfahren lassen
sudo systemctl enable minecraft.service

echo "alias minecraft-console='screen -r minecraft_server'" >> ~/.bash_aliases
source ~/.bash_aliases

echo "===== Configuring the Minecraft-Server done! Der Server startet nun automatisch beim Start/Neustart des RaspberryPi's! ====="
sleep 2

}

configure_backup(){

echo "===== Configuring the daily backup... =====" 
sleep 2

#Tägliches Backup um 4 Uhr morgens konfigurieren
(crontab -l 2>/dev/null; echo "0 4 * * * /bin/bash /home/pi/mcs/mcs_backup/minecraft-backup.sh") | crontab -

echo "===== Configuring the daily backup done! The backup will be every night at 4am. ====="
sleep 2

}

start_minecraft_server(){


echo "===== Starting the Minecraft-Server... This may take a while... ====="
sleep 2

#Minecraft Server starten.
sudo systemctl start minecraft.service
sleep 60

echo " "
echo " "
echo "====== Starting the Minecraft-Server done! The Server will now automatically start after booting the RaspberryPi. ======"
sleep 2


}

echo "Minecraft Server wird erstellt..."

setup_directories
install_software
download_papermc
configure_minecraft_server
configure_backup
start_minecraft_server

echo "Minecraft-Server eingerichtet und gestartet!"
echo "Schreibe 'minecraft-console' ins Terminal um auf die Konsole des Minecraft Server zuzugreifen."
echo "Um den Server zu stoppen ./stopmcs.sh ausführen. "
echo "Die server-properties Datei muss noch bearbeitet werden und der Port auf dem WLAN Router geöffnet werden damit alles fuktioniert."
echo "Viel Spaß!"
sleep 20
