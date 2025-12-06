export interface ServerToClientEvents {
  'chat:message': (message: ChatMessage) => void;
  'chat:user-typing': (data: { userId: string; isTyping: boolean }) => void;
  'chat:message-blocked': (data: { message: string }) => void;
  'notification:new': (notification: Notification) => void;
}

export interface ClientToServerEvents {
  'chat:join-group': (data: { groupId: string }) => void;
  'chat:leave-group': (data: { groupId: string }) => void;
  'chat:message': (data: { groupId: string; content: string }) => void;
  'chat:typing': (data: { groupId: string; isTyping: boolean }) => void;
}

export interface ChatMessage {
  id: string;
  content: string;
  userId: string;
  groupId: string;
  createdAt: Date;
  user: {
    registerNumber: string;
    studentProfile?: {
      fullName: string;
    } | null;
  };
}
