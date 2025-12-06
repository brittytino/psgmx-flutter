'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Plus, Edit, Trash2, Pin } from 'lucide-react';
import Link from 'next/link';
import axios from 'axios';
import { formatDateTime } from '@/lib/utils/format';

export default function AnnouncementsManagementPage() {
  const [announcements, setAnnouncements] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchAnnouncements();
  }, []);

  const fetchAnnouncements = async () => {
    try {
      const response = await axios.get('/api/announcements');
      setAnnouncements(response.data.data);
    } catch (error) {
      console.error('Failed to fetch announcements:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this announcement?')) return;

    try {
      await axios.delete(`/api/announcements/${id}`);
      setAnnouncements(announcements.filter(a => a.id !== id));
    } catch (error) {
      console.error('Failed to delete announcement:', error);
    }
  };

  const togglePin = async (id: string, currentPinned: boolean) => {
    try {
      await axios.put(`/api/announcements/${id}`, {
        isPinned: !currentPinned,
      });
      fetchAnnouncements();
    } catch (error) {
      console.error('Failed to toggle pin:', error);
    }
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Announcements</h1>
          <p className="text-muted-foreground mt-1">
            Create and manage announcements for students
          </p>
        </div>
        <Link href="/super-admin/announcements/create">
          <Button>
            <Plus className="h-4 w-4 mr-2" />
            Create Announcement
          </Button>
        </Link>
      </div>

      <div className="space-y-4">
        {announcements.map((announcement) => (
          <Card key={announcement.id} className={announcement.isPinned ? 'border-primary' : ''}>
            <CardHeader>
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <CardTitle className="flex items-center gap-2">
                    {announcement.title}
                    {announcement.isPinned && <Pin className="h-4 w-4 text-primary" />}
                  </CardTitle>
                  <div className="flex items-center gap-2 mt-2">
                    <span className="text-sm text-muted-foreground">
                      {formatDateTime(announcement.createdAt)}
                    </span>
                    {announcement.classSection && (
                      <Badge variant="outline">{announcement.classSection}</Badge>
                    )}
                    {announcement.academicYear && (
                      <Badge variant="outline">Year {announcement.academicYear}</Badge>
                    )}
                  </div>
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => togglePin(announcement.id, announcement.isPinned)}
                  >
                    <Pin className={`h-4 w-4 ${announcement.isPinned ? 'fill-current' : ''}`} />
                  </Button>
                  <Button variant="ghost" size="icon">
                    <Edit className="h-4 w-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => handleDelete(announcement.id)}
                  >
                    <Trash2 className="h-4 w-4 text-destructive" />
                  </Button>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-sm whitespace-pre-wrap">{announcement.content}</p>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
