import { NextRequest, NextResponse } from 'next/server';
import { loginSchema } from '@/lib/validation/schemas/auth';
import { comparePassword } from '@/lib/auth/password';
import { signToken } from '@/lib/auth/jwt';
import { setSessionToken } from '@/lib/auth/session';
import { handleError } from '@/lib/middleware/error-handler';
import { rateLimit } from '@/lib/middleware/rate-limit';
import { APP_CONFIG } from '@/lib/utils/constants';
import prisma from '@/lib/db/prisma';

const limiter = rateLimit(APP_CONFIG.RATE_LIMITS.API_AUTH);

export async function POST(req: NextRequest) {
  try {
    // Rate limiting
    const rateLimitError = await limiter(req);
    if (rateLimitError) return rateLimitError;

    const body = await req.json();
    const { registerNumber, password } = loginSchema.parse(body);

    // Find user
    const user = await prisma.user.findUnique({
      where: { registerNumber },
      include: {
        studentProfile: {
          select: {
            fullName: true,
          },
        },
      },
    });

    if (!user || !user.isActive) {
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      );
    }

    // Verify password
    const isValidPassword = await comparePassword(password, user.password);
    if (!isValidPassword) {
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      );
    }

    // Update last login
    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    // Generate token
    const token = signToken({
      userId: user.id,
      registerNumber: user.registerNumber,
      email: user.email,
      role: user.role,
      batchStartYear: user.batchStartYear,
      batchEndYear: user.batchEndYear,
      classSection: user.classSection,
      academicYear: user.academicYear,
    });

    // Set session cookie
    await setSessionToken(token);

    return NextResponse.json({
      success: true,
      data: {
        user: {
          id: user.id,
          registerNumber: user.registerNumber,
          email: user.email,
          role: user.role,
          fullName: user.studentProfile?.fullName || '',
        },
        token,
      },
    });
  } catch (error) {
    return handleError(error);
  }
}
