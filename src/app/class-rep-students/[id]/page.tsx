'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ArrowLeft, Mail, Phone, Send } from 'lucide-react';
import { useRouter } from 'next/navigation';
import axios from 'axios';
import { formatDate } from '@/lib/utils/format';

export default function ClassRepStudentDetailPage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const [student, setStudent] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStudent();
  }, [params.id]);

  const fetchStudent = async () => {
    try {
      const response = await axios.get(`/api/students/${params.id}`);
      setStudent(response.data.data);
    } catch (error) {
      console.error('Failed to fetch student:', error);
    } finally {
      setLoading(false);
    }
  };

  const sendNotification = async () => {
    const message = prompt(`Send notification to ${student.studentProfile?.fullName}:`);
    if (!message) return;

    try {
      await axios.post('/api/notifications', {
        userId: student.id,
        title: 'Message from Class Representative',
        message,
        type: 'info',
      });
      alert('Notification sent successfully!');
    } catch (error) {
      alert('Failed to send notification');
    }
  };

  if (loading) return <div>Loading...</div>;
  if (!student) return <div>Student not found</div>;

  const profile = student.studentProfile;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={() => router.back()}>
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <div className="flex-1">
          <h1 className="text-3xl font-bold">
            {profile?.fullName || student.registerNumber}
          </h1>
          <p className="text-muted-foreground mt-1">{student.registerNumber}</p>
        </div>
        <Button onClick={sendNotification}>
          <Send className="h-4 w-4 mr-2" />
          Send Message
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Contact Information</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex items-center gap-3">
            <Mail className="h-5 w-5 text-muted-foreground" />
            <div>
              <p className="text-sm text-muted-foreground">College Email</p>
              <p className="font-medium">{student.email}</p>
            </div>
          </div>

          {profile?.personalEmail && (
            <div className="flex items-center gap-3">
              <Mail className="h-5 w-5 text-muted-foreground" />
              <div>
                <p className="text-sm text-muted-foreground">Personal Email</p>
                <p className="font-medium">{profile.personalEmail}</p>
              </div>
            </div>
          )}

          {profile?.contactNumber && (
            <div className="flex items-center gap-3">
              <Phone className="h-5 w-5 text-muted-foreground" />
              <div>
                <p className="text-sm text-muted-foreground">Contact Number</p>
                <p className="font-medium">{profile.contactNumber}</p>
              </div>
            </div>
          )}

          {profile?.whatsappNumber && (
            <div className="flex items-center gap-3">
              <Phone className="h-5 w-5 text-muted-foreground" />
              <div>
                <p className="text-sm text-muted-foreground">WhatsApp</p>
                <p className="font-medium">{profile.whatsappNumber}</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Profile Status</CardTitle>
        </CardHeader>
        <CardContent>
          {profile?.isProfileComplete ? (
            <Badge className="bg-green-100 text-green-700">
              Profile Completed
            </Badge>
          ) : (
            <Badge variant="secondary">Profile Incomplete</Badge>
          )}
        </CardContent>
      </Card>

      {profile?.technicalSkills && profile.technicalSkills.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Technical Skills</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2">
              {profile.technicalSkills.map((skill: string) => (
                <Badge key={skill} variant="outline">
                  {skill}
                </Badge>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
