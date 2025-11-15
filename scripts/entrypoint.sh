#!/bin/sh
set -e

# Docker entrypoint script
# This script runs as root at container start to:
# 1. Read Docker secrets from /run/secrets/
# 2. Export them as environment variables for the app
# 3. Drop privileges to the non-root nextjs user
# 4. Start the Next.js application

echo "Starting entrypoint script..."

# Read secrets from /run/secrets/ if they exist
# These are typically mounted by Docker Compose or Docker Swarm
if [ -f "/run/secrets/jwt_secret" ]; then
    export JWT_SECRET=$(cat /run/secrets/jwt_secret)
    echo "✓ Loaded JWT_SECRET from Docker secret"
elif [ -f "/run/secrets/jwt_secret.txt" ]; then
    export JWT_SECRET=$(cat /run/secrets/jwt_secret.txt)
    echo "✓ Loaded JWT_SECRET from Docker secret (jwt_secret.txt)"
fi

if [ -f "/run/secrets/admin_username" ]; then
    export ADMIN_USERNAME=$(cat /run/secrets/admin_username)
    echo "✓ Loaded ADMIN_USERNAME from Docker secret"
elif [ -f "/run/secrets/admin_username.txt" ]; then
    export ADMIN_USERNAME=$(cat /run/secrets/admin_username.txt)
    echo "✓ Loaded ADMIN_USERNAME from Docker secret (admin_username.txt)"
fi

if [ -f "/run/secrets/admin_password_hash_base64" ]; then
    export ADMIN_PASSWORD_HASH_BASE64=$(cat /run/secrets/admin_password_hash_base64)
    echo "✓ Loaded ADMIN_PASSWORD_HASH_BASE64 from Docker secret"
elif [ -f "/run/secrets/admin_password_hash_base64.txt" ]; then
    export ADMIN_PASSWORD_HASH_BASE64=$(cat /run/secrets/admin_password_hash_base64.txt)
    echo "✓ Loaded ADMIN_PASSWORD_HASH_BASE64 from Docker secret (admin_password_hash_base64.txt)"
fi

# Verify that required secrets are loaded
if [ -z "$JWT_SECRET" ]; then
    echo "ERROR: JWT_SECRET not found in /run/secrets/"
    exit 1
fi

if [ -z "$ADMIN_USERNAME" ]; then
    echo "ERROR: ADMIN_USERNAME not found in /run/secrets/"
    exit 1
fi

if [ -z "$ADMIN_PASSWORD_HASH_BASE64" ]; then
    echo "ERROR: ADMIN_PASSWORD_HASH_BASE64 not found in /run/secrets/"
    exit 1
fi

echo "All required secrets loaded successfully"

# Create data directory if it doesn't exist
mkdir -p /app/data
chown -R nextjs:nodejs /app/data

# Drop privileges to nextjs user and start the application
echo "Dropping privileges to nextjs user and starting Next.js..."
exec su-exec nextjs:nodejs "$@"
