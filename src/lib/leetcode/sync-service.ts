import { prisma } from '@/lib/db/prisma';
import { batchFetchLeetCodeProfiles, fetchLeetCodeProfile, parseLeetCodeStats } from './graphql-client';
import { createAuditLog, AUDIT_ACTIONS, ENTITY_TYPES } from '@/lib/audit/audit-log';

export interface SyncResult {
  success: number;
  failed: number;
  errors: Array<{ username: string; error: string }>;
}

export async function syncSingleUserLeetCode(userId: string): Promise<boolean> {
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        studentProfile: true,
        leetcodeProfile: true,
      },
    });

    if (!user || !user.studentProfile?.leetcodeUrl) {
      return false;
    }

    // Extract username from LeetCode URL
    const username = extractLeetCodeUsername(user.studentProfile.leetcodeUrl);
    
    if (!username) {
      await updateLeetCodeProfile(userId, null, 'Invalid LeetCode URL');
      return false;
    }

    const data = await fetchLeetCodeProfile(username);
    
    if (!data) {
      await updateLeetCodeProfile(userId, null, 'Profile not found');
      return false;
    }

    const stats = parseLeetCodeStats(data);
    
    await prisma.leetCodeProfile.upsert({
      where: { userId },
      create: {
        userId,
        leetcodeUsername: username,
        totalSolved: stats.totalSolved,
        easySolved: stats.easySolved,
        mediumSolved: stats.mediumSolved,
        hardSolved: stats.hardSolved,
        ranking: stats.ranking,
        reputation: stats.reputation,
        profileData: data as any,
        lastSyncedAt: new Date(),
        syncError: null,
      },
      update: {
        totalSolved: stats.totalSolved,
        easySolved: stats.easySolved,
        mediumSolved: stats.mediumSolved,
        hardSolved: stats.hardSolved,
        ranking: stats.ranking,
        reputation: stats.reputation,
        profileData: data as any,
        lastSyncedAt: new Date(),
        syncError: null,
      },
    });

    await createAuditLog({
      userId,
      action: AUDIT_ACTIONS.UPDATE,
      entityType: ENTITY_TYPES.LEETCODE_PROFILE,
      entityId: userId,
      details: { username, stats },
    });

    return true;
  } catch (error: any) {
    console.error(`Failed to sync LeetCode for user ${userId}:`, error);
    await updateLeetCodeProfile(userId, null, error.message);
    return false;
  }
}

export async function syncAllLeetCodeProfiles(batchYear?: { startYear: number; endYear: number }): Promise<SyncResult> {
  const result: SyncResult = {
    success: 0,
    failed: 0,
    errors: [],
  };

  try {
    const where: any = {
      isActive: true,
      studentProfile: {
        leetcodeUrl: { not: null },
      },
    };

    if (batchYear) {
      where.batchStartYear = batchYear.startYear;
      where.batchEndYear = batchYear.endYear;
    }

    const users = await prisma.user.findMany({
      where,
      include: {
        studentProfile: true,
      },
    });

    console.log(`Syncing LeetCode profiles for ${users.length} users...`);

    // Extract usernames
    const usernameMap = new Map<string, string>(); // username -> userId
    for (const user of users) {
      if (user.studentProfile?.leetcodeUrl) {
        const username = extractLeetCodeUsername(user.studentProfile.leetcodeUrl);
        if (username) {
          usernameMap.set(username, user.id);
        }
      }
    }

    const usernames = Array.from(usernameMap.keys());
    const profiles = await batchFetchLeetCodeProfiles(usernames);

    // Update database
    for (const [username, stats] of profiles.entries()) {
      const userId = usernameMap.get(username);
      if (!userId) continue;

      if (stats) {
        try {
          await prisma.leetCodeProfile.upsert({
            where: { userId },
            create: {
              userId,
              leetcodeUsername: username,
              totalSolved: stats.totalSolved,
              easySolved: stats.easySolved,
              mediumSolved: stats.mediumSolved,
              hardSolved: stats.hardSolved,
              ranking: stats.ranking,
              reputation: stats.reputation,
              lastSyncedAt: new Date(),
              syncError: null,
            },
            update: {
              totalSolved: stats.totalSolved,
              easySolved: stats.easySolved,
              mediumSolved: stats.mediumSolved,
              hardSolved: stats.hardSolved,
              ranking: stats.ranking,
              reputation: stats.reputation,
              lastSyncedAt: new Date(),
              syncError: null,
            },
          });
          result.success++;
        } catch (error: any) {
          result.failed++;
          result.errors.push({ username, error: error.message });
        }
      } else {
        result.failed++;
        result.errors.push({ username, error: 'Profile not found' });
        await updateLeetCodeProfile(userId, null, 'Profile not found');
      }
    }

    console.log(`LeetCode sync completed: ${result.success} success, ${result.failed} failed`);
    
    return result;
  } catch (error: any) {
    console.error('Batch LeetCode sync error:', error);
    throw error;
  }
}

function extractLeetCodeUsername(url: string): string | null {
  try {
    // Handle various LeetCode URL formats
    // https://leetcode.com/username/
    // https://leetcode.com/u/username/
    const match = url.match(/leetcode\.com\/(u\/)?([^/]+)/);
    return match ? match[2] : null;
  } catch {
    return null;
  }
}

async function updateLeetCodeProfile(userId: string, stats: any, error: string): Promise<void> {
  await prisma.leetCodeProfile.upsert({
    where: { userId },
    create: {
      userId,
      leetcodeUsername: '',
      syncError: error,
      lastSyncedAt: new Date(),
    },
    update: {
      syncError: error,
      lastSyncedAt: new Date(),
    },
  });
}
