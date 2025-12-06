import { NextRequest, NextResponse } from 'next/server';
import { requireAuth, requireSuperAdmin } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { customFieldSchema } from '@/lib/validation/schemas/admin';
import { getAllCustomFields, createCustomField } from '@/lib/db/queries/admin';

export async function GET(req: NextRequest) {
  try {
    const authError = await requireAuth(req);
    if (authError) return authError;

    const fields = await getAllCustomFields();

    return NextResponse.json({
      success: true,
      data: fields,
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
    const validatedData = customFieldSchema.parse(body);

    const field = await createCustomField(validatedData);

    return NextResponse.json({
      success: true,
      data: field,
      message: 'Custom field created successfully',
    });
  } catch (error) {
    return handleError(error);
  }
}
