export interface Project {
  id: string;
  userId: string;
  title: string;
  description: string;
  technologiesUsed: string[];
  projectUrl?: string | null;
  githubUrl?: string | null;
  thumbnailUrl?: string | null;
  startDate?: Date | null;
  endDate?: Date | null;
  isOngoing: boolean;
  createdAt: Date;
  updatedAt: Date;
}
