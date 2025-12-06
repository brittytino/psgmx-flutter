import { NextRequest, NextResponse } from 'next/server';
import { requireSuperAdmin } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { createUserSchema } from '@/lib/validation/schemas/admin';
import { createUser } from '@/lib/db/queries/admin';
import prisma from '@/lib/db/prisma';
import { UserRole } from '@prisma/client';

export async function GET(req: NextRequest) {
  try {
    const authError = await requireSuperAdmin(req);
    if (authError) return authError;

    const admins = await prisma.user.findMany({
      where: {
        role: {
          in: [UserRole.SUPER_ADMIN, UserRole.CLASS_REP],
        },
      },
      select: {
        id: true,
        registerNumber: true,
        email: true,
        role: true,
        batchStartYear: true,
        batchEndYear: true,
        classSection: true,
        isActive: true,
        createdAt: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return NextResponse.json({
      success: true,
      data: admins,
    });
  } catch (error) {
    return handleError(error);
  }
}

export async function POST(req: NextRequest) {
  try {
    const authError = await requireSuperAdmin(req);
    if (authError) return authError;

    const body = await req.json();
    const validatedData = createUserSchema.parse(body);

    const user = await createUser(validatedData);

    return NextResponse.json({
      success: true,
      data: user,
      message: 'Admin created successfully',
    });
  } catch (error) {
    return handleError(error);
  }
}
