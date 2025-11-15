# Quick Start Guide - Docker Compose with Secrets

This guide gets you running with Docker Compose in under 5 minutes.

## Prerequisites
- Docker and Docker Compose installed
- Git (to clone the repository)

## Step 1: Clone the Repository
```bash
git clone https://github.com/DeimosDeist/RV-Fragen.git
cd RV-Fragen
```

## Step 2: Generate Secrets
Run the helper script (or create manually):

### Option A: Using Helper Script
```bash
./generate-secrets.sh
```
This will prompt you for an admin password and generate all required secrets.

### Option B: Manual Creation
```bash
cd secrets

# Admin username
echo "admin" > admin_username.txt

# Admin password hash (replace 'yourpassword' with your desired password)
node -e "const bcrypt = require('bcryptjs'); const password = 'yourpassword'; const hash = bcrypt.hashSync(password, 10); const base64 = Buffer.from(hash).toString('base64'); console.log(base64);" > admin_password_hash_base64.txt

# JWT secret
openssl rand -base64 32 > jwt_secret.txt

cd ..
```

## Step 3: Start the Application
```bash
docker compose up -d
```

This will:
1. Build the Docker image from the latest code
2. Mount secrets securely at `/run/secrets/`
3. Start the application on port 3000

## Step 4: Access the Application
Open your browser to: http://localhost:3000

## Step 5: Login as Admin
1. Click the Shield icon (🛡️) in the top right
2. Login with:
   - Username: `admin` (or whatever you set)
   - Password: the password you used (NOT the hash)

## Management Commands

```bash
# View logs
docker compose logs -f

# Stop the application
docker compose down

# Restart after code changes
docker compose up -d --build

# Check status
docker compose ps
```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker compose logs app

# Verify secrets exist
ls -la secrets/
```

### Can't login
- Make sure you're using the password, not the hash
- Check that all secret files were created correctly
- Verify no extra whitespace in secret files

### Build fails
- Check internet connection (needs to clone from GitHub)
- Verify Docker has enough disk space
- Try: `docker compose build --no-cache`

## Security Notes

✅ Secrets are stored in files, not environment variables
✅ Secrets are mounted at runtime, not baked into the image
✅ Secrets are never exposed to client-side code
✅ Secret files are excluded from git

🚨 **Important for Production:**
- Always use HTTPS (HTTP-only cookies require it)
- Use strong passwords (12+ characters)
- Restrict access to secret files
- Never commit actual secrets to git

## Next Steps

- See `README.md` for detailed documentation
- See `ADMIN_SETUP.md` for admin configuration
- See `SECURITY_SUMMARY.md` for security details
