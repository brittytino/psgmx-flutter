import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { studentProfileSchema } from '@/lib/validation/schemas/student';
import { updateStudentProfile, calculateProfileCompletion } from '@/lib/db/queries/students';
import { getSession } from '@/lib/auth/session';
import prisma from '@/lib/db/prisma';

export async function PUT(req: NextRequest) {
  try {
    const authError = await requireAuth(req);
    if (authError) return authError;

    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await req.json();
    const validatedData = studentProfileSchema.parse(body);

    // Update profile
    const profile = await updateStudentProfile(session.userId, validatedData);

    // Calculate completion score
    const completionScore = await calculateProfileCompletion(session.userId);
    
    await prisma.studentProfile.update({
      where: { userId: session.userId },
      data: {
        profileCompletionScore: completionScore,
        isProfileComplete: completionScore >= 80,
      },
    });

    return NextResponse.json({
      success: true,
      data: profile,
      message: 'Profile updated successfully',
    });
  } catch (error) {
    return handleError(error);
  }
}
