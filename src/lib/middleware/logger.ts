export function logRequest(req: any) {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
}

export function logError(error: Error, context?: string) {
  console.error(`[ERROR] ${context || 'Unknown'}:`, error);
}

export function logInfo(message: string, data?: any) {
  console.log(`[INFO] ${message}`, data || '');
}
