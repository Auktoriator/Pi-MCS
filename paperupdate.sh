#paperupdate.sh
#by FO

#!/bin/bash

echo "Update Paper.."

# 1. Neue API-URL verwenden
LATEST_VERSION=$(curl -s https://api.papermc.io/v2/projects/paper | jq -r '.versions[-1]')
BUILD_NUMBER=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$LATEST_VERSION" | jq -r '.builds[-1]')

# 2. Download-URL zusammenbauen
DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/$LATEST_VERSION/builds/$BUILD_NUMBER/downloads/paper-$LATEST_VERSION-$BUILD_NUMBER.jar"

# 3. Jar herunterladen
sudo wget -O paper.jar "$DOWNLOAD_URL"

if [ $? -ne 0 ]; then
  echo "Failed to download the latest PaperMC version. Exiting."
  exit 1
fi

echo "PaperMC heruntergeladen!"
