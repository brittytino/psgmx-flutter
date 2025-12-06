import { NextRequest, NextResponse } from 'next/server';
import { removeSessionToken } from '@/lib/auth/session';

export async function POST(req: NextRequest) {
  try {
    await removeSessionToken();
    
    return NextResponse.json({
      success: true,
      message: 'Logged out successfully',
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Logout failed' },
      { status: 500 }
    );
  }
}
