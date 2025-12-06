import { NextRequest, NextResponse } from 'next/server';
import { requireSuperAdmin } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { bulkUploadSchema } from '@/lib/validation/schemas/admin';
import { bulkCreateUsers } from '@/lib/db/queries/admin';

export async function POST(req: NextRequest) {
  try {
    const authError = await requireSuperAdmin(req);
    if (authError) return authError;

    const body = await req.json();
    const users = bulkUploadSchema.parse(body.users);

    const result = await bulkCreateUsers(users);

    return NextResponse.json({
      success: true,
      data: {
        created: result.count,
      },
      message: `${result.count} users created successfully`,
    });
  } catch (error) {
    return handleError(error);
  }
}
