import { prisma } from '@/lib/db/prisma';

export interface AuditLogData {
  userId?: string;
  action: string;
  entityType: string;
  entityId?: string;
  ipAddress?: string;
  userAgent?: string;
  details?: Record<string, any>;
}

export async function createAuditLog(data: AuditLogData): Promise<void> {
  try {
    await prisma.auditLog.create({
      data: {
        userId: data.userId,
        action: data.action,
        entityType: data.entityType,
        entityId: data.entityId,
        ipAddress: data.ipAddress,
        userAgent: data.userAgent,
        details: data.details || {},
      },
    });
  } catch (error) {
    console.error('Failed to create audit log:', error);
    // Don't throw - audit logs shouldn't break the main flow
  }
}

export async function getAuditLogs(filters: {
  userId?: string;
  entityType?: string;
  entityId?: string;
  startDate?: Date;
  endDate?: Date;
  limit?: number;
  offset?: number;
}) {
  const where: any = {};
  
  if (filters.userId) where.userId = filters.userId;
  if (filters.entityType) where.entityType = filters.entityType;
  if (filters.entityId) where.entityId = filters.entityId;
  
  if (filters.startDate || filters.endDate) {
    where.createdAt = {};
    if (filters.startDate) where.createdAt.gte = filters.startDate;
    if (filters.endDate) where.createdAt.lte = filters.endDate;
  }
  
  const [logs, total] = await Promise.all([
    prisma.auditLog.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: filters.limit || 50,
      skip: filters.offset || 0,
    }),
    prisma.auditLog.count({ where }),
  ]);
  
  return { logs, total };
}

// Audit action constants
export const AUDIT_ACTIONS = {
  // Auth
  LOGIN: 'LOGIN',
  LOGOUT: 'LOGOUT',
  LOGIN_FAILED: 'LOGIN_FAILED',
  PASSWORD_CHANGED: 'PASSWORD_CHANGED',
  
  // CRUD
  CREATE: 'CREATE',
  UPDATE: 'UPDATE',
  DELETE: 'DELETE',
  BULK_CREATE: 'BULK_CREATE',
  BULK_DELETE: 'BULK_DELETE',
  
  // Access
  VIEW: 'VIEW',
  DOWNLOAD: 'DOWNLOAD',
  EXPORT: 'EXPORT',
  
  // Admin
  BATCH_HANDOVER: 'BATCH_HANDOVER',
  ROLE_CHANGED: 'ROLE_CHANGED',
  CUSTOM_FIELD_ADDED: 'CUSTOM_FIELD_ADDED',
  
  // Content moderation
  MESSAGE_MODERATED: 'MESSAGE_MODERATED',
  MESSAGE_FLAGGED: 'MESSAGE_FLAGGED',
} as const;

export const ENTITY_TYPES = {
  USER: 'User',
  STUDENT_PROFILE: 'StudentProfile',
  PROJECT: 'Project',
  DOCUMENT: 'Document',
  GROUP: 'Group',
  MESSAGE: 'Message',
  ANNOUNCEMENT: 'Announcement',
  NOTIFICATION: 'Notification',
  LEETCODE_PROFILE: 'LeetCodeProfile',
  CUSTOM_FIELD: 'CustomField',
  BATCH: 'Batch',
} as const;
