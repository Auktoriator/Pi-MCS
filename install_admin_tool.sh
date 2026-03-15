#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADMIN_SRC_DIR="$BASE_DIR/admin_ui"
ADMIN_DST_DIR="/home/pi/mcs/admin"
SERVICE_DST="/etc/systemd/system/mcs-admin.service"
SUDOERS_FILE="/etc/sudoers.d/mcs-admin"
ENV_FILE="$ADMIN_DST_DIR/.env"
ALIAS_LINE="alias mcs-admin-status='/home/pi/mcs/admin/mcsadmin.sh'"

echo "=== Installing Pi-MCS admin tool ==="

if [ ! -d "$ADMIN_SRC_DIR" ]; then
  echo "Error: $ADMIN_SRC_DIR not found."
  exit 1
fi

echo "== Installing dependencies =="
sudo apt-get update
sudo apt-get install -y python3-flask

echo "== Copying admin tool files =="
sudo mkdir -p "$ADMIN_DST_DIR/templates"
sudo cp "$ADMIN_SRC_DIR/app.py" "$ADMIN_DST_DIR/app.py"
sudo cp "$ADMIN_SRC_DIR/templates/index.html" "$ADMIN_DST_DIR/templates/index.html"
sudo cp "$ADMIN_SRC_DIR/mcsadmin.sh" "$ADMIN_DST_DIR/mcsadmin.sh"
sudo chmod +x "$ADMIN_DST_DIR/mcsadmin.sh"

if [ ! -f "$ENV_FILE" ]; then
  echo "== Creating default .env (please edit password afterwards) =="
  sudo tee "$ENV_FILE" >/dev/null <<'EOF'
MCS_ADMIN_USER=admin
MCS_ADMIN_PASSWORD=CHANGE_ME_NOW
MCS_ADMIN_HOST=0.0.0.0
MCS_ADMIN_PORT=8080
MCS_SCREEN_SESSION=minecraft_server
# Optional:
# MCS_ALLOW_HOST_POWER=1
EOF
  sudo chmod 600 "$ENV_FILE"
fi

sudo chown -R pi:pi "$ADMIN_DST_DIR"

echo "== Installing service =="
sudo cp "$ADMIN_SRC_DIR/mcs-admin.service" "$SERVICE_DST"
sudo chmod 644 "$SERVICE_DST"

echo "== Configuring sudo permissions for admin actions =="
sudo tee "$SUDOERS_FILE" >/dev/null <<'EOF'
pi ALL=(root) NOPASSWD: /bin/systemctl start minecraft.service, /bin/systemctl stop minecraft.service, /bin/systemctl restart minecraft.service, /bin/systemctl is-active minecraft.service, /bin/systemctl show minecraft.service, /bin/bash /home/pi/mcs/mcs_backup/minecraft-backup.sh, /bin/bash /home/pi/mcs/mc_server/paperupdate.sh
# Optional host power commands (uncomment only if you want them):
# pi ALL=(root) NOPASSWD: /bin/systemctl reboot, /bin/systemctl poweroff
EOF
sudo chmod 440 "$SUDOERS_FILE"
sudo visudo -cf "$SUDOERS_FILE"

echo "== Enabling service =="
sudo systemctl daemon-reload
sudo systemctl enable --now mcs-admin.service

if ! grep -Fq "$ALIAS_LINE" /home/pi/.bash_aliases 2>/dev/null; then
  echo "$ALIAS_LINE" >> /home/pi/.bash_aliases
fi

echo "=== Done ==="
echo "1) Set a secure password in: $ENV_FILE"
echo "2) Restart admin service: sudo systemctl restart mcs-admin.service"
echo "3) Open UI: http://<raspberrypi-ip>:8080"
echo "4) Terminal summary command: mcs-admin-status"
