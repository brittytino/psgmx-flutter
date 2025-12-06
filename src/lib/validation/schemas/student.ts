import { z } from 'zod';
import { Gender } from '@prisma/client';

export const studentProfileSchema = z.object({
  fullName: z.string().min(2, 'Full name must be at least 2 characters'),
  dateOfBirth: z.string().or(z.date()),
  gender: z.nativeEnum(Gender),
  contactNumber: z.string().regex(/^\d{10}$/, 'Contact number must be 10 digits'),
  whatsappNumber: z.string().regex(/^\d{10}$/, 'WhatsApp number must be 10 digits').optional(),
  personalEmail: z.string().email('Invalid email address'),
  
  ugDegree: z.string().min(2, 'UG Degree is required'),
  ugCollege: z.string().min(2, 'UG College is required'),
  ugPercentage: z.number().min(0).max(100, 'Percentage must be between 0 and 100'),
  schoolName: z.string().min(2, 'School name is required'),
  tenthPercentage: z.number().min(0).max(100),
  twelfthPercentage: z.number().min(0).max(100).optional().nullable(),
  diplomaPercentage: z.number().min(0).max(100).optional().nullable(),
  
  technicalSkills: z.array(z.string()).min(1, 'At least one skill is required'),
  certifications: z.array(z.string()).default([]),
  areasOfInterest: z.array(z.string()).min(1, 'At least one area of interest is required'),
  
  githubUrl: z.string().url('Invalid GitHub URL').optional().or(z.literal('')),
  leetcodeUrl: z.string().url('Invalid LeetCode URL').optional().or(z.literal('')),
  linkedinUrl: z.string().url('Invalid LinkedIn URL').optional().or(z.literal('')),
  portfolioUrl: z.string().url('Invalid Portfolio URL').optional().or(z.literal('')),
  otherCodingProfiles: z.record(z.string()).optional(),
});

export const updateStudentProfileSchema = studentProfileSchema.partial();

export type StudentProfileInput = z.infer<typeof studentProfileSchema>;
export type UpdateStudentProfileInput = z.infer<typeof updateStudentProfileSchema>;
