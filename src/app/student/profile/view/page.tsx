'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Edit, Mail, Phone, Calendar, MapPin, Award } from 'lucide-react';
import Link from 'next/link';
import axios from 'axios';
import { formatDate } from '@/lib/utils/format';

export default function ViewProfilePage() {
  const [profile, setProfile] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const response = await axios.get('/api/auth/session');
      setProfile(response.data.data.studentProfile);
    } catch (error) {
      console.error('Failed to fetch profile:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div>Loading...</div>;
  if (!profile) return <div>No profile found</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">{profile.fullName}</h1>
          <p className="text-muted-foreground mt-1">Student Profile</p>
        </div>
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
        <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="flex items-center gap-3">
            <Calendar className="h-5 w-5 text-muted-foreground" />
            <div>
              <p className="text-sm text-muted-foreground">Date of Birth</p>
              <p className="font-medium">{formatDate(profile.dateOfBirth)}</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <MapPin className="h-5 w-5 text-muted-foreground" />
            <div>
              <p className="text-sm text-muted-foreground">Gender</p>
              <p className="font-medium">{profile.gender}</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <Phone className="h-5 w-5 text-muted-foreground" />
            <div>
              <p className="text-sm text-muted-foreground">Contact</p>
              <p className="font-medium">{profile.contactNumber}</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <Mail className="h-5 w-5 text-muted-foreground" />
            <div>
              <p className="text-sm text-muted-foreground">Email</p>
              <p className="font-medium">{profile.personalEmail}</p>
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
          <div>
            <p className="text-sm text-muted-foreground">Undergraduate Degree</p>
            <p className="font-medium">{profile.ugDegree}</p>
            <p className="text-sm">{profile.ugCollege}</p>
            <p className="text-sm text-muted-foreground mt-1">
              CGPA: {profile.ugPercentage}
            </p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-muted-foreground">10th Percentage</p>
              <p className="font-medium">{profile.tenthPercentage}%</p>
              <p className="text-sm">{profile.schoolName}</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">12th/Diploma</p>
              <p className="font-medium">
                {profile.twelfthPercentage ? `${profile.twelfthPercentage}%` : 'N/A'}
              </p>
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
            <p className="text-sm text-muted-foreground mb-2">Technical Skills</p>
            <div className="flex flex-wrap gap-2">
              {profile.technicalSkills?.map((skill: string) => (
                <Badge key={skill} variant="secondary">
                  {skill}
                </Badge>
              ))}
            </div>
          </div>

          <div>
            <p className="text-sm text-muted-foreground mb-2">Areas of Interest</p>
            <div className="flex flex-wrap gap-2">
              {profile.areasOfInterest?.map((interest: string) => (
                <Badge key={interest} className="bg-primary text-primary-foreground">
                  {interest}
                </Badge>
              ))}
            </div>
          </div>

          {profile.certifications && profile.certifications.length > 0 && (
            <div>
              <p className="text-sm text-muted-foreground mb-2">Certifications</p>
              <div className="flex flex-wrap gap-2">
                {profile.certifications.map((cert: string) => (
                  <Badge key={cert} variant="outline">
                    <Award className="h-3 w-3 mr-1" />
                    {cert}
                  </Badge>
                ))}
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Professional Links */}
      <Card>
        <CardHeader>
          <CardTitle>Professional Links</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {profile.githubUrl && (
            <div>
              <p className="text-sm text-muted-foreground">GitHub</p>
              <a
                href={profile.githubUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary hover:underline"
              >
                {profile.githubUrl}
              </a>
            </div>
          )}
          {profile.linkedinUrl && (
            <div>
              <p className="text-sm text-muted-foreground">LinkedIn</p>
              <a
                href={profile.linkedinUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary hover:underline"
              >
                {profile.linkedinUrl}
              </a>
            </div>
          )}
          {profile.leetcodeUrl && (
            <div>
              <p className="text-sm text-muted-foreground">LeetCode</p>
              <a
                href={profile.leetcodeUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary hover:underline"
              >
                {profile.leetcodeUrl}
              </a>
            </div>
          )}
          {profile.portfolioUrl && (
            <div>
              <p className="text-sm text-muted-foreground">Portfolio</p>
              <a
                href={profile.portfolioUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary hover:underline"
              >
                {profile.portfolioUrl}
              </a>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
