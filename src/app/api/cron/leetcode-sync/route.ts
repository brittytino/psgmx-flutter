import { NextRequest, NextResponse } from 'next/server';
import { syncAllLeetCodeProfiles } from '@/lib/leetcode/sync-service';

export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';

// This endpoint is called by Vercel Cron or external scheduler
// Configure in vercel.json:
// "crons": [{ "path": "/api/cron/leetcode-sync", "schedule": "0 2 * * *" }]

export async function GET(request: NextRequest) {
  try {
    // Verify cron secret to prevent unauthorized access
    const authHeader = request.headers.get('authorization');
    const cronSecret = process.env.CRON_SECRET;
    
    if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    console.log('Starting daily LeetCode sync...');
    
    const result = await syncAllLeetCodeProfiles();
    
    console.log('LeetCode sync completed:', result);
    
    return NextResponse.json({
      success: true,
      message: 'LeetCode profiles synced successfully',
      result,
    });
  } catch (error: any) {
    console.error('LeetCode sync cron error:', error);
    return NextResponse.json(
      { error: 'Sync failed', message: error.message },
      { status: 500 }
    );
  }
}
