export const APP_CONFIG = {
  NAME: 'PSG Placement Portal',
  DESCRIPTION: 'MCA Department Placement Management System',
  MAX_FILE_SIZE: 10 * 1024 * 1024, // 10MB
  ALLOWED_FILE_TYPES: {
    RESUME: ['application/pdf'],
    IMAGE: ['image/jpeg', 'image/png', 'image/webp'],
    DOCUMENT: ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
  },
  PAGINATION: {
    DEFAULT_PAGE_SIZE: 20,
    MAX_PAGE_SIZE: 100,
  },
  RATE_LIMITS: {
    API_GENERAL: { windowMs: 60 * 1000, maxRequests: 60 }, // 60 per minute
    API_AUTH: { windowMs: 15 * 60 * 1000, maxRequests: 5 }, // 5 per 15 minutes
    API_UPLOAD: { windowMs: 60 * 1000, maxRequests: 10 }, // 10 per minute
  },
};

export const CLASS_SECTIONS = ['G1', 'G2'] as const;
export const ACADEMIC_YEARS = [1, 2] as const;
export const TOTAL_GROUPS = 20;

export const ERROR_MESSAGES = {
  UNAUTHORIZED: 'You must be logged in to access this resource',
  FORBIDDEN: 'You do not have permission to access this resource',
  NOT_FOUND: 'The requested resource was not found',
  VALIDATION_ERROR: 'Please check your input and try again',
  SERVER_ERROR: 'An unexpected error occurred. Please try again later',
  FILE_TOO_LARGE: `File size must be less than ${APP_CONFIG.MAX_FILE_SIZE / (1024 * 1024)}MB`,
  INVALID_FILE_TYPE: 'Invalid file type',
};

export const SUCCESS_MESSAGES = {
  PROFILE_UPDATED: 'Profile updated successfully',
  PROJECT_CREATED: 'Project created successfully',
  PROJECT_UPDATED: 'Project updated successfully',
  PROJECT_DELETED: 'Project deleted successfully',
  FILE_UPLOADED: 'File uploaded successfully',
  FILE_DELETED: 'File deleted successfully',
};
