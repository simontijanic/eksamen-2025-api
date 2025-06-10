# Foxvote API

Dette er backend-API for Foxvote-prosjektet. Her kan brukere stemme på søte rever og se statistikk over de mest populære revene.

## Database-diagram (ER-diagram)

```
+---------+         +-------+
|  Vote   |         |       |
+---------+         |       |
| imageId |<------->|  Fox  | (kun bilde-id, ikke egen tabell)
| votes   |         |       |
+---------+         +-------+
```

- **Vote**: Lagrer antall stemmer for hvert bilde (imageId).
- Det finnes ingen egen "Fox"-tabell, kun bilde-id fra randomfox.ca.

## RESTful API-endepunkter

| Metode | Endpoint      | Beskrivelse                        | Body/Parametre         |
|--------|--------------|-------------------------------------|------------------------|
| GET    | /api/images  | Hent to tilfeldige rev-bilder       | -                      |
| POST   | /api/vote    | Stem på en rev                      | `{ imageId: string }`  |
| GET    | /api/stats   | Hent toppliste og leder             | -                      |

- **POST /api/vote**: Registrerer en stemme på valgt bilde. Cooldown på 3 sekunder per IP.
- **GET /api/images**: Returnerer to tilfeldige, ulike bilde-id'er og deres URL.
- **GET /api/stats**: Returnerer toppliste (topp 10) og leder.

## Sette opp prosjektet på Ubuntu 22 med bash-script

1. **Last ned og gjør scriptet kjørbart:**
   ```bash
   curl -O https://raw.githubusercontent.com/simontijanic/eksamen-2025-api/main/setup_foxvote_server.sh
   chmod +x setup_foxvote_server.sh
   ```
2. **Kjør scriptet med:**
   ```bash
   sudo bash setup_foxvote_server.sh <git_repo_url> <api_folder>
   ```
   Eksempel:
   ```bash
   sudo bash setup_foxvote_server.sh https://github.com/simontijanic/eksamen-2025-api.git /home/ubuntu/foxvote-api
   ```
3. **Scriptet gjør følgende:**
   - Installerer nødvendige pakker (`curl`, `git`, `nginx`, `unzip`)
   - Installerer FNM (Node.js manager) og siste Node.js-versjon
   - Kloner API-koden fra gitt repo
   - Oppretter `.env` fra `.env.example` hvis den ikke finnes
   - Installerer avhengigheter og PM2
   - Starter API med PM2
   - Setter opp Nginx reverse proxy for `/api/`

4. **Etter kjøring:**
   - API-et kjører på http://<server-ip>/api/
   - Sjekk status med `pm2 status`
   - Endre MongoDB-tilkobling i `.env` hvis nødvendig

## Eksempel på .env-fil

```
MONGODB_URI=mongodb://localhost:27017/2025eksamenb
```

## Avhengigheter
- Node.js (installeres via FNM)
- MongoDB (må være installert og kjørende)
- PM2
- Nginx

---

**Lisens:** MIT
