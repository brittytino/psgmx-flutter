import { setCache, getCache, deleteCache, clearCacheByPattern } from './client';

const CACHE_PREFIXES = {
  LEETCODE: 'leetcode:',
  USER: 'user:',
  PROFILE: 'profile:',
  GROUP: 'group:',
  ANNOUNCEMENT: 'announcement:',
} as const;

const CACHE_TTL = {
  LEETCODE: 3600, // 1 hour
  USER: 1800, // 30 minutes
  PROFILE: 1800, // 30 minutes
  GROUP: 900, // 15 minutes
  ANNOUNCEMENT: 600, // 10 minutes
} as const;

// LeetCode profile caching
export async function cacheLeetCodeProfile(userId: string, data: any): Promise<void> {
  await setCache(`${CACHE_PREFIXES.LEETCODE}${userId}`, data, CACHE_TTL.LEETCODE);
}

export async function getCachedLeetCodeProfile(userId: string): Promise<any | null> {
  return await getCache(`${CACHE_PREFIXES.LEETCODE}${userId}`);
}

export async function invalidateLeetCodeCache(userId?: string): Promise<void> {
  if (userId) {
    await deleteCache(`${CACHE_PREFIXES.LEETCODE}${userId}`);
  } else {
    await clearCacheByPattern(`${CACHE_PREFIXES.LEETCODE}*`);
  }
}

// User caching
export async function cacheUser(userId: string, data: any): Promise<void> {
  await setCache(`${CACHE_PREFIXES.USER}${userId}`, data, CACHE_TTL.USER);
}

export async function getCachedUser(userId: string): Promise<any | null> {
  return await getCache(`${CACHE_PREFIXES.USER}${userId}`);
}

export async function invalidateUserCache(userId: string): Promise<void> {
  await deleteCache(`${CACHE_PREFIXES.USER}${userId}`);
}

// Profile caching
export async function cacheProfile(userId: string, data: any): Promise<void> {
  await setCache(`${CACHE_PREFIXES.PROFILE}${userId}`, data, CACHE_TTL.PROFILE);
}

export async function getCachedProfile(userId: string): Promise<any | null> {
  return await getCache(`${CACHE_PREFIXES.PROFILE}${userId}`);
}

export async function invalidateProfileCache(userId: string): Promise<void> {
  await deleteCache(`${CACHE_PREFIXES.PROFILE}${userId}`);
}

// Group caching
export async function cacheGroup(groupId: string, data: any): Promise<void> {
  await setCache(`${CACHE_PREFIXES.GROUP}${groupId}`, data, CACHE_TTL.GROUP);
}

export async function getCachedGroup(groupId: string): Promise<any | null> {
  return await getCache(`${CACHE_PREFIXES.GROUP}${groupId}`);
}

export async function invalidateGroupCache(groupId?: string): Promise<void> {
  if (groupId) {
    await deleteCache(`${CACHE_PREFIXES.GROUP}${groupId}`);
  } else {
    await clearCacheByPattern(`${CACHE_PREFIXES.GROUP}*`);
  }
}

// Announcement caching
export async function cacheAnnouncements(data: any): Promise<void> {
  await setCache(`${CACHE_PREFIXES.ANNOUNCEMENT}list`, data, CACHE_TTL.ANNOUNCEMENT);
}

export async function getCachedAnnouncements(): Promise<any | null> {
  return await getCache(`${CACHE_PREFIXES.ANNOUNCEMENT}list`);
}

export async function invalidateAnnouncementCache(): Promise<void> {
  await clearCacheByPattern(`${CACHE_PREFIXES.ANNOUNCEMENT}*`);
}
