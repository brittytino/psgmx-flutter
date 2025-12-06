'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Plus, Edit, Trash2, Users } from 'lucide-react';
import Link from 'next/link';
import axios from 'axios';

export default function ClassRepsPage() {
  const [classReps, setClassReps] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchClassReps();
  }, []);

  const fetchClassReps = async () => {
    try {
      const response = await axios.get('/api/admin/users?role=CLASS_REP');
      setClassReps(response.data.data);
    } catch (error) {
      console.error('Failed to fetch class reps:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Remove class representative privileges?')) return;

    try {
      await axios.delete(`/api/admin/users/${id}`);
      setClassReps(classReps.filter(cr => cr.id !== id));
    } catch (error) {
      alert('Failed to remove class rep');
    }
  };

  if (loading) return <div>Loading...</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Class Representatives</h1>
          <p className="text-muted-foreground mt-1">
            Manage class representative assignments
          </p>
        </div>
        <Link href="/admin/class-reps/manage">
          <Button>
            <Plus className="h-4 w-4 mr-2" />
            Assign Class Rep
          </Button>
        </Link>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Class Representatives ({classReps.length})</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-3 px-4">Register No</th>
                  <th className="text-left py-3 px-4">Email</th>
                  <th className="text-left py-3 px-4">Class</th>
                  <th className="text-left py-3 px-4">Year</th>
                  <th className="text-left py-3 px-4">Actions</th>
                </tr>
              </thead>
              <tbody>
                {classReps.map((rep) => (
                  <tr key={rep.id} className="border-b hover:bg-muted/50">
                    <td className="py-3 px-4 font-medium">{rep.registerNumber}</td>
                    <td className="py-3 px-4">{rep.email}</td>
                    <td className="py-3 px-4">
                      <Badge variant="outline">{rep.classSection}</Badge>
                    </td>
                    <td className="py-3 px-4">Year {rep.academicYear}</td>
                    <td className="py-3 px-4">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDelete(rep.id)}
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
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
