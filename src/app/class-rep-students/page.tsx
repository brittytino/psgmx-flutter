'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Eye, Send } from 'lucide-react';
import Link from 'next/link';
import axios from 'axios';
import { useAuth } from '@/lib/hooks/useAuth';

export default function ClassRepStudentsPage() {
  const { user } = useAuth();
  const [students, setStudents] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStudents();
  }, []);

  const fetchStudents = async () => {
    try {
      const response = await axios.get('/api/students');
      const classStudents = response.data.data.filter(
        (s: any) => s.classSection === user?.classSection
      );
      setStudents(classStudents);
    } catch (error) {
      console.error('Failed to fetch students:', error);
    } finally {
      setLoading(false);
    }
  };

  const sendNotification = async (studentId: string, studentName: string) => {
    const message = prompt(`Send notification to ${studentName}:`);
    if (!message) return;

    try {
      await axios.post('/api/notifications', {
        userId: studentId,
        title: 'Message from Class Representative',
        message,
        type: 'info',
      });
      alert('Notification sent successfully!');
    } catch (error) {
      alert('Failed to send notification');
    }
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Class Students</h1>
        <p className="text-muted-foreground mt-1">
          View and manage students in your class
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Students List ({students.length})</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-3 px-4">Register No</th>
                  <th className="text-left py-3 px-4">Name</th>
                  <th className="text-left py-3 px-4">Email</th>
                  <th className="text-left py-3 px-4">Profile Status</th>
                  <th className="text-left py-3 px-4">Actions</th>
                </tr>
              </thead>
              <tbody>
                {students.map((student) => (
                  <tr key={student.id} className="border-b hover:bg-muted/50">
                    <td className="py-3 px-4 font-medium">{student.registerNumber}</td>
                    <td className="py-3 px-4">{student.profile?.fullName || '-'}</td>
                    <td className="py-3 px-4 text-sm text-muted-foreground">
                      {student.email}
                    </td>
                    <td className="py-3 px-4">
                      {student.profile?.isProfileComplete ? (
                        <Badge className="bg-green-100 text-green-700">Complete</Badge>
                      ) : (
                        <Badge variant="secondary">Incomplete</Badge>
                      )}
                    </td>
                    <td className="py-3 px-4">
                      <div className="flex gap-2">
                        <Link href={`/class-rep/students/${student.id}`}>
                          <Button variant="ghost" size="sm">
                            <Eye className="h-4 w-4" />
                          </Button>
                        </Link>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => sendNotification(student.id, student.profile?.fullName || student.registerNumber)}
                        >
                          <Send className="h-4 w-4" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
