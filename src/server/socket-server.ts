import { createServer } from 'http';
import { Server } from 'socket.io';
import { initializeSocketServer } from '@/lib/socket/server';

const PORT = process.env.SOCKET_PORT || 3001;

const httpServer = createServer();
const io = initializeSocketServer(httpServer);

httpServer.listen(PORT, () => {
  console.log(`Socket.IO server running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing Socket.IO server');
  io.close(() => {
    httpServer.close(() => {
      console.log('Socket.IO server closed');
      process.exit(0);
    });
  });
});
