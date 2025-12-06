import { NextRequest, NextResponse } from 'next/server';
import { UserRole } from '@prisma/client';
import { getSession } from '../auth/session';
import { verifyToken } from '@/lib/auth/jwt';

export interface AuthContext {
  userId: string;
  registerNumber: string;
  email: string;
  role: UserRole;
  batchStartYear: number;
  batchEndYear: number;
  classSection: string;
  academicYear: number;
}

export async function authenticate(
  request: NextRequest
): Promise<{ success: false; response: NextResponse } | { success: true; user: AuthContext }> {
  try {
    const token = request.headers.get('authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return {
        success: false,
        response: NextResponse.json(
          { error: 'Authentication required' },
          { status: 401 }
        ),
      };
    }
    
    const decoded = verifyToken(token);
    
    if (!decoded) {
      return {
        success: false,
        response: NextResponse.json(
          { error: 'Invalid or expired token' },
          { status: 401 }
        ),
      };
    }
    
    return {
      success: true,
      user: decoded as AuthContext,
    };
  } catch (error) {
    console.error('Authentication error:', error);
    return {
      success: false,
      response: NextResponse.json(
        { error: 'Authentication failed' },
        { status: 401 }
      ),
    };
  }
}

export async function requireAuth(req: NextRequest): Promise<NextResponse | null> {
  const session = await getSession();
  
  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized - Please login' },
      { status: 401 }
    );
  }

  return null;
}

export async function requireRole(req: NextRequest, allowedRoles: UserRole[]): Promise<NextResponse | null> {
  const session = await getSession();
  
  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized - Please login' },
      { status: 401 }
    );
  }

  if (!allowedRoles.includes(session.role)) {
    return NextResponse.json(
      { error: 'Forbidden - Insufficient permissions' },
      { status: 403 }
    );
  }

  return null;
}

export async function requireSuperAdmin(req: NextRequest): Promise<NextResponse | null> {
  return requireRole(req, [UserRole.SUPER_ADMIN]);
}

export async function requireClassRepOrAdmin(req: NextRequest): Promise<NextResponse | null> {
  return requireRole(req, [UserRole.SUPER_ADMIN, UserRole.CLASS_REP]);
}
