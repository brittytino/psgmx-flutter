export interface Group {
  id: string;
  name: string;
  groupNumber: number;
  batchStartYear: number;
  batchEndYear: number;
  classSection: string;
  academicYear: number;
  isActive: boolean;
  memberCount?: number;
}

export interface Message {
  id: string;
  groupId: string;
  userId: string;
  content: string;
  isModerated: boolean;
  moderationFlags?: any;
  createdAt: Date;
  user: {
    registerNumber: string;
    studentProfile?: {
      fullName: string;
    } | null;
  };
}

export interface GroupWithMessages extends Group {
  messages: Message[];
}
