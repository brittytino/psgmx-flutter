'use client';

import { useEffect, useState, useRef } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import MessageList from './MessageList';
import MessageInput from './MessageInput';
import { useSocket } from '@/lib/hooks/useSocket';
import { useAuth } from '@/lib/hooks/useAuth';
import axios from 'axios';

interface ChatWindowProps {
  groupId: string;
}

export default function ChatWindow({ groupId }: ChatWindowProps) {
  const { user } = useAuth();
  const [messages, setMessages] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const { socket, connected, emit, on, off } = useSocket(null);

  useEffect(() => {
    fetchMessages();
  }, [groupId]);

  useEffect(() => {
    if (!socket || !connected) return;

    // Join group
    emit('chat:join-group', { groupId });

    // Listen for new messages
    on('chat:message', (message: any) => {
      setMessages((prev) => [...prev, message]);
    });

    // Listen for typing indicators
    on('chat:user-typing', (data: any) => {
      // Handle typing indicator
      console.log('User typing:', data);
    });

    // Listen for blocked messages
    on('chat:message-blocked', (data: any) => {
      alert(data.message);
    });

    return () => {
      off('chat:message');
      off('chat:user-typing');
      off('chat:message-blocked');
    };
  }, [socket, connected, groupId]);

  const fetchMessages = async () => {
    try {
      const response = await axios.get(`/api/groups/${groupId}/messages`);
      setMessages(response.data.data);
    } catch (error) {
      console.error('Failed to fetch messages:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSendMessage = (content: string) => {
    if (!socket || !connected) {
      alert('Not connected to chat server');
      return;
    }

    emit('chat:message', { groupId, content });
  };

  const handleTyping = (isTyping: boolean) => {
    if (socket && connected) {
      emit('chat:typing', { groupId, isTyping });
    }
  };

  if (loading) {
    return <div>Loading messages...</div>;
  }

  return (
    <Card className="h-[600px] flex flex-col">
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <span>Group Chat</span>
          <span className="text-sm font-normal text-muted-foreground">
            {connected ? (
              <span className="flex items-center gap-2">
                <span className="h-2 w-2 bg-green-500 rounded-full" />
                Connected
              </span>
            ) : (
              <span className="flex items-center gap-2">
                <span className="h-2 w-2 bg-red-500 rounded-full" />
                Disconnected
              </span>
            )}
          </span>
        </CardTitle>
      </CardHeader>
      <CardContent className="flex-1 flex flex-col p-0">
        <MessageList messages={messages} currentUserId={user?.id || ''} />
        <MessageInput onSendMessage={handleSendMessage} onTyping={handleTyping} />
      </CardContent>
    </Card>
  );
}
