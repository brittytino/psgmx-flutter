'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Edit, Mail, Phone, Calendar, Github, Linkedin, Globe, Code2 } from 'lucide-react';
import Link from 'next/link';
import axios from 'axios';
import { formatDate } from '@/lib/utils/format';

export default function ProfilePage() {
  const [profile, setProfile] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const response = await axios.get('/api/students/profile');
      setProfile(response.data.data);
    } catch (error) {
      console.error('Failed to fetch profile:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">My Profile</h1>
        <Link href="/profile/edit">
          <Button>
            <Edit className="h-4 w-4 mr-2" />
            Edit Profile
          </Button>
        </Link>
      </div>

      {/* Personal Information */}
      <Card>
        <CardHeader>
          <CardTitle>Personal Information</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="text-sm text-muted-foreground">Full Name</label>
              <p className="font-medium">{profile?.fullName || 'Not set'}</p>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Date of Birth</label>
              <p className="font-medium">
                {profile?.dateOfBirth ? formatDate(profile.dateOfBirth) : 'Not set'}
              </p>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Gender</label>
              <p className="font-medium">{profile?.gender || 'Not set'}</p>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Contact Number</label>
              <p className="font-medium flex items-center gap-2">
                <Phone className="h-4 w-4" />
                {profile?.contactNumber || 'Not set'}
              </p>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Email</label>
              <p className="font-medium flex items-center gap-2">
                <Mail className="h-4 w-4" />
                {profile?.personalEmail || 'Not set'}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Academic Information */}
      <Card>
        <CardHeader>
          <CardTitle>Academic Information</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="text-sm text-muted-foreground">UG Degree</label>
              <p className="font-medium">{profile?.ugDegree || 'Not set'}</p>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">UG College</label>
              <p className="font-medium">{profile?.ugCollege || 'Not set'}</p>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">UG Percentage</label>
              <p className="font-medium">{profile?.ugPercentage || 'Not set'}%</p>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">10th Percentage</label>
              <p className="font-medium">{profile?.tenthPercentage || 'Not set'}%</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Skills & Interests */}
      <Card>
        <CardHeader>
          <CardTitle>Skills & Interests</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="text-sm text-muted-foreground mb-2 block">Technical Skills</label>
            <div className="flex flex-wrap gap-2">
              {profile?.technicalSkills?.map((skill: string) => (
                <Badge key={skill} variant="secondary">{skill}</Badge>
              )) || <p className="text-sm text-muted-foreground">No skills added</p>}
            </div>
          </div>
          <div>
            <label className="text-sm text-muted-foreground mb-2 block">Areas of Interest</label>
            <div className="flex flex-wrap gap-2">
              {profile?.areasOfInterest?.map((interest: string) => (
                <Badge key={interest}>{interest}</Badge>
              )) || <p className="text-sm text-muted-foreground">No interests added</p>}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Links */}
      <Card>
        <CardHeader>
          <CardTitle>Professional Links</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {profile?.githubUrl && (
            <a href={profile.githubUrl} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 text-sm hover:underline">
              <Github className="h-4 w-4" />
              GitHub Profile
            </a>
          )}
          {profile?.linkedinUrl && (
            <a href={profile.linkedinUrl} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 text-sm hover:underline">
              <Linkedin className="h-4 w-4" />
              LinkedIn Profile
            </a>
          )}
          {profile?.leetcodeUrl && (
            <a href={profile.leetcodeUrl} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 text-sm hover:underline">
              <Code2 className="h-4 w-4" />
              LeetCode Profile
            </a>
          )}
          {profile?.portfolioUrl && (
            <a href={profile.portfolioUrl} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 text-sm hover:underline">
              <Globe className="h-4 w-4" />
              Portfolio Website
            </a>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
