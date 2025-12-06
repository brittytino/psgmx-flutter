'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import axios from 'axios';

export default function EditStudentPage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    registerNumber: '',
    email: '',
    classSection: 'G1',
    academicYear: 1,
    batchStartYear: new Date().getFullYear(),
    batchEndYear: new Date().getFullYear() + 2,
  });

  useEffect(() => {
    fetchStudent();
  }, [params.id]);

  const fetchStudent = async () => {
    try {
      const response = await axios.get(`/api/students/${params.id}`);
      const student = response.data.data;
      setFormData({
        registerNumber: student.registerNumber,
        email: student.email,
        classSection: student.classSection,
        academicYear: student.academicYear,
        batchStartYear: student.batchStartYear,
        batchEndYear: student.batchEndYear,
      });
    } catch (error) {
      console.error('Failed to fetch student:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      await axios.put(`/api/students/${params.id}`, formData);
      alert('Student updated successfully!');
      router.push(`/admin-students/${params.id}`);
    } catch (error: any) {
      alert(error.response?.data?.error || 'Failed to update student');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h1 className="text-3xl font-bold">Edit Student</h1>
        <p className="text-muted-foreground mt-1">
          Update student account information
        </p>
      </div>

      <form onSubmit={handleSubmit}>
        <Card>
          <CardHeader>
            <CardTitle>Student Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="registerNumber">Register Number *</Label>
                <Input
                  id="registerNumber"
                  value={formData.registerNumber}
                  onChange={(e) => setFormData({ ...formData, registerNumber: e.target.value })}
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="email">Email *</Label>
                <Input
                  id="email"
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="classSection">Class Section *</Label>
                <select
                  id="classSection"
                  value={formData.classSection}
                  onChange={(e) => setFormData({ ...formData, classSection: e.target.value })}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  required
                >
                  <option value="G1">G1</option>
                  <option value="G2">G2</option>
                </select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="academicYear">Academic Year *</Label>
                <Input
                  id="academicYear"
                  type="number"
                  value={formData.academicYear}
                  onChange={(e) => setFormData({ ...formData, academicYear: parseInt(e.target.value) })}
                  min="1"
                  max="2"
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="batchStartYear">Batch Start Year *</Label>
                <Input
                  id="batchStartYear"
                  type="number"
                  value={formData.batchStartYear}
                  onChange={(e) => setFormData({ ...formData, batchStartYear: parseInt(e.target.value) })}
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="batchEndYear">Batch End Year *</Label>
                <Input
                  id="batchEndYear"
                  type="number"
                  value={formData.batchEndYear}
                  onChange={(e) => setFormData({ ...formData, batchEndYear: parseInt(e.target.value) })}
                  required
                />
              </div>
            </div>
          </CardContent>
        </Card>

        <div className="flex gap-2 mt-6">
          <Button type="submit" disabled={loading}>
            {loading ? 'Updating...' : 'Update Student'}
          </Button>
          <Button type="button" variant="outline" onClick={() => router.back()}>
            Cancel
          </Button>
        </div>
      </form>
    </div>
  );
}
