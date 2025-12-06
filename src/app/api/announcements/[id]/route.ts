import { NextRequest, NextResponse } from 'next/server';
import { requireSuperAdmin } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { announcementSchema } from '@/lib/validation/schemas/admin';
import { updateAnnouncement, deleteAnnouncement } from '@/lib/db/queries/announcements';

export async function PUT(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const authError = await requireSuperAdmin(req);
    if (authError) return authError;

    const body = await req.json();
    const validatedData = announcementSchema.parse(body);

    const announcement = await updateAnnouncement(params.id, validatedData);

    return NextResponse.json({
      success: true,
      data: announcement,
      message: 'Announcement updated successfully',
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

    await deleteAnnouncement(params.id);

    return NextResponse.json({
      success: true,
      message: 'Announcement deleted successfully',
    });
  } catch (error) {
    return handleError(error);
  }
}
