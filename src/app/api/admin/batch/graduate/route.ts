import { NextRequest, NextResponse } from 'next/server';
import { requireSuperAdmin } from '@/lib/middleware/rbac';
import { handleError } from '@/lib/middleware/error-handler';
import { deleteUsersByBatch } from '@/lib/db/queries/admin';

export async function POST(req: NextRequest) {
  try {
    const authError = await requireSuperAdmin(req);
    if (authError) return authError;

    const body = await req.json();
    const { batchStartYear, batchEndYear } = body;

    if (!batchStartYear || !batchEndYear) {
      return NextResponse.json(
        { error: 'Batch years are required' },
        { status: 400 }
      );
    }

    await deleteUsersByBatch(batchStartYear, batchEndYear);

    return NextResponse.json({
      success: true,
      message: `Batch ${batchStartYear}-${batchEndYear} graduated and data cleared successfully`,
    });
  } catch (error) {
    return handleError(error);
  }
}
