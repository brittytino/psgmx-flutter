import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { syncLeetCodeProfile } from '@/lib/leetcode/sync';
import { getSession } from '@/lib/auth/session';
import prisma from '@/lib/db/prisma';

export async function POST(req: NextRequest) {
  try {
    const authError = await requireAuth(req);
    if (authError) return authError;

    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await req.json();
    const { leetcodeUsername } = body;

    if (!leetcodeUsername) {
      return NextResponse.json(
        { error: 'LeetCode username is required' },
        { status: 400 }
      );
    }

    const profile = await syncLeetCodeProfile(session.userId, leetcodeUsername);

    // Update student profile with LeetCode URL
    await prisma.studentProfile.update({
      where: { userId: session.userId },
      data: {
        leetcodeUrl: `https://leetcode.com/${leetcodeUsername}`,
      },
    });

    return NextResponse.json({
      success: true,
      data: profile,
      message: 'LeetCode profile synced successfully',
    });
  } catch (error) {
    return handleError(error);
  }
}
