# Docker Compose Secrets

This directory contains secret files that are read by the application when running in Docker.

## Setup Instructions

1. Copy the example files and remove the `.example` extension:
   ```bash
   cp admin_username.txt.example admin_username.txt
   cp admin_password_hash_base64.txt.example admin_password_hash_base64.txt
   cp jwt_secret.txt.example jwt_secret.txt
   ```

2. Edit each file with your actual secrets (see below for generation instructions)

3. **IMPORTANT**: Never commit these files to git! They are already listed in `.gitignore`

## Generating Secrets

### Admin Username
Simply write your desired username to `admin_username.txt`:
```bash
echo "admin" > admin_username.txt
```

### Admin Password Hash
Generate a bcrypt hash of your password and encode it in base64:
```bash
node -e "const bcrypt = require('bcryptjs'); const password = 'your-secure-password'; const hash = bcrypt.hashSync(password, 10); const base64 = Buffer.from(hash).toString('base64'); console.log(base64);" > admin_password_hash_base64.txt
```

### JWT Secret
Generate a random 32+ character secret:
```bash
openssl rand -base64 32 > jwt_secret.txt
```

## File Format

Each secret file should contain only the secret value with no extra whitespace or newlines (trailing newlines are automatically trimmed).

## Security Notes

- These files are mounted as Docker secrets at `/run/secrets/` inside the container
- The application reads these files at startup (see `src/lib/secrets.ts`)
- Secrets are never exposed to client-side code
- For production deployments, consider using Docker Swarm secrets or Kubernetes secrets for better security

## Docker Secret Mounting

The application supports multiple Docker secret naming conventions:
1. **Direct mounting** with uppercase names (e.g., `/run/secrets/JWT_SECRET`)
2. **File-based mounting** with lowercase names and `.txt` extension (e.g., `/run/secrets/jwt_secret.txt`)

The secret management system automatically tries both formats, ensuring compatibility with different Docker Compose configurations.
