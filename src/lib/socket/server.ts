import { Server as SocketIOServer } from 'socket.io';
import { Server as HTTPServer } from 'http';
import { verifyToken } from '../auth/jwt';
import { handleChatMessage, handleTyping, handleJoinGroup } from './handlers/chat';
import { handleNotificationRead } from './handlers/notifications';

export function initializeSocketServer(httpServer: HTTPServer) {
  const io = new SocketIOServer(httpServer, {
    cors: {
      origin: [
        'http://localhost:3000',
        'capacitor://localhost',
        'ionic://localhost',
        process.env.NEXT_PUBLIC_APP_URL || '',
      ],
      credentials: true,
    },
  });

  // Authentication middleware
  io.use(async (socket, next) => {
    const token = socket.handshake.auth.token;
    
    if (!token) {
      return next(new Error('Authentication error'));
    }

    const payload = verifyToken(token);
    if (!payload) {
      return next(new Error('Invalid token'));
    }

    socket.data.user = payload;
    next();
  });

  io.on('connection', (socket) => {
    console.log(`User connected: ${socket.data.user.userId}`);

    // Join user's personal room
    socket.join(`user:${socket.data.user.userId}`);

    // Chat handlers
    socket.on('chat:join-group', (data) => handleJoinGroup(socket, data));
    socket.on('chat:message', (data) => handleChatMessage(io, socket, data));
    socket.on('chat:typing', (data) => handleTyping(socket, data));

    // Notification handlers
    socket.on('notification:read', (data) => handleNotificationRead(socket, data));

    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.data.user.userId}`);
    });
  });

  return io;
}
