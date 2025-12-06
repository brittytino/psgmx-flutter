import { UserRole } from '@prisma/client';
import { JWTPayload } from './jwt';

export function hasRole(user: JWTPayload, roles: UserRole[]): boolean {
  return roles.includes(user.role);
}

export function isSuperAdmin(user: JWTPayload): boolean {
  return user.role === UserRole.SUPER_ADMIN;
}

export function isClassRep(user: JWTPayload): boolean {
  return user.role === UserRole.CLASS_REP;
}

export function isStudent(user: JWTPayload): boolean {
  return user.role === UserRole.STUDENT;
}

export function canAccessBatch(user: JWTPayload, batchStartYear: number, batchEndYear: number): boolean {
  return user.batchStartYear === batchStartYear && user.batchEndYear === batchEndYear;
}

export function canAccessClass(user: JWTPayload, classSection: string): boolean {
  if (isSuperAdmin(user)) return true;
  if (isClassRep(user)) return user.classSection === classSection;
  return user.classSection === classSection;
}

export function canManageUser(currentUser: JWTPayload, targetUserId: string): boolean {
  if (isSuperAdmin(currentUser)) return true;
  return currentUser.userId === targetUserId;
}

export function canViewAllGroups(user: JWTPayload): boolean {
  return isSuperAdmin(user);
}

export function canModerateContent(user: JWTPayload): boolean {
  return isSuperAdmin(user) || isClassRep(user);
}
