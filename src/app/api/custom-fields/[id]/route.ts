import { NextRequest, NextResponse } from 'next/server';
import { requireSuperAdmin } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { updateCustomField } from '@/lib/db/queries/admin';
import prisma from '@/lib/db/prisma';

export async function PUT(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const authError = await requireSuperAdmin(req);
    if (authError) return authError;

    const body = await req.json();
    const field = await updateCustomField(params.id, body);

    return NextResponse.json({
      success: true,
      data: field,
      message: 'Custom field updated successfully',
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

    await prisma.customField.update({
      where: { id: params.id },
      data: { isActive: false },
    });

    return NextResponse.json({
      success: true,
      message: 'Custom field deactivated successfully',
    });
  } catch (error) {
    return handleError(error);
  }
}
