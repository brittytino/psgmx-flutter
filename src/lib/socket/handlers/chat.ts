import { Server as SocketIOServer, Socket } from 'socket.io';
import { createMessage, getGroupById } from '../../db/queries/groups';
import { moderateContent } from '../../openrouter/moderation';
import { isSuperAdmin } from '../../auth/permissions';

export async function handleJoinGroup(socket: Socket, data: { groupId: string }) {
  try {
    const group = await getGroupById(data.groupId);
    
    if (!group) {
      socket.emit('error', { message: 'Group not found' });
      return;
    }

    // Check if user has access
    const user = socket.data.user;
    const isMember = group.members.some(m => m.userId === user.userId);
    
    if (!isMember && !isSuperAdmin(user)) {
      socket.emit('error', { message: 'Access denied' });
      return;
    }

    socket.join(`group:${data.groupId}`);
    socket.emit('chat:joined', { groupId: data.groupId });
  } catch (error) {
    console.error('Join group error:', error);
    socket.emit('error', { message: 'Failed to join group' });
  }
}

export async function handleChatMessage(
  io: SocketIOServer,
  socket: Socket,
  data: { groupId: string; content: string }
) {
  try {
    const user = socket.data.user;

    // Moderate content
    const moderation = await moderateContent(data.content);
    
    if (!moderation.isClean && moderation.confidence > 0.7) {
      socket.emit('chat:message-blocked', {
        message: 'Your message was blocked due to inappropriate content',
        flags: moderation.flags,
      });
      return;
    }

    // Create message
    const message = await createMessage(
      data.groupId,
      user.userId,
      data.content,
      moderation
    );

    // Broadcast to group
    io.to(`group:${data.groupId}`).emit('chat:message', message);
  } catch (error) {
    console.error('Chat message error:', error);
    socket.emit('error', { message: 'Failed to send message' });
  }
}

export function handleTyping(socket: Socket, data: { groupId: string; isTyping: boolean }) {
  socket.to(`group:${data.groupId}`).emit('chat:user-typing', {
    userId: socket.data.user.userId,
    isTyping: data.isTyping,
  });
}
