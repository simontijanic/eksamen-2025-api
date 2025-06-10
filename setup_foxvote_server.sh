#!/bin/bash
# Setup script for Ubuntu 22: Node.js (via FNM), PM2, and Nginx for foxvote-api only
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

# 2. Installer FNM (Fast Node Manager)
if ! command -v fnm &> /dev/null; then
  curl -fsSL https://fnm.vercel.app/install | bash
  export PATH="$HOME/.fnm:$PATH"
  eval "$(fnm env)"
fi

# 3. Klon kun api-prosjektet
if [ ! -d "$API_FOLDER" ]; then
  git clone "$GIT_REPO" "$API_FOLDER"
fi
cd "$API_FOLDER"

# 3b. Lag .env fra eksempel hvis ikke finnes
if [ ! -f .env ]; then
  cp .env.example .env
fi

# 4. Installer siste versjon av Node.js via FNM
export PATH="$HOME/.fnm:$PATH"
eval "$(fnm env)"
fnm install latest
fnm use latest

# 5. Installer avhengigheter og PM2
npm install -g pm2
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
