'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import ChatWindow from '@/components/groups/ChatWindow';
import MotivationQuote from '@/components/groups/MotivationQuote';
import { useAuth } from '@/lib/hooks/useAuth';
import { useSocket } from '@/lib/hooks/useSocket';
import axios from 'axios';

export default function GroupsPage() {
  const { user } = useAuth();
  const [group, setGroup] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const { socket, connected } = useSocket(null); // Will implement token from session

  useEffect(() => {
    fetchGroup();
  }, []);

  const fetchGroup = async () => {
    try {
      const response = await axios.get('/api/groups');
      if (response.data.data.length > 0) {
        setGroup(response.data.data[0]);
      }
    } catch (error) {
      console.error('Failed to fetch group:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  if (!group) {
    return (
      <div className="space-y-6">
        <h1 className="text-3xl font-bold">Groups</h1>
        <Card>
          <CardContent className="p-6">
            <p className="text-center text-muted-foreground">
              You haven't been assigned to a group yet.
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">{group.name}</h1>
        <p className="text-muted-foreground mt-1">
          Chat with your group members
        </p>
      </div>

      <MotivationQuote />

      <ChatWindow groupId={group.id} />
    </div>
  );
}
