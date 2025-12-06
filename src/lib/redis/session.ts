import { setCache, getCache, deleteCache } from './client';
import { JWTPayload } from '../auth/jwt';

const SESSION_PREFIX = 'session:';
const SESSION_EXPIRATION = 7 * 24 * 60 * 60; // 7 days in seconds

export async function createSession(
  sessionToken: string,
  user: JWTPayload
): Promise<void> {
  const key = `${SESSION_PREFIX}${sessionToken}`;
  await setCache(key, user, SESSION_EXPIRATION);
}

export async function getSession(
  sessionToken: string
): Promise<JWTPayload | null> {
  const key = `${SESSION_PREFIX}${sessionToken}`;
  return await getCache<JWTPayload>(key);
}

export async function deleteSession(sessionToken: string): Promise<void> {
  const key = `${SESSION_PREFIX}${sessionToken}`;
  await deleteCache(key);
}

export async function updateSessionExpiry(sessionToken: string): Promise<void> {
  const session = await getSession(sessionToken);
  if (session) {
    await createSession(sessionToken, session);
  }
}
