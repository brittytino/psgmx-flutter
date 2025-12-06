import { UserRole } from '@prisma/client';

export interface AuthUser {
  id: string;
  registerNumber: string;
  email: string;
  role: UserRole;
  batchStartYear: number;
  batchEndYear: number;
  classSection: string;
  academicYear: number;
}

export interface LoginResponse {
  user: AuthUser;
  token: string;
}

export interface SessionData extends AuthUser {
  isActive: boolean;
}
