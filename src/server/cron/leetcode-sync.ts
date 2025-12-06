import { syncAllLeetCodeProfiles } from '@/lib/leetcode/batch-processor';

export async function runLeetCodeSync() {
  try {
    console.log('Starting LeetCode sync job...');
    await syncAllLeetCodeProfiles();
    console.log('LeetCode sync job completed successfully');
  } catch (error) {
    console.error('LeetCode sync job failed:', error);
  }
}

// Run every 24 hours
const SYNC_INTERVAL = 24 * 60 * 60 * 1000; // 24 hours

if (process.env.LEETCODE_SYNC_ENABLED === 'true') {
  setInterval(() => {
    runLeetCodeSync();
  }, SYNC_INTERVAL);

  // Run once on startup
  runLeetCodeSync();
}
