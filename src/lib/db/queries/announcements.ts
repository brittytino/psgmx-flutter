import prisma from '../prisma';

export async function getAnnouncementsByBatch(
  batchStartYear: number,
  batchEndYear: number,
  classSection?: string,
  academicYear?: number
) {
  return prisma.announcement.findMany({
    where: {
      OR: [
        // Global announcements
        {
          batchStartYear: null,
          batchEndYear: null,
          classSection: null,
          academicYear: null,
        },
        // Batch-specific
        {
          batchStartYear,
          batchEndYear,
          classSection: classSection || null,
          academicYear: academicYear || null,
        },
      ],
    },
    orderBy: [
      { isPinned: 'desc' },
      { createdAt: 'desc' },
    ],
  });
}

export async function createAnnouncement(authorId: string, data: any) {
  return prisma.announcement.create({
    data: {
      ...data,
      authorId,
    },
  });
}

export async function updateAnnouncement(announcementId: string, data: any) {
  return prisma.announcement.update({
    where: { id: announcementId },
    data,
  });
}

export async function deleteAnnouncement(announcementId: string) {
  return prisma.announcement.delete({
    where: { id: announcementId },
  });
}
