'use client';

import { useEffect, useRef } from 'react';
import { formatDateTime } from '@/lib/utils/format';
import { cn } from '@/lib/utils/format';

interface Message {
  id: string;
  content: string;
  createdAt: Date;
  userId: string;
  user: {
    registerNumber: string;
    studentProfile?: {
      fullName: string;
    } | null;
  };
}

interface MessageListProps {
  messages: Message[];
  currentUserId: string;
}

export default function MessageList({ messages, currentUserId }: MessageListProps) {
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  return (
    <div className="flex-1 overflow-y-auto p-4 space-y-4">
      {messages.length === 0 ? (
        <div className="flex items-center justify-center h-full">
          <p className="text-muted-foreground">No messages yet. Start the conversation!</p>
        </div>
      ) : (
        messages.map((message) => {
          const isOwnMessage = message.userId === currentUserId;
          const userName = message.user.studentProfile?.fullName || message.user.registerNumber;

          return (
            <div
              key={message.id}
              className={cn(
                'flex flex-col',
                isOwnMessage ? 'items-end' : 'items-start'
              )}
            >
              {!isOwnMessage && (
                <span className="text-xs text-muted-foreground mb-1 px-2">
                  {userName}
                </span>
              )}
              <div
                className={cn(
                  'max-w-[70%] rounded-lg px-4 py-2',
                  isOwnMessage
                    ? 'bg-primary text-primary-foreground'
                    : 'bg-muted'
                )}
              >
                <p className="text-sm whitespace-pre-wrap break-words">
                  {message.content}
                </p>
                <span className={cn(
                  'text-xs mt-1 block',
                  isOwnMessage ? 'text-primary-foreground/70' : 'text-muted-foreground'
                )}>
                  {formatDateTime(message.createdAt)}
                </span>
              </div>
            </div>
          );
        })
      )}
      <div ref={bottomRef} />
    </div>
  );
}
