# Joke Review API

Dette er backend-API for vits-anmeldelser – en Node.js/Express-server som henter tilfeldige vitser fra en ekstern API og lar brukere anmelde dem med stjerner og kommentar.

## 📁 Prosjektstruktur

```
api/
├── index.js                  # Hovedfil for Express-server
├── package.json              # Node.js avhengigheter
├── .env.example              # Miljøvariabler mal
├── setup_joke_server.sh      # Automatisk oppsett for Ubuntu
├── ecosystem.config.js       # PM2 prosesskonfig
├── config/
│   └── database.js           # Database-tilkobling (MongoDB)
├── controllers/
│   └── jokeController.js     # API-logikk for vitser og anmeldelser
├── models/
│   └── jokeReview.js         # Mongoose-modell for vits-anmeldelser
├── routes/
│   └── jokeRoutes.js         # API-ruter for vits og anmeldelser
└── README.md                 # Denne filen
```

## 🛠️ Verktøy og teknologi
- **Node.js/Express** – Backend-rammeverk
- **MongoDB/Mongoose** – Database og ODM
- **Nginx** – Reverse proxy
- **PM2** – Prosessmanager for Node.js
- **UFW** – Brannmur
- **express-rate-limit** – Rate limiting
- **dotenv** – Miljøvariabler
- **Bootstrap 5** – Frontend-rammeverk
- **Vanilla JavaScript** – Frontend-logikk
- **HTML/CSS** – Struktur og styling
- **official-joke-api.appspot.com** – Ekstern API for vitser

## 🗂️ Arkitektur

- **Frontend:** Viser én tilfeldig vits, lar brukeren gi stjerner og kommentar, og viser gjennomsnittlig vurdering. Kommuniserer med backend via API.
- **Backend (API):** Node.js/Express-app på egen VM. Henter vits fra ekstern API, lagrer anmeldelser, og leverer statistikk.
- **Database:** MongoDB på egen VM, kun tilgjengelig fra backendens interne IP.

**Database-tabell:**
- `JokeReview` (jokeId: number, stars: number, comment: string)

**Arkitekturdiagram:**
```
[ Bruker ]
    |
    v
[Frontend VM: Nginx + statiske filer]
    |
    v
[Backend VM: Nginx (proxy) -> Node.js/Express (API)]
    |
    v
[Database VM: MongoDB]
```


---

## 🔌 RESTful API-endepunkter

| Metode | Endpoint                | Beskrivelse                        | Body/Parametre         | Respons |
|--------|------------------------|-------------------------------------|------------------------|---------|
| GET    | /api/joke              | Hent én tilfeldig vits              | -                      | `{ id, setup, punchline, ... }` |
| POST   | /api/joke/review       | Send inn anmeldelse av vits         | `{ jokeId, stars, comment }` | `{ message, average, count }` |
| GET    | /api/joke/average/:id  | Hent gjennomsnittlig rating for vits| -                      | `{ average, count }` |

---

## ⚙️ Konfigurasjoner

### Miljøvariabler (.env):
```env
MONGODB_URI=mongodb://localhost:27017/2025eksamenb
PORT=3000
```

### Nginx-konfigurasjon (settes automatisk av scriptet):
```nginx
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
```

---

## 📊 ER-diagram (datamodell)

```
+------------+
| JokeReview |
+------------+
| jokeId : number
| stars  : number
| comment: string
+------------+
```

- Hver anmeldelse lagres med vits-ID (jokeId), stjerner (stars), og kommentar (comment).

---

## 🐾 Funksjonalitet og kravoppfyllelse

- Viser en tilfeldig vits fra en ekstern kilde
- Brukeren kan gi stjerner (1-5) og skrive kommentar på vitsen
- Systemet lagrer anmeldelser og beregner gjennomsnittlig vurdering
- Statistikk vises: gjennomsnittlig vurdering og antall anmeldelser
- Universell utforming: ARIA, responsivt design, tastaturnavigasjon, tydelige meldinger
- Feiltilstander gir brukervennlige feilmeldinger
- Koden er kommentert for enkel forståelse

---

## 🔒 Sikkerhet og drift

- **Brannmur:** UFW åpner kun nødvendige porter (80, 22, 3000 kun fra frontend)
- **Direkte tilgang til database fra internett er blokkert**
- **API-endepunkter dokumentert (se over)**
- **Frontend, backend og database kjører som separate tjenester på egne porter/IP-er**
- **MongoDB lytter kun på backendens interne IP**

### Potensielle sikkerhetshull
1. Mangler autentisering/autorisasjon – alle kan sende inn anmeldelser
2. Rate limiting kun på IP og i minnet – kan omgås med mange IP-er
3. Ingen input-validering på jokeId – mulig å sende ugyldige verdier

### Angrepstyper
- Massesending av anmeldelser (spam) med script eller mange IP-er
- Injection-angrep (f.eks. NoSQL injection hvis input ikke valideres)

### Tiltak for å redusere risiko
- Innfør autentisering og tilgangskontroll
- Bruk robust rate limiting (f.eks. express-rate-limit med Redis)
- Valider all input med f.eks. express-validator
- Bruk HTTPS i produksjon
- Logg og overvåk mistenkelig trafikk

---

## 🧑‍💻 Brukerstøtte og universell utforming

- Intuitivt grensesnitt med tydelige knapper og tilbakemeldinger
- Feilmeldinger er forståelige for brukeren
- Universell utforming: ARIA, tastaturnavigasjon, responsivt design
- Brukerveiledning og FAQ finnes i frontend-mappen

---

## 🐛 Vanlige feil og hvordan løse dem

### 1. API svarer ikke / får ikke kontakt
- Sjekk at API-et kjører:
  ```bash
  pm2 status
  pm2 logs jokeapi
  ```
  Start på nytt om nødvendig:
  ```bash
  pm2 restart jokeapi
  ```

### 2. Nginx feiler ved reload
- Ofte feil i proxy_set_header-linjer (mangler verdi).
- Sjekk konfigurasjon:
  ```bash
  sudo nginx -t
  ```
  Rett opp alle proxy_set_header-linjer slik at de har både navn og verdi (se eksempel over).

### 3. Får 404 Not Found på /api/joke
- API-et kjører ikke, eller feil i Nginx-proxy.
- Sjekk at Node.js-API-et kjører (pm2 status).
- Sjekk at Nginx-proxyen peker til riktig port (proxy_pass http://localhost:3000;).

### 4. CORS-feil i frontend
- Mangler CORS i backend.
- Sørg for at app.use(cors()); er med i index.js i backend.

### 5. Feil med MongoDB-tilkobling
- Sjekk at MongoDB kjører:
  ```bash
  sudo systemctl status mongod
  ```
- Sjekk at .env har riktig MONGODB_URI.

### 6. Brannmur blokkerer trafikk
- Sjekk UFW-regler:
  ```bash
  sudo ufw status verbose
  ```
- Sørg for at port 80 og 22 er åpne, og at port 3000 kun er åpen for frontend-serveren.

---

## 🛑 Mulige svakheter i databasen og hvordan forbedre dem

**Svakheter i nåværende løsning:**
- Alle anmeldelser lagres uten kobling til bruker (ingen autentisering). Det betyr at samme person kan anmelde samme vits mange ganger, og det er ingen måte å hindre juks.
- Ingen sjekk på om en vits faktisk eksisterer i den eksterne API-en før anmeldelse lagres.
- Ingen validering av kommentarens lengde eller innhold utover det som er satt i modellen.
- Ingen indeksering på `jokeId` – kan bli tregt ved mange anmeldelser.
- Ingen mulighet for å hente ut alle anmeldelser for en vits (kun snitt og antall).
- Ingen "soft delete" eller mulighet for å trekke tilbake en anmeldelse.

**Hvordan forbedre:**
- Legg til brukersystem (autentisering) slik at én bruker kun kan anmelde hver vits én gang.
- Legg til validering mot ekstern API for å sjekke at vitsen finnes før anmeldelse lagres.
- Legg til bedre validering av kommentarer (lengde, språk, evt. banning-filter).
- Legg til MongoDB-indeks på `jokeId` for raskere oppslag.
- Lag et endepunkt for å hente ut alle anmeldelser for en vits (for f.eks. admin eller læringsformål).
- Implementer "soft delete" (f.eks. `deleted: true`-felt) for å kunne trekke tilbake anmeldelser uten å slette data.

**Forklaring (for studenter):**
Dagens løsning er enkel og lett å forstå, men ikke robust mot juks eller misbruk. I en ekte applikasjon bør man alltid tenke på hvordan man kan sikre at dataene er riktige, at én bruker ikke kan stemme mange ganger, og at systemet tåler mange brukere uten å bli tregt. Indekser og autentisering er viktige verktøy for dette.

---

## 📞 Support
- Sjekk PM2-logger: pm2 logs jokeapi
- Kontroller systemstatus: pm2 status
- Se Nginx-logger: sudo tail -f /var/log/nginx/error.log



