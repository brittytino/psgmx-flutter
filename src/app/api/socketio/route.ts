import { NextRequest, NextResponse } from 'next/server';

// This is a placeholder for Socket.IO initialization
// The actual server is handled in src/server/socket-server.ts

export async function GET(req: NextRequest) {
  return NextResponse.json({
    message: 'Socket.IO server is running on port 3001',
    url: process.env.NEXT_PUBLIC_SOCKET_URL || 'http://localhost:3001',
  });
}
