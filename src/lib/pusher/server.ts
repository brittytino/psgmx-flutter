import Pusher from 'pusher';

export const pusherServer = new Pusher({
  appId: process.env.PUSHER_APP_ID || '',
  key: process.env.PUSHER_KEY || '',
  secret: process.env.PUSHER_SECRET || '',
  cluster: process.env.PUSHER_CLUSTER || 'ap2',
  useTLS: true,
});

export async function triggerPusherEvent(
  channel: string,
  event: string,
  data: any
) {
  try {
    await pusherServer.trigger(channel, event, data);
  } catch (error) {
    console.error('Pusher trigger error:', error);
    throw error;
  }
}

export async function triggerBatchEvents(
  channels: string[],
  event: string,
  data: any
) {
  try {
    await pusherServer.triggerBatch(
      channels.map(channel => ({ channel, name: event, data }))
    );
  } catch (error) {
    console.error('Pusher batch trigger error:', error);
    throw error;
  }
}
