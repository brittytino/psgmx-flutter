'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Bell, Send, CheckCircle } from 'lucide-react';
import { useAuth } from '@/lib/hooks/useAuth';
import axios from 'axios';

export default function NotificationsPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    message: '',
    sendToAll: true,
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setSuccess(false);

    try {
      await axios.post('/api/notifications/broadcast', {
        title: formData.title,
        message: formData.message,
        classSection: user?.classSection,
        type: 'info',
      });

      setSuccess(true);
      setFormData({ title: '', message: '', sendToAll: true });
      
      setTimeout(() => setSuccess(false), 3000);
    } catch (error) {
      alert('Failed to send notification');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h1 className="text-3xl font-bold">Send Notifications</h1>
        <p className="text-muted-foreground mt-1">
          Broadcast messages to your class students
        </p>
      </div>

      {success && (
        <Alert className="bg-green-50 border-green-200">
          <CheckCircle className="h-5 w-5 text-green-600" />
          <AlertDescription className="text-green-800">
            Notification sent successfully to all students in {user?.classSection}!
          </AlertDescription>
        </Alert>
      )}

      <form onSubmit={handleSubmit}>
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Bell className="h-5 w-5" />
              Notification Details
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="title">Title *</Label>
              <Input
                id="title"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                placeholder="e.g., Important: Assignment Deadline"
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="message">Message *</Label>
              <Textarea
                id="message"
                value={formData.message}
                onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                placeholder="Enter your message here..."
                rows={8}
                required
              />
            </div>

            <div className="bg-muted p-4 rounded-lg">
              <p className="text-sm font-medium mb-1">Recipients:</p>
              <p className="text-sm text-muted-foreground">
                All students in class {user?.classSection}
              </p>
            </div>
          </CardContent>
        </Card>

        <Button type="submit" disabled={loading} className="w-full mt-4">
          <Send className="h-4 w-4 mr-2" />
          {loading ? 'Sending...' : 'Send Notification'}
        </Button>
      </form>

      <Alert>
        <AlertDescription>
          <p className="font-medium mb-2">Tips:</p>
          <ul className="list-disc ml-5 space-y-1 text-sm">
            <li>Keep messages clear and concise</li>
            <li>Use descriptive titles to grab attention</li>
            <li>Notifications will be sent via in-app and email</li>
            <li>Students can view all notifications in their dashboard</li>
          </ul>
        </AlertDescription>
      </Alert>
    </div>
  );
}
