import PusherClient from 'pusher-js';

export const pusherClient = new PusherClient(
  process.env.NEXT_PUBLIC_PUSHER_KEY || '',
  {
    cluster: process.env.NEXT_PUBLIC_PUSHER_CLUSTER || 'ap2',
    forceTLS: true,
  }
);

export function subscribeToChannel(channelName: string) {
  return pusherClient.subscribe(channelName);
}

export function unsubscribeFromChannel(channelName: string) {
  pusherClient.unsubscribe(channelName);
}

export function bindEvent(
  channel: any,
  eventName: string,
  callback: (data: any) => void
) {
  channel.bind(eventName, callback);
}

export function unbindEvent(channel: any, eventName: string) {
  channel.unbind(eventName);
}
