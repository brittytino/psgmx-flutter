'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { SearchBar } from '@/components/shared/SearchBar';
import axios from 'axios';

export default function ManageClassRepsPage() {
  const router = useRouter();
  const [students, setStudents] = useState<any[]>([]);
  const [filteredStudents, setFilteredStudents] = useState<any[]>([]);
  const [selectedStudent, setSelectedStudent] = useState<string>('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchStudents();
  }, []);

  const fetchStudents = async () => {
    try {
      const response = await axios.get('/api/students');
      const studentUsers = response.data.data.filter((s: any) => s.role === 'STUDENT');
      setStudents(studentUsers);
      setFilteredStudents(studentUsers);
    } catch (error) {
      console.error('Failed to fetch students:', error);
    }
  };

  const handleSearch = (query: string) => {
    const filtered = students.filter(
      (s) =>
        s.registerNumber.toLowerCase().includes(query.toLowerCase()) ||
        s.email.toLowerCase().includes(query.toLowerCase()) ||
        s.studentProfile?.fullName?.toLowerCase().includes(query.toLowerCase())
    );
    setFilteredStudents(filtered);
  };

  const handleAssign = async () => {
    if (!selectedStudent) {
      alert('Please select a student');
      return;
    }

    if (!confirm('Assign this student as class representative?')) return;

    setLoading(true);

    try {
      await axios.put(`/api/admin/users/${selectedStudent}`, {
        role: 'CLASS_REP',
      });

      alert('Class representative assigned successfully!');
      router.push('/admin/class-reps');
    } catch (error: any) {
      alert(error.response?.data?.error || 'Failed to assign class rep');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h1 className="text-3xl font-bold">Assign Class Representative</h1>
        <p className="text-muted-foreground mt-1">
          Select a student to assign as class representative
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Search Students</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <SearchBar
            placeholder="Search by name, register number, or email..."
            onSearch={handleSearch}
          />

          <div className="border rounded-lg overflow-hidden max-h-96 overflow-y-auto">
            <table className="w-full">
              <thead className="bg-muted sticky top-0">
                <tr>
                  <th className="text-left py-3 px-4">Select</th>
                  <th className="text-left py-3 px-4">Register No</th>
                  <th className="text-left py-3 px-4">Name</th>
                  <th className="text-left py-3 px-4">Class</th>
                  <th className="text-left py-3 px-4">Email</th>
                </tr>
              </thead>
              <tbody>
                {filteredStudents.map((student) => (
                  <tr key={student.id} className="border-b hover:bg-muted/50">
                    <td className="py-3 px-4">
                      <input
                        type="radio"
                        name="selectedStudent"
                        value={student.id}
                        onChange={(e) => setSelectedStudent(e.target.value)}
                        className="h-4 w-4"
                      />
                    </td>
                    <td className="py-3 px-4 font-medium">{student.registerNumber}</td>
                    <td className="py-3 px-4">
                      {student.studentProfile?.fullName || '-'}
                    </td>
                    <td className="py-3 px-4">{student.classSection}</td>
                    <td className="py-3 px-4 text-sm text-muted-foreground">
                      {student.email}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      <div className="flex gap-2">
        <Button onClick={handleAssign} disabled={!selectedStudent || loading}>
          {loading ? 'Assigning...' : 'Assign as Class Rep'}
        </Button>
        <Button variant="outline" onClick={() => router.back()}>
          Cancel
        </Button>
      </div>
    </div>
  );
}
