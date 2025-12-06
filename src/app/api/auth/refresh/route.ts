import { NextRequest, NextResponse } from 'next/server';
import { getSession, setSessionToken } from '@/lib/auth/session';
import { signToken } from '@/lib/auth/jwt';

export async function POST(req: NextRequest) {
  try {
    const session = await getSession();
    
    if (!session) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    // Generate new token
    const newToken = signToken(session);
    await setSessionToken(newToken);

    return NextResponse.json({
      success: true,
      data: { token: newToken },
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Token refresh failed' },
      { status: 500 }
    );
  }
}
