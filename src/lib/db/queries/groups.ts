import prisma from '../prisma';

export async function getGroupsByBatch(batchStartYear: number, batchEndYear: number) {
  return prisma.group.findMany({
    where: {
      batchStartYear,
      batchEndYear,
      isActive: true,
    },
    include: {
      _count: {
        select: { members: true },
      },
    },
    orderBy: {
      groupNumber: 'asc',
    },
  });
}

export async function getGroupById(groupId: string) {
  return prisma.group.findUnique({
    where: { id: groupId },
    include: {
      members: {
        include: {
          user: {
            include: {
              studentProfile: {
                select: {
                  fullName: true,
                },
              },
            },
          },
        },
      },
    },
  });
}

export async function getGroupMessages(groupId: string, limit: number = 50) {
  return prisma.message.findMany({
    where: { groupId },
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
    orderBy: { createdAt: 'desc' },
    take: limit,
  });
}

export async function createMessage(groupId: string, userId: string, content: string, moderationData?: any) {
  return prisma.message.create({
    data: {
      groupId,
      userId,
      content,
      isModerated: !!moderationData,
      moderationFlags: moderationData,
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

export async function getUserGroup(userId: string) {
  const membership = await prisma.groupMember.findFirst({
    where: { userId },
    include: {
      group: true,
    },
  });

  return membership?.group || null;
}
