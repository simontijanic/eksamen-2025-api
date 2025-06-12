#!/bin/bash
# Usage: sudo bash setup_joke_server.sh <git_repo_url> <api_folder> [github_actions_token]

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

if [ $# -lt 2 ]; then
  echo "Usage: $0 <git_repo_url> <api_folder> [github_actions_token]"
  exit 1
fi

GIT_REPO="$1"
API_FOLDER="$2"
GITHUB_ACTIONS_TOKEN="$3"

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

# 3. Klon api-prosjektet til valgt mappe
if [ ! -d "$API_FOLDER" ]; then
  git clone "$GIT_REPO" "$API_FOLDER"
fi
cd "$API_FOLDER"

# 3b. Lag .env fra eksempel hvis ikke finnes
if [ ! -f .env ]; then
  cp .env.example .env
fi

# 4. Installer siste versjon av Node.js via NVM
nvm install node
nvm use node

# 5. Installer avhengigheter og PM2
npm install -g pm2@latest
npm install

# 5b. Installer GitHub Actions Runner hvis token er oppgitt
if [ -n "$GITHUB_ACTIONS_TOKEN" ]; then
  GITHUB_ACTIONS_RUNNER_VERSION="2.325.0"
  GITHUB_ACTIONS_RUNNER_URL="https://github.com/actions/runner/releases/download/v${GITHUB_ACTIONS_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_ACTIONS_RUNNER_VERSION}.tar.gz"
  GITHUB_ACTIONS_RUNNER_SHA="5020da7139d85c776059f351e0de8fdec753affc9c558e892472d43ebeb518f4"
  GITHUB_ACTIONS_REPO_URL="$GIT_REPO"
  RUNNER_DIR="$API_FOLDER/actions-runner"
  mkdir -p "$RUNNER_DIR"
  cd "$RUNNER_DIR"
  curl -o actions-runner-linux-x64-${GITHUB_ACTIONS_RUNNER_VERSION}.tar.gz -L "$GITHUB_ACTIONS_RUNNER_URL"
  echo "$GITHUB_ACTIONS_RUNNER_SHA  actions-runner-linux-x64-${GITHUB_ACTIONS_RUNNER_VERSION}.tar.gz" | shasum -a 256 -c
  tar xzf ./actions-runner-linux-x64-${GITHUB_ACTIONS_RUNNER_VERSION}.tar.gz
  ./config.sh --url "${GITHUB_ACTIONS_REPO_URL%.git}" --token "$GITHUB_ACTIONS_TOKEN"
  sudo ./svc.sh install
  sudo ./svc.sh start
  cd "$API_FOLDER"
fi

# 6. Start API med PM2
pm2 start index.js --name jokeapi
pm2 save

# 7. Sett opp Nginx reverse proxy
cat >/etc/nginx/sites-available/joke-api <<EOL
server {
    listen 80;
    server_name _;

    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOL

# Remove default nginx configuration
rm -f /etc/nginx/sites-enabled/default

# Enable joke-api configuration
ln -sf /etc/nginx/sites-available/joke-api /etc/nginx/sites-enabled/joke-api

# Test configuration and reload nginx
nginx -t && systemctl reload nginx

# 4b. Sørg for at NVM lastes automatisk for dev-brukeren i nye shells
NVM_INIT='export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
if [ "$SUDO_USER" ]; then
  DEV_HOME="/home/$SUDO_USER"
  if ! sudo -u $SUDO_USER grep -q 'nvm.sh' "$DEV_HOME/.bashrc"; then
    echo -e "\n# NVM init for Node.js\n$NVM_INIT" | sudo -u $SUDO_USER tee -a "$DEV_HOME/.bashrc" > /dev/null
  fi
else
  if ! grep -q 'nvm.sh' "$HOME/.bashrc"; then
    echo -e "\n# NVM init for Node.js\n$NVM_INIT" >> "$HOME/.bashrc"
  fi
fi

# 8. Konfigurer brannmur (UFW)
echo "Konfigurerer UFW-brannmur..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
# Tillat kun frontend-serveren å nå API-porten (3000)
ufw allow from 10.12.87.102 to any port 3000
# (Optional: allow outgoing to MongoDB if needed)
# ufw allow out to 10.12.87.100 port 27017
ufw default deny incoming
ufw default allow outgoing

echo "\n--- Ferdig! ---"
echo "API kjører på http://<server-ip>/api/"
echo "API-mappe: $API_FOLDER"
echo "PM2 status: pm2 status"
echo "Nginx reverse proxy er satt opp."
