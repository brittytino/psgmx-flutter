import prisma from '../prisma';

export async function getProjectsByUser(userId: string) {
  return prisma.project.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
  });
}

export async function createProject(userId: string, data: any) {
  return prisma.project.create({
    data: {
      userId,
      ...data,
    },
  });
}

export async function updateProject(projectId: string, userId: string, data: any) {
  return prisma.project.updateMany({
    where: {
      id: projectId,
      userId, // Ensure user owns the project
    },
    data,
  });
}

export async function deleteProject(projectId: string, userId: string) {
  return prisma.project.deleteMany({
    where: {
      id: projectId,
      userId,
    },
  });
}
