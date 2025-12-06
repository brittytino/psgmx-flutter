import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { deleteFromCloudinary } from '@/lib/cloudinary/delete';
import { getSession } from '@/lib/auth/session';
import prisma from '@/lib/db/prisma';

export async function DELETE(
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

    // Get document
    const document = await prisma.document.findFirst({
      where: {
        id: params.id,
        userId: session.userId,
      },
    });

    if (!document) {
      return NextResponse.json({ error: 'Document not found' }, { status: 404 });
    }

    // Delete from Cloudinary
    await deleteFromCloudinary(document.filePublicId);

    // Delete from database
    await prisma.document.delete({
      where: { id: params.id },
    });

    return NextResponse.json({
      success: true,
      message: 'Document deleted successfully',
    });
  } catch (error) {
    return handleError(error);
  }
}
