# Implementation Architecture

This document explains how the Docker Compose secrets implementation works.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Docker Host                              │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ secrets/ directory (host)                                   │ │
│  │ ├── admin_username.txt                                      │ │
│  │ ├── admin_password_hash_base64.txt                          │ │
│  │ └── jwt_secret.txt                                          │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           │                                       │
│                           │ mounted as                            │
│                           ▼                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Docker Container                         │ │
│  │                                                              │ │
│  │  /run/secrets/ (read-only)                                  │ │
│  │  ├── ADMIN_USERNAME                                         │ │
│  │  ├── ADMIN_PASSWORD_HASH_BASE64                             │ │
│  │  └── JWT_SECRET                                             │ │
│  │                                                              │ │
│  │  ┌────────────────────────────────────────────────────┐    │ │
│  │  │         Next.js Application                        │    │ │
│  │  │                                                     │    │ │
│  │  │  ┌──────────────────────────────────────────────┐  │    │ │
│  │  │  │  Client-Side (Browser)                       │  │    │ │
│  │  │  │  - React Components                           │  │    │ │
│  │  │  │  - UI Logic                                   │  │    │ │
│  │  │  │  ❌ NO ACCESS to secrets                     │  │    │ │
│  │  │  └──────────────────────────────────────────────┘  │    │ │
│  │  │                      │                              │    │ │
│  │  │                      │ HTTP Request                 │    │ │
│  │  │                      ▼                              │    │ │
│  │  │  ┌──────────────────────────────────────────────┐  │    │ │
│  │  │  │  Server-Side API Routes                      │  │    │ │
│  │  │  │  /api/admin/login                            │  │    │ │
│  │  │  │  /api/admin/verify                           │  │    │ │
│  │  │  │                                               │  │    │ │
│  │  │  │     imports                                   │  │    │ │
│  │  │  │        ▼                                      │  │    │ │
│  │  │  │  ┌──────────────────────────────────────┐    │  │    │ │
│  │  │  │  │  src/lib/auth.ts                     │    │  │    │ │
│  │  │  │  │  - getJWTSecret() (lazy)             │    │  │    │ │
│  │  │  │  │  - getAdminUsername() (lazy)         │    │  │    │ │
│  │  │  │  │  - getAdminPasswordHash() (lazy)     │    │  │    │ │
│  │  │  │  └────────────┬─────────────────────────┘    │  │    │ │
│  │  │  │               │                               │  │    │ │
│  │  │  │               │ calls on first use            │  │    │ │
│  │  │  │               ▼                               │  │    │ │
│  │  │  │  ┌──────────────────────────────────────┐    │  │    │ │
│  │  │  │  │  src/lib/secrets.ts                  │    │  │    │ │
│  │  │  │  │  - getSecret(name)                   │    │  │    │ │
│  │  │  │  │  - getRequiredSecret(name)           │    │  │    │ │
│  │  │  │  └────────────┬─────────────────────────┘    │  │    │ │
│  │  │  │               │                               │  │    │ │
│  │  │  │               │ reads                         │  │    │ │
│  │  │  │               ▼                               │  │    │ │
│  │  │  │     /run/secrets/JWT_SECRET                  │  │    │ │
│  │  │  │     /run/secrets/ADMIN_USERNAME              │  │    │ │
│  │  │  │     /run/secrets/ADMIN_PASSWORD_HASH_BASE64  │  │    │ │
│  │  │  │     (or falls back to process.env)           │  │    │ │
│  │  │  └──────────────────────────────────────────────┘  │    │ │
│  │  └────────────────────────────────────────────────────┘    │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Request Flow

### 1. Admin Login Request
```
Browser
  │
  │ POST /api/admin/login
  │ Body: { username: "admin", password: "secret" }
  ▼
API Route Handler (src/app/api/admin/login/route.ts)
  │
  │ calls verifyAdmin(username, password)
  ▼
src/lib/auth.ts
  │
  │ First call: getAdminUsername()
  │   └─► getRequiredSecret('ADMIN_USERNAME')
  │       └─► readFileSync('/run/secrets/ADMIN_USERNAME')
  │           └─► Returns: "admin"
  │
  │ Second call: getAdminPasswordHash()
  │   └─► getSecret('ADMIN_PASSWORD_HASH_BASE64')
  │       └─► readFileSync('/run/secrets/ADMIN_PASSWORD_HASH_BASE64')
  │           └─► Returns: base64 hash
  │
  │ bcrypt.compare(password, hash)
  │
  ▼
Valid? Generate JWT token using getJWTSecret()
  │
  │ getJWTSecret()
  │   └─► getRequiredSecret('JWT_SECRET', 32)
  │       └─► readFileSync('/run/secrets/JWT_SECRET')
  │           └─► Returns: 32+ char secret
  │
  ▼
Return JWT in HTTP-only cookie
```

## Lazy Loading Pattern

Secrets are loaded **on first use**, not at module import:

```typescript
// ❌ OLD: Loaded at module import (build time issue)
const JWT_SECRET = process.env.JWT_SECRET;

// ✅ NEW: Loaded on first use (runtime only)
let JWT_SECRET: string | null = null;

function getJWTSecret(): string {
  if (JWT_SECRET === null) {
    JWT_SECRET = getRequiredSecret('JWT_SECRET', 32);
  }
  return JWT_SECRET;
}
```

### Why This Matters

1. **Build Time**: Module import happens during build
   - With old code: Secrets required during `npm run build`
   - With new code: Secrets not accessed until runtime

2. **Runtime**: First API request triggers lazy load
   - Secrets read from `/run/secrets/`
   - Cached for subsequent requests
   - Never exposed to client

## Security Guarantees

### 1. Client-Side Isolation
```typescript
// This code CAN run client-side:
import { Button } from '@/components/ui/button';

// This code CANNOT run client-side (Node.js only):
import { readFileSync } from 'fs';  // ❌ Not available in browser
```

### 2. File-Based Secrets
```bash
# Docker Compose mounts secrets as read-only files
$ docker exec app ls -la /run/secrets/
-r--------  1 nextjs nodejs  5 Nov 15 13:45 ADMIN_USERNAME
-r--------  1 nextjs nodejs 80 Nov 15 13:45 ADMIN_PASSWORD_HASH_BASE64
-r--------  1 nextjs nodejs 44 Nov 15 13:45 JWT_SECRET
```

### 3. No Build-Time Access
```dockerfile
# Build stage - NO secrets available
RUN npm run build

# Runtime - secrets mounted here
CMD ["npm", "start"]
```

## Development vs Production

### Development (without Docker)
```
.env.local
├── ADMIN_USERNAME=admin
├── ADMIN_PASSWORD_HASH_BASE64=...
└── JWT_SECRET=...
        │
        │ process.env fallback
        ▼
    getSecret(name)
        │
        ▼
    Returns value
```

### Production (with Docker Compose)
```
secrets/*.txt
├── admin_username.txt
├── admin_password_hash_base64.txt
└── jwt_secret.txt
        │
        │ Docker Compose mounts to /run/secrets/
        ▼
    /run/secrets/*
        │
        │ readFileSync()
        ▼
    getSecret(name)
        │
        ▼
    Returns value
```

## Fallback Strategy

The implementation tries multiple sources in order:

1. **Docker secret file** (`/run/secrets/SECRET_NAME`)
   - Used in production with Docker Compose
   - Most secure option

2. **Environment variable** (`process.env.SECRET_NAME`)
   - Used in local development
   - Backward compatible

3. **Error** (for required secrets)
   - Clear error message
   - Fails fast on startup

## Summary

✅ Secrets never in client-side code (Node.js fs module)
✅ Secrets not required at build time (lazy loading)
✅ Secrets mounted securely at runtime (Docker Compose)
✅ Falls back to env vars for development (backward compatible)
✅ Clear separation between client and server code
