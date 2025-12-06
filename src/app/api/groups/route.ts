import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { getGroupsByBatch, getUserGroup } from '@/lib/db/queries/groups';
import { getSession } from '@/lib/auth/session';
import { isSuperAdmin } from '@/lib/auth/permissions';

export async function GET(req: NextRequest) {
  try {
    const authError = await requireAuth(req);
    if (authError) return authError;

    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Super admins see all groups, students see only their group
    let groups;
    if (isSuperAdmin(session)) {
      groups = await getGroupsByBatch(session.batchStartYear, session.batchEndYear);
    } else {
      const userGroup = await getUserGroup(session.userId);
      groups = userGroup ? [userGroup] : [];
    }

    return NextResponse.json({
      success: true,
      data: groups,
    });
  } catch (error) {
    return handleError(error);
  }
}
