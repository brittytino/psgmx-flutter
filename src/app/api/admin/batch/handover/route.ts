import { NextRequest, NextResponse } from 'next/server';
import { requireSuperAdmin } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { hashPassword } from '@/lib/auth/password';
import prisma from '@/lib/db/prisma';
import { UserRole } from '@prisma/client';

export async function POST(req: NextRequest) {
  try {
    const authError = await requireSuperAdmin(req);
    if (authError) return authError;

    const body = await req.json();
    const { newAdminData } = body;

    // Create new super admin
    const hashedPassword = await hashPassword(newAdminData.password);
    
    await prisma.user.create({
      data: {
        registerNumber: newAdminData.registerNumber,
        email: newAdminData.email,
        password: hashedPassword,
        role: UserRole.SUPER_ADMIN,
        batchStartYear: newAdminData.batchStartYear,
        batchEndYear: newAdminData.batchEndYear,
        classSection: newAdminData.classSection,
        academicYear: newAdminData.academicYear,
      },
    });

    return NextResponse.json({
      success: true,
      message: 'Handover completed successfully',
    });
  } catch (error) {
    return handleError(error);
  }
}
