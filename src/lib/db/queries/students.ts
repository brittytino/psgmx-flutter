import prisma from '../prisma';
import { UserRole } from '@prisma/client';

export async function getStudentsByBatch(batchStartYear: number, batchEndYear: number) {
  return prisma.user.findMany({
    where: {
      role: UserRole.STUDENT,
      batchStartYear,
      batchEndYear,
      isActive: true,
    },
    include: {
      studentProfile: true,
      leetcodeProfile: {
        select: {
          totalSolved: true,
          easySolved: true,
          mediumSolved: true,
          hardSolved: true,
          ranking: true,
          lastSyncedAt: true,
        },
      },
    },
    orderBy: {
      registerNumber: 'asc',
    },
  });
}

export async function getStudentsByClass(
  batchStartYear: number,
  batchEndYear: number,
  classSection: string
) {
  return prisma.user.findMany({
    where: {
      role: UserRole.STUDENT,
      batchStartYear,
      batchEndYear,
      classSection,
      isActive: true,
    },
    include: {
      studentProfile: true,
      leetcodeProfile: true,
    },
    orderBy: {
      registerNumber: 'asc',
    },
  });
}

export async function getStudentById(userId: string) {
  return prisma.user.findUnique({
    where: { id: userId },
    include: {
      studentProfile: true,
      projects: {
        orderBy: { createdAt: 'desc' },
      },
      documents: {
        orderBy: { createdAt: 'desc' },
      },
      leetcodeProfile: true,
    },
  });
}

export async function updateStudentProfile(userId: string, data: any) {
  return prisma.studentProfile.upsert({
    where: { userId },
    update: data,
    create: {
      userId,
      ...data,
    },
  });
}

export async function calculateProfileCompletion(userId: string): Promise<number> {
  const profile = await prisma.studentProfile.findUnique({
    where: { userId },
  });

  if (!profile) return 0;

  const requiredFields = [
    'fullName',
    'dateOfBirth',
    'gender',
    'contactNumber',
    'personalEmail',
    'ugDegree',
    'ugCollege',
    'ugPercentage',
    'schoolName',
    'tenthPercentage',
    'resumeUrl',
  ];

  const optionalFields = [
    'githubUrl',
    'leetcodeUrl',
    'linkedinUrl',
    'portfolioUrl',
  ];

  const requiredScore = requiredFields.filter(field => {
    const value = (profile as any)[field];
    return value !== null && value !== undefined && value !== '';
  }).length;

  const optionalScore = optionalFields.filter(field => {
    const value = (profile as any)[field];
    return value !== null && value !== undefined && value !== '';
  }).length;

  const hasSkills = profile.technicalSkills.length > 0;
  const hasInterests = profile.areasOfInterest.length > 0;

  const total = (requiredScore / requiredFields.length) * 70 +
                (optionalScore / optionalFields.length) * 20 +
                (hasSkills ? 5 : 0) +
                (hasInterests ? 5 : 0);

  return Math.round(total);
}
