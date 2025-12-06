import { UserRole } from '@prisma/client';

declare module 'next-auth' {
  interface Session {
    user: {
      id: string;
      registerNumber: string;
      email: string;
      role: UserRole;
      classSection: string;
      academicYear: number;
    };
  }

  interface User {
    id: string;
    registerNumber: string;
    email: string;
    role: UserRole;
    classSection: string;
    academicYear: number;
  }
}

declare module 'next-auth/jwt' {
  interface JWT {
    id: string;
    registerNumber: string;
    role: UserRole;
    classSection: string;
    academicYear: number;
  }
}
