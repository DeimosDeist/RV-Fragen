#!/bin/bash
# Helper script to generate secrets

cd "$(dirname "$0")/secrets"

echo "Generating secrets..."

# Generate admin username
echo "admin" > admin_username.txt
echo "✓ Created admin_username.txt"

# Generate admin password hash
read -sp "Enter admin password: " password
echo
hash=$(node -e "const bcrypt = require('bcryptjs'); const hash = bcrypt.hashSync('$password', 10); console.log(Buffer.from(hash).toString('base64'));")
echo "$hash" > admin_password_hash_base64.txt
echo "✓ Created admin_password_hash_base64.txt"

# Generate JWT secret
openssl rand -base64 32 > jwt_secret.txt
echo "✓ Created jwt_secret.txt"

echo ""
echo "All secrets generated successfully!"
echo "You can now run: docker compose up -d"
