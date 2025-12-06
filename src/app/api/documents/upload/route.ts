import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { uploadToCloudinary } from '@/lib/cloudinary/upload';
import { getSession } from '@/lib/auth/session';
import { APP_CONFIG } from '@/lib/utils/constants';
import prisma from '@/lib/db/prisma';

export async function POST(req: NextRequest) {
  try {
    const authError = await requireAuth(req);
    if (authError) return authError;

    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const formData = await req.formData();
    const file = formData.get('file') as File;
    const documentType = formData.get('documentType') as string || 'document';

    if (!file) {
      return NextResponse.json({ error: 'No file provided' }, { status: 400 });
    }

    if (file.size > APP_CONFIG.MAX_FILE_SIZE) {
      return NextResponse.json(
        { error: 'File too large' },
        { status: 400 }
      );
    }

    // Upload to Cloudinary
    const uploadResult = await uploadToCloudinary(
      file,
      `placement-portal/documents/${session.userId}`
    );

    // Save to database
    const document = await prisma.document.create({
      data: {
        userId: session.userId,
        fileName: file.name,
        fileUrl: uploadResult.url,
        filePublicId: uploadResult.publicId,
        fileType: file.type,
        fileSize: file.size,
        documentType,
      },
    });

    // If it's a resume, update student profile
    if (documentType === 'resume') {
      await prisma.studentProfile.update({
        where: { userId: session.userId },
        data: {
          resumeUrl: uploadResult.url,
          resumePublicId: uploadResult.publicId,
        },
      });
    }

    return NextResponse.json({
      success: true,
      data: document,
      message: 'File uploaded successfully',
    });
  } catch (error) {
    return handleError(error);
  }
}
