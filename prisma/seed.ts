import { PrismaClient, UserRole, Gender } from '@prisma/client';
import { hashPassword } from '../src/lib/auth/password';

const prisma = new PrismaClient();

async function main() {
  console.log('Starting database seed...');

  // Create Super Admin
  const superAdminPassword = await hashPassword('admin123');
  const superAdmin = await prisma.user.upsert({
    where: { registerNumber: 'ADMIN001' },
    update: {},
    create: {
      registerNumber: 'ADMIN001',
      email: 'admin@psgtech.ac.in',
      password: superAdminPassword,
      role: UserRole.SUPER_ADMIN,
      batchStartYear: 2025,
      batchEndYear: 2027,
      classSection: 'G1',
      academicYear: 1,
    },
  });

  console.log('Super Admin created:', superAdmin.registerNumber);

  // Create Class Representatives
  const classRep1Password = await hashPassword('classrep123');
  const classRep1 = await prisma.user.upsert({
    where: { registerNumber: '2025MCA001' },
    update: {},
    create: {
      registerNumber: '2025MCA001',
      email: 'classrep1@psgtech.ac.in',
      password: classRep1Password,
      role: UserRole.CLASS_REP,
      batchStartYear: 2025,
      batchEndYear: 2027,
      classSection: 'G1',
      academicYear: 1,
    },
  });

  console.log('Class Rep 1 created:', classRep1.registerNumber);

  // Create Sample Students
  const studentPassword = await hashPassword('student123');
  
  const students = [];
  for (let i = 2; i <= 10; i++) {
    const regNo = `2025MCA${i.toString().padStart(3, '0')}`;
    const student = await prisma.user.upsert({
      where: { registerNumber: regNo },
      update: {},
      create: {
        registerNumber: regNo,
        email: `student${i}@psgtech.ac.in`,
        password: studentPassword,
        role: UserRole.STUDENT,
        batchStartYear: 2025,
        batchEndYear: 2027,
        classSection: i % 2 === 0 ? 'G1' : 'G2',
        academicYear: 1,
      },
    });
    students.push(student);
  }

  console.log(`${students.length} students created`);

  // Create Groups (20 groups total)
  for (let i = 1; i <= 20; i++) {
    const classSection = i <= 10 ? 'G1' : 'G2';
    await prisma.group.upsert({
      where: { groupNumber: i },
      update: {},
      create: {
        name: `Group ${i}`,
        groupNumber: i,
        batchStartYear: 2025,
        batchEndYear: 2027,
        classSection,
        academicYear: 1,
        isActive: true,
      },
    });
  }

  console.log('20 groups created');

  // Assign students to groups
  const groups = await prisma.group.findMany();
  for (let i = 0; i < students.length; i++) {
    const groupIndex = i % groups.length;
    await prisma.groupMember.create({
      data: {
        groupId: groups[groupIndex].id,
        userId: students[i].id,
      },
    });
  }

  console.log('Students assigned to groups');

  // Create initial motivation quote
  await prisma.motivationQuote.create({
    data: {
      quote: 'Success is not final, failure is not fatal: it is the courage to continue that counts.',
      author: 'Winston Churchill',
      date: new Date(),
    },
  });

  console.log('Initial motivation quote created');

  console.log('Database seed completed!');
}

main()
  .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
