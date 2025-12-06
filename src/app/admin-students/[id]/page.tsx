'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ArrowLeft, Edit, Mail, Phone, Calendar, Code2 } from 'lucide-react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import axios from 'axios';
import { formatDate } from '@/lib/utils/format';

export default function StudentDetailPage({ params }: { params: { id: string } }) {
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
        <Link href={`/admin-students/${student.id}/edit`}>
          <Button>
            <Edit className="h-4 w-4 mr-2" />
            Edit Profile
          </Button>
        </Link>
      </div>

      {/* Basic Info */}
      <Card>
        <CardHeader>
          <CardTitle>Basic Information</CardTitle>
        </CardHeader>
        <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="flex items-center gap-3">
            <Mail className="h-5 w-5 text-muted-foreground" />
            <div>
              <p className="text-sm text-muted-foreground">Email</p>
              <p className="font-medium">{student.email}</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <Phone className="h-5 w-5 text-muted-foreground" />
            <div>
              <p className="text-sm text-muted-foreground">Contact</p>
              <p className="font-medium">{profile?.contactNumber || '-'}</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <Calendar className="h-5 w-5 text-muted-foreground" />
            <div>
              <p className="text-sm text-muted-foreground">Date of Birth</p>
              <p className="font-medium">
                {profile?.dateOfBirth ? formatDate(profile.dateOfBirth) : '-'}
              </p>
            </div>
          </div>

          <div>
            <p className="text-sm text-muted-foreground">Class & Year</p>
            <p className="font-medium">
              {student.classSection} - Year {student.academicYear}
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Academic Info */}
      {profile && (
        <Card>
          <CardHeader>
            <CardTitle>Academic Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div>
              <p className="text-sm text-muted-foreground">UG Details</p>
              <p className="font-medium">
                {profile.ugDegree} from {profile.ugCollege}
              </p>
              <p className="text-sm">CGPA: {profile.ugPercentage}</p>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">10th Percentage</p>
                <p className="font-medium">{profile.tenthPercentage}%</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">12th Percentage</p>
                <p className="font-medium">{profile.twelfthPercentage || '-'}%</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Skills */}
      {profile?.technicalSkills && profile.technicalSkills.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Technical Skills</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2">
              {profile.technicalSkills.map((skill: string) => (
                <Badge key={skill} variant="secondary">
                  {skill}
                </Badge>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* LeetCode Stats */}
      {student.leetcodeProfile && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Code2 className="h-5 w-5" />
              LeetCode Statistics
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Total Solved</p>
                <p className="text-2xl font-bold text-primary">
                  {student.leetcodeProfile.totalSolved}
                </p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Easy</p>
                <p className="text-2xl font-bold text-green-600">
                  {student.leetcodeProfile.easySolved}
                </p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Medium</p>
                <p className="text-2xl font-bold text-yellow-600">
                  {student.leetcodeProfile.mediumSolved}
                </p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Hard</p>
                <p className="text-2xl font-bold text-red-600">
                  {student.leetcodeProfile.hardSolved}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
