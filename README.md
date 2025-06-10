# Foxvote API

Dette er backend-API for Foxvote-prosjektet - en Node.js/Express server som håndterer stemmegivning og statistikk for søte rev-bilder.

## 📁 Prosjektstruktur

```
api/
├── app.js                     # Hovedfil for Express-server
├── package.json               # Node.js avhengigheter
├── .env.example              # Miljøvariabler mal
├── setup_foxvote_server.sh   # Automatisk oppsett for Ubuntu
└── README.md                 # Denne filen
```

## 🗄️ Database-diagram (ER-diagram)

```
+---------+         +-------+
|  Vote   |         |       |
+---------+         |       |
| imageId |<------->|  Fox  | (kun bilde-id, ikke egen tabell)
| votes   |         |       |
+---------+         +-------+
```

- **Vote**: Lagrer antall stemmer for hvert bilde (imageId) i MongoDB
- Det finnes ingen egen "Fox"-tabell, kun bilde-id fra randomfox.ca API

## 🔌 RESTful API-endepunkter

| Metode | Endpoint      | Beskrivelse                        | Body/Parametre         | Respons |
|--------|--------------|-------------------------------------|------------------------|---------|
| GET    | /api/images  | Hent to tilfeldige rev-bilder       | -                      | `{ images: [{ id, url }] }` |
| POST   | /api/vote    | Stem på en rev                      | `{ imageId: string }`  | `{ success: boolean, message: string }` |
| GET    | /api/stats   | Hent toppliste og leder             | -                      | `{ topList: [], leader: {} }` |

### Detaljer:
- **POST /api/vote**: Registrerer en stemme på valgt bilde. Cooldown på 3 sekunder per IP-adresse
- **GET /api/images**: Returnerer to tilfeldige, ulike bilde-id'er og deres URL-er
- **GET /api/stats**: Returnerer toppliste (topp 10) og nåværende leder med stemmetall

## 🚀 Rask oppsett med bash-script (Ubuntu 22.04)

### Automatisk installasjon:
```bash
# Last ned og gjør scriptet kjørbart
curl -O https://raw.githubusercontent.com/simontijanic/eksamen-2025-api/main/setup_foxvote_server.sh
chmod +x setup_foxvote_server.sh

# Kjør scriptet
sudo bash setup_foxvote_server.sh https://github.com/simontijanic/eksamen-2025-api.git /home/ubuntu/foxvote-api
```

### Hva scriptet gjør:
- ✅ Installerer nødvendige pakker (curl, git, nginx, unzip)
- ✅ Installerer NVM (Node Version Manager) og Node.js LTS
- ✅ Kloner API-koden fra GitHub
- ✅ Oppretter `.env` fra `.env.example` 
- ✅ Installerer npm avhengigheter og PM2
- ✅ Starter API med PM2 (prosessmanager)
- ✅ Setter opp Nginx reverse proxy for `/api/`
- ✅ Konfigurerer brannmur (UFW)

### Etter installasjon:
- **API-tilgang:** `http://<server-ip>/api/`
- **Status:** `pm2 status` for å sjekke prosessen
- **Logger:** `pm2 logs` for å se API-logger

## 🛠 Manuell installasjon

### Forutsetninger:
- Ubuntu 22.04 eller nyere
- MongoDB server (lokal eller ekstern)
- Nginx
- Node.js (LTS versjon)

### Steg-for-steg:

1. **Installer Node.js via NVM:**
   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   source ~/.bashrc
   nvm install --lts
   nvm use --lts
   ```

2. **Klon prosjektet:**
   ```bash
   git clone https://github.com/simontijanic/eksamen-2025-api.git /home/ubuntu/foxvote-api
   cd /home/ubuntu/foxvote-api
   ```

3. **Installer avhengigheter:**
   ```bash
   npm install
   npm install -g pm2
   ```

4. **Konfigurer miljøvariabler:**
   ```bash
   cp .env.example .env
   nano .env  # Rediger MongoDB-tilkobling
   ```

5. **Start API-serveren:**
   ```bash
   pm2 start app.js --name foxvote-api
   pm2 save
   pm2 startup
   ```

6. **Konfigurer Nginx proxy:**
   ```bash
   sudo nano /etc/nginx/sites-available/foxvote-api
   ```
   Se [nginx-konfigurasjon](#nginx-konfigurasjon) under.

## ⚙️ Konfigurasjoner

### Miljøvariabler (.env):
```env
# MongoDB-tilkobling
MONGODB_URI=mongodb://localhost:27017/foxvote

# Server-port (standard: 3000)
PORT=3000

# Cooldown for stemming (sekunder)
VOTE_COOLDOWN=3
```

### Nginx-konfigurasjon:
```nginx
server {
    listen 80;
    server_name your-domain.com;  # eller server IP
    
    # API-proxy
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout-innstillinger
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Helse-sjekk
    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
}
```

## 🔧 API-funksjonalitet

### Hovedfunksjoner:
- **🎲 Tilfeldig bildehenting:** Henter tilfeldige rev-bilder fra randomfox.ca
- **🗳️ Stemmeregistrering:** Lagrer stemmer i MongoDB med IP-basert cooldown
- **📊 Statistikk:** Genererer toppliste og viser mest populære rever
- **⏱️ Rate limiting:** 3 sekunders cooldown mellom stemmer per IP
- **🛡️ Feilhåndtering:** Omfattende error handling og logging

### Tekniske detaljer:
- **Backend:** Node.js med Express framework
- **Database:** MongoDB for stemmelagring
- **Prosessmanagement:** PM2 for produksjonstabilitet
- **Proxy:** Nginx reverse proxy for API-routing
- **Logging:** PM2 logging for feilsøking

## 🔗 Eksterne avhengigheter

| Tjeneste | Beskrivelse | URL |
|----------|-------------|-----|
| RandomFox API | Leverer rev-bilder | https://randomfox.ca/floof/ |
| MongoDB | Database for stemmelagring | - |

## 🐛 Feilsøking

### Vanlige problemer:

1. **API svarer ikke:**
   ```bash
   pm2 status                    # Sjekk prosessstatus
   pm2 logs foxvote-api         # Se logger
   pm2 restart foxvote-api      # Restart ved behov
   ```

2. **MongoDB-tilkoblingsfeil:**
   ```bash
   # Sjekk at MongoDB kjører
   sudo systemctl status mongod
   
   # Kontroller .env-fil
   cat .env
   
   # Test tilkobling
   mongosh $MONGODB_URI
   ```

3. **Nginx-proxy problemer:**
   ```bash
   sudo nginx -t                    # Test konfigurasjon
   sudo systemctl status nginx      # Sjekk status
   sudo tail -f /var/log/nginx/error.log  # Se feillogger
   ```

4. **Port allerede i bruk:**
   ```bash
   sudo netstat -tulpn | grep :3000  # Sjekk hvem som bruker port 3000
   pm2 delete foxvote-api            # Stopp eksisterende prosess
   ```

### Logging og overvåking:
```bash
# PM2 kommandoer
pm2 status                 # Prosessoversikt
pm2 logs foxvote-api      # Live logger
pm2 monit                 # Sanntidsmonitorering
pm2 info foxvote-api      # Detaljert prosessinfo

# System-logger
sudo journalctl -u nginx  # Nginx systemlogger
tail -f /var/log/nginx/access.log  # HTTP-tilgangslogger
```

## 🔄 Oppdatering og vedlikehold

### Oppdatere API-kode:
```bash
cd /home/ubuntu/foxvote-api
git pull
npm install  # Installer nye avhengigheter hvis nødvendig
pm2 restart foxvote-api
```

### Backup av stemmedata:
```bash
# Eksporter MongoDB-data
mongodump --uri=$MONGODB_URI --out=/backup/foxvote-$(date +%Y%m%d)

# Gjenopprett fra backup
mongorestore --uri=$MONGODB_URI /backup/foxvote-20241220/
```

## 📊 Ytelse og skalering

### Anbefalte innstillinger:
- **PM2 Cluster Mode:** For høy belastning
  ```bash
  pm2 start app.js --name foxvote-api -i max
  ```
- **MongoDB-indeksering:** På `imageId` for raskere oppslag
- **Nginx-caching:** For API-responser med lav endringshyppighet

## 📋 Systemkrav

### Minimum krav:
- **Server:** Ubuntu 22.04+ (2 CPU cores, 2GB RAM)
- **Node.js:** v18.0+ (LTS anbefalt)
- **MongoDB:** v5.0+
- **Nginx:** v1.18+
- **Diskplass:** 1GB for applikasjon + database

### Anbefalte krav for produksjon:
- **Server:** 4 CPU cores, 4GB RAM
- **SSD-lagring** for MongoDB
- **Backup-strategi** for database

## 🔐 Sikkerhet

### Implementerte tiltak:
- ✅ Rate limiting per IP-adresse
- ✅ Input-validering på alle endepunkter
- ✅ CORS-konfigurasjon
- ✅ Environment-basert konfigurasjon
- ✅ Nginx-proxy med sikkerhetstiltak

### Anbefalte forbedringer:
- SSL/TLS-sertifikater (HTTPS)
- Database-autentisering
- API-nøkler for tilgangskontroll
- Brannmursregler for MongoDB

## 📄 Avhengigheter

### Node.js pakker (package.json):
```json
{
  "dependencies": {
    "express": "^4.18.0",
    "mongodb": "^5.0.0",
    "cors": "^2.8.5",
    "dotenv": "^16.0.0"
  }
}
```

### Systemavhengigheter:
- **NVM:** Node.js versjonshåndtering
- **PM2:** Prosessmanager for Node.js
- **Nginx:** Reverse proxy og webserver
- **UFW:** Brannmur (Ubuntu Firewall)

---

## 📞 Support

For spørsmål eller problemer:
- Sjekk PM2-logger: `pm2 logs foxvote-api`
- Kontroller systemstatus: `pm2 status`
- Se Nginx-logger: `sudo tail -f /var/log/nginx/error.log`
- Kontakt systemadministrator ved alvorlige problemer

**Lisens:** MIT
