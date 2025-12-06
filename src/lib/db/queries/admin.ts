import prisma from '../prisma';
import { hashPassword } from '../../auth/password';

export async function createUser(data: any) {
  const hashedPassword = await hashPassword(data.password);
  
  return prisma.user.create({
    data: {
      ...data,
      password: hashedPassword,
    },
  });
}

export async function bulkCreateUsers(users: any[]) {
  const usersWithHashedPasswords = await Promise.all(
    users.map(async (user) => ({
      ...user,
      password: await hashPassword(user.password),
    }))
  );

  return prisma.user.createMany({
    data: usersWithHashedPasswords,
    skipDuplicates: true,
  });
}

export async function deleteUsersByBatch(batchStartYear: number, batchEndYear: number) {
  // Delete all related data first (cascade should handle this, but being explicit)
  await prisma.user.deleteMany({
    where: {
      batchStartYear,
      batchEndYear,
    },
  });
}

export async function getAllCustomFields() {
  return prisma.customField.findMany({
    where: { isActive: true },
    orderBy: { createdAt: 'asc' },
  });
}

export async function createCustomField(data: any) {
  return prisma.customField.create({
    data,
  });
}

export async function updateCustomField(fieldId: string, data: any) {
  return prisma.customField.update({
    where: { id: fieldId },
    data,
  });
}
