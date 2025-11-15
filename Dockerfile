# Multi-stage build für optimierte Image-Größe
FROM node:20-alpine AS base

# Stage to fetch the source code
FROM base AS fetcher
RUN apk add --no-cache git
WORKDIR /app
ARG REPO_URL=https://github.com/deimosdeist/RV-Fragen.git
ARG COMMIT_HASH=HEAD
RUN git clone $REPO_URL .
RUN git checkout $COMMIT_HASH

# Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY --from=fetcher /app/package.json /app/package-lock.json* ./
RUN npm ci

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=fetcher /app .

# Setze Umgebungsvariablen für den Build
ENV NEXT_TELEMETRY_DISABLED=1

# Build der Anwendung
# IMPORTANT: Secrets are NOT needed at build time, only at runtime
# The application reads secrets from /run/secrets/ at runtime via src/lib/secrets.ts
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Kopiere notwendige Dateien
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Erstelle data Verzeichnis für persistente Daten
RUN mkdir -p /app/data && chown -R nextjs:nodejs /app/data

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["npm", "start"]
