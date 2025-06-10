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

# Ekstra robusthet og backup-planer for vanlige feil
# --------------------------------------------------
# 1. Hvis NVM installasjon feiler, prøv igjen én gang automatisk.
NVM_INSTALL_ATTEMPTS=0
until command -v nvm &> /dev/null || [ $NVM_INSTALL_ATTEMPTS -ge 2 ]; do
  NVM_INSTALL_ATTEMPTS=$((NVM_INSTALL_ATTEMPTS+1))
  echo "Forsøker å installere NVM (forsøk $NVM_INSTALL_ATTEMPTS)..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
done
if ! command -v nvm &> /dev/null; then
  echo "NVM installasjon feilet etter flere forsøk. Avslutter."
  exit 1
fi

# 3. Klon kun api-prosjektet til dev-brukerens hjemmemappe hvis SUDO_USER er satt
if [ "$SUDO_USER" ]; then
  DEV_HOME="/home/$SUDO_USER"
  API_FOLDER="$DEV_HOME/foxvote-api"
  if [ ! -d "$API_FOLDER" ]; then
    sudo -u $SUDO_USER git clone "$GIT_REPO" "$API_FOLDER"
  fi
  cd "$API_FOLDER"
else
  # 2. Hvis git clone feiler, prøv igjen én gang automatisk.
  GIT_CLONE_ATTEMPTS=0
  CLONE_OK=0
  while [ $GIT_CLONE_ATTEMPTS -lt 2 ] && [ ! -d "$API_FOLDER" ]; do
    GIT_CLONE_ATTEMPTS=$((GIT_CLONE_ATTEMPTS+1))
    echo "Kloner repo til $API_FOLDER (forsøk $GIT_CLONE_ATTEMPTS)..."
    git clone "$GIT_REPO" "$API_FOLDER" && CLONE_OK=1 && break
    sleep 2
  done
  if [ ! -d "$API_FOLDER" ]; then
    echo "Klarte ikke å klone repo etter flere forsøk. Avslutter."
    exit 1
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
# Installer PM2 globalt for root
npm install -g pm2@latest

# Installer NVM for dev-brukeren hvis SUDO_USER er satt
if [ "$SUDO_USER" ]; then
  echo "Installerer NVM for dev-bruker $SUDO_USER..."
  sudo -u $SUDO_USER bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
  sudo -u $SUDO_USER bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; nvm install node && nvm use node && npm install -g pm2@latest'
  
  # Installer prosjekt-avhengigheter som dev-bruker i prosjektmappen
  echo "Installerer prosjekt-avhengigheter som dev-bruker..."
  sudo -u $SUDO_USER bash -c "cd '$API_FOLDER' && export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\" && npm install"
else
  # 3. Hvis npm install feiler, prøv igjen én gang automatisk.
  NPM_INSTALL_ATTEMPTS=0
  until npm install || [ $NPM_INSTALL_ATTEMPTS -ge 1 ]; do
    NPM_INSTALL_ATTEMPTS=$((NPM_INSTALL_ATTEMPTS+1))
    echo "npm install feilet, prøver igjen ($NPM_INSTALL_ATTEMPTS)..."
    sleep 2
  done
  if [ $NPM_INSTALL_ATTEMPTS -ge 1 ]; then
    echo "npm install feilet etter flere forsøk. Avslutter."
    exit 1
  fi
fi

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
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Remove default nginx configuration
rm -f /etc/nginx/sites-enabled/default

# Enable foxvote-api configuration
ln -sf /etc/nginx/sites-available/foxvote-api /etc/nginx/sites-enabled/foxvote-api

# Test configuration and reload nginx
nginx -t && systemctl reload nginx

# 4b. Sørg for at NVM lastes automatisk for dev-brukeren i nye shells
if [ "$SUDO_USER" ]; then
  DEV_HOME="/home/$SUDO_USER"
  NVM_INIT='export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
  if ! sudo -u $SUDO_USER grep -q 'nvm.sh' "$DEV_HOME/.bashrc"; then
    echo -e "\n# NVM init for Node.js\n$NVM_INIT" | sudo -u $SUDO_USER tee -a "$DEV_HOME/.bashrc" > /dev/null
  fi
else
  NVM_INIT='export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
  if ! grep -q 'nvm.sh' "$HOME/.bashrc"; then
    echo -e "\n# NVM init for Node.js\n$NVM_INIT" >> "$HOME/.bashrc"
  fi
fi

echo "\n--- Ferdig! ---"
echo "API kjører på http://<server-ip>/api/"
echo "API-mappe: $API_FOLDER"
echo "PM2 status: pm2 status"
echo "Nginx reverse proxy er satt opp."
