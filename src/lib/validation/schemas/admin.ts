import { z } from 'zod';
import { UserRole } from '@prisma/client';

export const createUserSchema = z.object({
  registerNumber: z.string().min(1, 'Register number is required'),
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  role: z.nativeEnum(UserRole),
  batchStartYear: z.number().int().min(2020).max(2050),
  batchEndYear: z.number().int().min(2020).max(2050),
  classSection: z.enum(['G1', 'G2']),
  academicYear: z.number().int().min(1).max(2),
});

export const bulkUploadSchema = z.array(createUserSchema);

export const announcementSchema = z.object({
  title: z.string().min(3, 'Title must be at least 3 characters'),
  content: z.string().min(10, 'Content must be at least 10 characters'),
  batchStartYear: z.number().optional().nullable(),
  batchEndYear: z.number().optional().nullable(),
  classSection: z.string().optional().nullable(),
  academicYear: z.number().optional().nullable(),
  isPinned: z.boolean().default(false),
});

export const customFieldSchema = z.object({
  fieldName: z.string().min(1, 'Field name is required'),
  fieldType: z.enum(['text', 'number', 'date', 'select', 'multiselect']),
  fieldLabel: z.string().min(1, 'Field label is required'),
  isRequired: z.boolean().default(false),
  options: z.array(z.string()).optional(),
});

export type CreateUserInput = z.infer<typeof createUserSchema>;
export type BulkUploadInput = z.infer<typeof bulkUploadSchema>;
export type AnnouncementInput = z.infer<typeof announcementSchema>;
export type CustomFieldInput = z.infer<typeof customFieldSchema>;
