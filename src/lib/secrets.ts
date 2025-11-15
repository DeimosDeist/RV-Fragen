import { readFileSync } from 'fs';
import { join } from 'path';

/**
 * Read a secret from Docker Compose secrets (file-based) or fall back to environment variable
 * 
 * Docker Compose secrets are mounted at /run/secrets/<secret_name> in containers
 * For development/non-Docker environments, falls back to process.env
 * 
 * This ensures secrets are never exposed in client-side code as this function
 * can only be called from server-side code (Node.js fs module is not available in browser)
 */
export function getSecret(name: string): string | undefined {
  // Try to read from Docker secret file first
  const secretPath = join('/run/secrets', name);
  
  try {
    // Attempt to read the secret from file (Docker Compose secrets)
    const secret = readFileSync(secretPath, 'utf-8').trim();
    if (secret) {
      return secret;
    }
  } catch (error) {
    // File doesn't exist or can't be read, fall back to environment variable
    // This is expected in development environments without Docker
  }
  
  // Fall back to environment variable for backward compatibility
  return process.env[name];
}

/**
 * Get a required secret - throws if not found
 */
export function getRequiredSecret(name: string, minLength?: number): string {
  const secret = getSecret(name);
  
  if (!secret) {
    throw new Error(`Secret '${name}' is required but not found! Provide it via Docker secret file at /run/secrets/${name} or environment variable ${name}`);
  }
  
  if (minLength && secret.length < minLength) {
    throw new Error(`Secret '${name}' must be at least ${minLength} characters long!`);
  }
  
  return secret;
}
