import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { getRequiredSecret, getSecret } from './secrets';

// Lazy-load secrets only when first accessed at runtime
// This ensures secrets are not required during build time
let JWT_SECRET: string | null = null;
let ADMIN_USERNAME: string | null = null;
let ADMIN_PASSWORD_HASH: string | null = null;

function getJWTSecret(): string {
  if (JWT_SECRET === null) {
    JWT_SECRET = getRequiredSecret('JWT_SECRET', 32);
  }
  return JWT_SECRET;
}

function getAdminUsername(): string {
  if (ADMIN_USERNAME === null) {
    ADMIN_USERNAME = getRequiredSecret('ADMIN_USERNAME');
  }
  return ADMIN_USERNAME;
}

function getAdminPasswordHash(): string {
  if (ADMIN_PASSWORD_HASH === null) {
    const base64 = getSecret('ADMIN_PASSWORD_HASH_BASE64') || '';
    ADMIN_PASSWORD_HASH = base64 
      ? Buffer.from(base64, 'base64').toString('utf-8')
      : '';
  }
  return ADMIN_PASSWORD_HASH;
}

export interface AdminToken {
  username: string;
  isAdmin: boolean;
  iat: number;
  exp: number;
}

/**
 * Verify admin credentials
 */
export async function verifyAdmin(username: string, password: string): Promise<boolean> {
  if (username !== getAdminUsername()) {
    return false;
  }
  
  const adminPasswordHash = getAdminPasswordHash();
  
  // If no hash is set, reject (security)
  if (!adminPasswordHash || adminPasswordHash.length < 10) {
    console.error('Admin password hash not configured!');
    return false;
  }
  
  try {
    const result = await bcrypt.compare(password, adminPasswordHash);
    return result;
  } catch (error) {
    console.error('Error verifying admin password:', error);
    return false;
  }
}

/**
 * Generate JWT token for admin
 */
export function generateAdminToken(username: string): string {
  return jwt.sign(
    { username, isAdmin: true },
    getJWTSecret(),
    { expiresIn: '7d' } // 7 days validity
  );
}

/**
 * Verify JWT token
 */
export function verifyToken(token: string): AdminToken | null {
  try {
    const decoded = jwt.verify(token, getJWTSecret());
    
    if (typeof decoded === 'object' && decoded !== null && 'isAdmin' in decoded) {
      const adminToken = decoded as AdminToken;
      return adminToken.isAdmin ? adminToken : null;
    }
    
    return null;
  } catch (error) {
    return null;
  }
}

/**
 * Hash password (for initial setup)
 */
export async function hashPassword(password: string): Promise<string> {
  return await bcrypt.hash(password, 10);
}

