import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { getSession } from '@/lib/auth/session';
import prisma from '@/lib/db/prisma';

export async function PUT(
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

    await prisma.notification.updateMany({
      where: {
        id: params.id,
        userId: session.userId,
      },
      data: {
        isRead: true,
      },
    });

    return NextResponse.json({
      success: true,
      message: 'Notification marked as read',
    });
  } catch (error) {
    return handleError(error);
  }
}
