import { NextRequest, NextResponse } from 'next/server';
import { requireAuth, requireSuperAdmin } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { getStudentsByBatch } from '@/lib/db/queries/students';
import { getSession } from '@/lib/auth/session';

export async function GET(req: NextRequest) {
  try {
    const authError = await requireAuth(req);
    if (authError) return authError;

    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(req.url);
    const batchStart = parseInt(searchParams.get('batchStart') || String(session.batchStartYear));
    const batchEnd = parseInt(searchParams.get('batchEnd') || String(session.batchEndYear));

    const students = await getStudentsByBatch(batchStart, batchEnd);

    return NextResponse.json({
      success: true,
      data: students,
    });
  } catch (error) {
    return handleError(error);
  }
}
