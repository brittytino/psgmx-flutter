import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { getLeetCodeStats } from '@/lib/db/queries/leetcode';
import { getSession } from '@/lib/auth/session';

export async function GET(req: NextRequest) {
  try {
    const authError = await requireAuth(req);
    if (authError) return authError;

    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const stats = await getLeetCodeStats(session.batchStartYear, session.batchEndYear);

    return NextResponse.json({
      success: true,
      data: stats,
    });
  } catch (error) {
    return handleError(error);
  }
}
