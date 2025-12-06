'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import ChatWindow from '@/components/groups/ChatWindow';
import { ArrowLeft, Users } from 'lucide-react';
import { useRouter } from 'next/navigation';
import axios from 'axios';

export default function GroupDetailPage({ params }: { params: { groupId: string } }) {
  const router = useRouter();
  const [group, setGroup] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchGroup();
  }, [params.groupId]);

  const fetchGroup = async () => {
    try {
      const response = await axios.get(`/api/groups/${params.groupId}`);
      setGroup(response.data.data);
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
    return <div>Group not found</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={() => router.back()}>
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <div>
          <h1 className="text-3xl font-bold">{group.name}</h1>
          <p className="text-muted-foreground mt-1">
            {group.classSection} - Year {group.academicYear}
          </p>
        </div>
      </div>

      {/* Group Members */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            Group Members ({group.members?.length || 0})
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid gap-2">
            {group.members?.map((member: any) => (
              <div key={member.id} className="flex items-center justify-between p-2 bg-muted/50 rounded">
                <div>
                  <p className="font-medium">
                    {member.user.studentProfile?.fullName || member.user.registerNumber}
                  </p>
                  <p className="text-sm text-muted-foreground">{member.user.email}</p>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Chat Window */}
      <ChatWindow groupId={params.groupId} />
    </div>
  );
}
