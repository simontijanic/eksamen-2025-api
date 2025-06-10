#!/bin/bash
# Setup script for Ubuntu 22: Node.js (via NVM), PM2, and Nginx for foxvote-api only
# Usage: sudo bash setup_foxvote_server.sh https://github.com/simontijanic/eksamen-2025-api.git  /home/ubuntu/foxvote-api

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

if [ $# -ne 2 ]; then
  echo "Usage: $0 <git_repo_url> <api_folder>"
  exit 1
fi

GIT_REPO="$1"
API_FOLDER="$2"

# 1. Oppdater og installer avhengigheter
apt update && apt upgrade -y
apt install -y curl git unzip nginx

# 2. Installer NVM (Node Version Manager)
if ! command -v nvm &> /dev/null; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# 3. Klon kun api-prosjektet til dev-brukerens hjemmemappe hvis SUDO_USER er satt
if [ "$SUDO_USER" ]; then
  API_FOLDER="/home/$SUDO_USER/foxvote-api"
  if [ ! -d "$API_FOLDER" ]; then
    sudo -u $SUDO_USER git clone "$GIT_REPO" "$API_FOLDER"
  fi
  cd "$API_FOLDER"
else
  if [ ! -d "$API_FOLDER" ]; then
    git clone "$GIT_REPO" "$API_FOLDER"
  fi
  cd "$API_FOLDER"
fi

# 3b. Lag .env fra eksempel hvis ikke finnes
if [ ! -f .env ]; then
  cp .env.example .env
fi

# 4. Installer siste versjon av Node.js via NVM
nvm install node
nvm use node

# 5. Installer avhengigheter og PM2
# Installer PM2 globalt for både root og dev-bruker (eller SUDO_USER)
npm install -g pm2@latest
if [ "$SUDO_USER" ]; then
  sudo -u $SUDO_USER npm install -g pm2@latest
fi
npm install

# 6. Start API med PM2
pm2 start index.js --name foxapi
pm2 save

# 7. Sett opp Nginx reverse proxy
cat >/etc/nginx/sites-available/foxvote-api <<EOL
server {
    listen 80;
    server_name _;

    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOL

ln -sf /etc/nginx/sites-available/foxvote-api /etc/nginx/sites-enabled/foxvote-api
nginx -t && systemctl reload nginx

echo "\n--- Ferdig! ---"
echo "API kjører på http://<server-ip>/api/"
echo "API-mappe: $API_FOLDER"
echo "PM2 status: pm2 status"
echo "Nginx reverse proxy er satt opp."
