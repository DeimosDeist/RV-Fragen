# 🔐 Admin Setup Anleitung

## Option 1: Docker Compose (Empfohlen für Production)

Docker Compose verwendet dateibasierte Secrets für maximale Sicherheit.

### Schritt 1: Secret-Dateien erstellen

Erstelle die benötigten Secret-Dateien im `secrets/` Verzeichnis:

```bash
cd secrets

# Kopiere die Beispieldateien
cp admin_username.txt.example admin_username.txt
cp admin_password_hash_base64.txt.example admin_password_hash_base64.txt
cp jwt_secret.txt.example jwt_secret.txt
```

### Schritt 2: Secrets befüllen

#### Admin Username (`secrets/admin_username.txt`)

Schreibe deinen Admin-Username in die Datei:

```bash
echo "admin" > admin_username.txt
```

#### Admin Password Hash (`secrets/admin_password_hash_base64.txt`)

Generiere einen bcrypt Hash und speichere ihn Base64-kodiert:

```bash
node -e "const bcrypt = require('bcryptjs'); const password = 'dein-sicheres-passwort'; const hash = bcrypt.hashSync(password, 10); const base64 = Buffer.from(hash).toString('base64'); console.log(base64);" > admin_password_hash_base64.txt
```

**Wichtig:** Ersetze `'dein-sicheres-passwort'` mit deinem gewünschten Passwort!

#### JWT Secret (`secrets/jwt_secret.txt`)

Generiere ein zufälliges Secret (mindestens 32 Zeichen):

```bash
openssl rand -base64 32 > jwt_secret.txt
```

### Schritt 3: Container starten

```bash
# Zurück zum Hauptverzeichnis
cd ..

# Container bauen und starten
docker compose up -d

# Logs anzeigen
docker compose logs -f
```

Die Anwendung läuft jetzt auf [http://localhost:3000](http://localhost:3000)

## Option 2: Lokale Entwicklung (ohne Docker)

### Schritt 1: Passwort-Hash generieren

Führe das folgende Kommando aus, um einen Passwort-Hash zu generieren:

```bash
node -e "const bcrypt = require('bcryptjs'); const password = 'deinSicheresPasswort'; const hash = bcrypt.hashSync(password, 10); const base64 = Buffer.from(hash).toString('base64'); console.log('ADMIN_PASSWORD_HASH_BASE64=' + base64);"
```

Das Script gibt dir einen Hash aus, den du im nächsten Schritt benötigst.

### Schritt 2: .env.local Datei erstellen

Erstelle eine Datei namens `.env.local` im Projekt-Root mit folgendem Inhalt:

```env
# Admin Credentials
ADMIN_USERNAME=admin
ADMIN_PASSWORD_HASH_BASE64=<der-generierte-hash-aus-schritt-1>

# JWT Secret (mindestens 32 Zeichen lang)
JWT_SECRET=dein-zufaelliges-secret-minimum-32-zeichen-lang
```

#### JWT Secret generieren (empfohlen):

```bash
openssl rand -base64 32
```

### Schritt 3: Server neu starten

Starte den Development-Server:

```bash
npm run dev
```

## Admin-Login verwenden

### Zugang zum Admin-Panel:

1. **Dezenter Zugang**: Klicke auf das **Shield-Icon** (🛡️) in der oberen rechten Ecke der Hauptseite
2. Gib deine Credentials ein (Username und Passwort, nicht den Hash!)

### Nach dem Login:

- Das Shield-Icon wird **grün** (✅ angemeldet)
- In den **Fragen-Details** siehst du einen Button "**Als erledigt markieren**"
- Beantwortete Fragen werden mit einem schönen grünen **"Erledigt"**-Badge markiert ✓

## Sicherheitshinweise

- ⚠️ **Teile niemals** deine Secret-Dateien oder `.env.local`!
- ⚠️ Diese Dateien sind bereits in `.gitignore` und werden **nicht** committet
- 🔒 Verwende ein **starkes Passwort** (mindestens 12 Zeichen, Groß-/Kleinbuchstaben, Zahlen, Sonderzeichen)
- 🔒 Ändere das JWT_SECRET auf einen **zufälligen Wert**
- 🔐 Admin-Credentials werden **verschlüsselt** (bcrypt) und Tokens sind **signiert** (JWT)
- 🛡️ Secrets werden **niemals** im Code oder Client-seitig exponiert
- 🐳 Bei Docker werden Secrets erst zur **Laufzeit** geladen, nicht beim Build

## Troubleshooting

### "Admin password hash not configured!"

→ Du hast vergessen, `ADMIN_PASSWORD_HASH_BASE64` (in `.env.local`) oder `secrets/admin_password_hash_base64.txt` (bei Docker) zu setzen.

### Login schlägt fehl

→ Stelle sicher, dass der Hash korrekt kopiert wurde (keine Leerzeichen/Zeilenumbrüche).
→ Achte darauf, dass du das **Passwort** eingibst, nicht den Hash!

### Server startet nicht

→ Überprüfe, ob alle Secrets korrekt gesetzt sind.
→ Bei Docker: Prüfe mit `docker compose logs app`
→ Bei lokaler Entwicklung: Prüfe, ob `.env.local` existiert und alle Werte gesetzt sind

### Docker Container startet nicht

→ Stelle sicher, dass alle Secret-Dateien in `secrets/` existieren:
```bash
ls -la secrets/
# Sollte zeigen: admin_username.txt, admin_password_hash_base64.txt, jwt_secret.txt
```

