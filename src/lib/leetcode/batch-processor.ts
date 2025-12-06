import prisma from '../db/prisma';
import { syncLeetCodeProfile } from './sync';

const BATCH_SIZE = 5;
const DELAY_BETWEEN_BATCHES = 2000; // 2 seconds

export async function syncAllLeetCodeProfiles() {
  console.log('Starting LeetCode sync for all users...');

  // Get all students with LeetCode URLs
  const students = await prisma.studentProfile.findMany({
    where: {
      leetcodeUrl: { not: null },
    },
    select: {
      userId: true,
      leetcodeUrl: true,
    },
  });

  console.log(`Found ${students.length} students with LeetCode profiles`);

  // Process in batches
  for (let i = 0; i < students.length; i += BATCH_SIZE) {
    const batch = students.slice(i, i + BATCH_SIZE);
    
    await Promise.allSettled(
      batch.map(async (student) => {
        const username = extractLeetCodeUsername(student.leetcodeUrl!);
        if (username) {
          await syncLeetCodeProfile(student.userId, username);
          console.log(`✓ Synced ${username}`);
        }
      })
    );

    // Delay between batches to avoid rate limiting
    if (i + BATCH_SIZE < students.length) {
      await new Promise(resolve => setTimeout(resolve, DELAY_BETWEEN_BATCHES));
    }
  }

  console.log('LeetCode sync completed');
}

function extractLeetCodeUsername(url: string): string | null {
  try {
    const match = url.match(/leetcode\.com\/([^\/]+)/);
    return match ? match[1] : null;
  } catch {
    return null;
  }
}
