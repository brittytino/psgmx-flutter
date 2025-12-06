import prisma from '../db/prisma';
import { fetchLeetCodeProfile, parseLeetCodeStats } from './graphql-client';

export async function syncLeetCodeProfile(userId: string, leetcodeUsername: string) {
  try {
    const data = await fetchLeetCodeProfile(leetcodeUsername);
    
    if (!data) {
      throw new Error('Failed to fetch LeetCode profile');
    }

    const stats = parseLeetCodeStats(data);

    const profile = await prisma.leetCodeProfile.upsert({
      where: { userId },
      update: {
        ...stats,
        leetcodeUsername,
        profileData: data as any,
        lastSyncedAt: new Date(),
        syncError: null,
      },
      create: {
        userId,
        ...stats,
        leetcodeUsername,
        profileData: data as any,
        lastSyncedAt: new Date(),
      },
    });

    return profile;
  } catch (error) {
    // Log sync error
    await prisma.leetCodeProfile.upsert({
      where: { userId },
      update: {
        syncError: error instanceof Error ? error.message : 'Unknown error',
        lastSyncedAt: new Date(),
      },
      create: {
        userId,
        leetcodeUsername,
        syncError: error instanceof Error ? error.message : 'Unknown error',
        lastSyncedAt: new Date(),
      },
    });

    throw error;
  }
}
