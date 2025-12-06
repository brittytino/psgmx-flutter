import prisma from '../prisma';

export async function getLeetCodeStats(batchStartYear: number, batchEndYear: number) {
  const users = await prisma.user.findMany({
    where: {
      batchStartYear,
      batchEndYear,
      isActive: true,
    },
    include: {
      studentProfile: {
        select: {
          fullName: true,
          leetcodeUrl: true,
        },
      },
      leetcodeProfile: true,
    },
  });

  return users
    .filter(u => u.leetcodeProfile)
    .map(u => ({
      userId: u.id,
      registerNumber: u.registerNumber,
      fullName: u.studentProfile?.fullName || '',
      leetcodeUrl: u.studentProfile?.leetcodeUrl,
      ...u.leetcodeProfile,
    }));
}

export async function getTopLeetCodePerformers(limit: number = 10) {
  return prisma.leetCodeProfile.findMany({
    take: limit,
    orderBy: {
      totalSolved: 'desc',
    },
    include: {
      user: {
        select: {
          registerNumber: true,
          studentProfile: {
            select: {
              fullName: true,
            },
          },
        },
      },
    },
  });
}
