import { NextRequest, NextResponse } from 'next/server';
import { requireAuth, requireSuperAdmin } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { announcementSchema } from '@/lib/validation/schemas/admin';
import { getAnnouncementsByBatch, createAnnouncement } from '@/lib/db/queries/announcements';
import { getSession } from '@/lib/auth/session';

export async function GET(req: NextRequest) {
  try {
    const authError = await requireAuth(req);
    if (authError) return authError;

    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const announcements = await getAnnouncementsByBatch(
      session.batchStartYear,
      session.batchEndYear,
      session.classSection,
      session.academicYear
    );

    return NextResponse.json({
      success: true,
      data: announcements,
    });
  } catch (error) {
    return handleError(error);
  }
}

export async function POST(req: NextRequest) {
  try {
    const authError = await requireSuperAdmin(req);
    if (authError) return authError;

    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await req.json();
    const validatedData = announcementSchema.parse(body);

    const announcement = await createAnnouncement(session.userId, validatedData);

    return NextResponse.json({
      success: true,
      data: announcement,
      message: 'Announcement created successfully',
    });
  } catch (error) {
    return handleError(error);
  }
}
