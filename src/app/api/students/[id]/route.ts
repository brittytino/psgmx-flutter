import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { getStudentById } from '@/lib/db/queries/students';
import { getSession } from '@/lib/auth/session';
import { canManageUser, isSuperAdmin, isClassRep } from '@/lib/auth/permissions';

export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const authError = await requireAuth(req);
    if (authError) return authError;

    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const student = await getStudentById(params.id);

    if (!student) {
      return NextResponse.json({ error: 'Student not found' }, { status: 404 });
    }

    // Check permissions
    const canView = 
      canManageUser(session, params.id) ||
      isSuperAdmin(session) ||
      (isClassRep(session) && student.classSection === session.classSection);

    if (!canView) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    return NextResponse.json({
      success: true,
      data: student,
    });
  } catch (error) {
    return handleError(error);
  }
}

export async function DELETE(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const authError = await requireSuperAdmin(req);
    if (authError) return authError;

    await prisma.user.delete({
      where: { id: params.id },
    });

    return NextResponse.json({
      success: true,
      message: 'Student deleted successfully',
    });
  } catch (error) {
    return handleError(error);
  }
}
