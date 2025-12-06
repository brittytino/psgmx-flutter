import { Gender } from '@prisma/client';

export interface StudentProfile {
  id: string;
  userId: string;
  fullName: string;
  dateOfBirth: Date;
  gender: Gender;
  contactNumber: string;
  whatsappNumber?: string | null;
  personalEmail: string;
  ugDegree: string;
  ugCollege: string;
  ugPercentage: number;
  schoolName: string;
  tenthPercentage: number;
  twelfthPercentage?: number | null;
  diplomaPercentage?: number | null;
  technicalSkills: string[];
  certifications: string[];
  areasOfInterest: string[];
  githubUrl?: string | null;
  leetcodeUrl?: string | null;
  linkedinUrl?: string | null;
  portfolioUrl?: string | null;
  otherCodingProfiles?: any;
  resumeUrl?: string | null;
  isProfileComplete: boolean;
  profileCompletionScore: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface StudentWithProfile {
  id: string;
  registerNumber: string;
  email: string;
  classSection: string;
  academicYear: number;
  profile: StudentProfile | null;
  leetcodeProfile?: {
    totalSolved: number;
    easySolved: number;
    mediumSolved: number;
    hardSolved: number;
    ranking?: number | null;
  } | null;
}
