import { Socket } from 'socket.io';
import prisma from '../../db/prisma';

export async function handleNotificationRead(socket: Socket, data: { notificationId: string }) {
  try {
    const userId = socket.data.user.userId;

    await prisma.notification.updateMany({
      where: {
        id: data.notificationId,
        userId,
      },
      data: {
        isRead: true,
      },
    });

    socket.emit('notification:read-success', { notificationId: data.notificationId });
  } catch (error) {
    console.error('Notification read error:', error);
  }
}
