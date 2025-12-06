'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select } from '@/components/ui/select';
import axios from 'axios';
import { useToast } from '@/lib/hooks/useToast';

export default function EditProfilePage() {
  const router = useRouter();
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    fullName: '',
    dateOfBirth: '',
    gender: 'MALE',
    contactNumber: '',
    whatsappNumber: '',
    personalEmail: '',
    ugDegree: '',
    ugCollege: '',
    ugPercentage: '',
    schoolName: '',
    tenthPercentage: '',
    twelfthPercentage: '',
    technicalSkills: [] as string[],
    certifications: [] as string[],
    areasOfInterest: [] as string[],
    githubUrl: '',
    leetcodeUrl: '',
    linkedinUrl: '',
    portfolioUrl: '',
  });

  const [skillInput, setSkillInput] = useState('');
  const [interestInput, setInterestInput] = useState('');

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const response = await axios.get('/api/auth/session');
      const profile = response.data.data.studentProfile;
      if (profile) {
        setFormData({
          fullName: profile.fullName || '',
          dateOfBirth: profile.dateOfBirth ? new Date(profile.dateOfBirth).toISOString().split('T')[0] : '',
          gender: profile.gender || 'MALE',
          contactNumber: profile.contactNumber || '',
          whatsappNumber: profile.whatsappNumber || '',
          personalEmail: profile.personalEmail || '',
          ugDegree: profile.ugDegree || '',
          ugCollege: profile.ugCollege || '',
          ugPercentage: profile.ugPercentage?.toString() || '',
          schoolName: profile.schoolName || '',
          tenthPercentage: profile.tenthPercentage?.toString() || '',
          twelfthPercentage: profile.twelfthPercentage?.toString() || '',
          technicalSkills: profile.technicalSkills || [],
          certifications: profile.certifications || [],
          areasOfInterest: profile.areasOfInterest || [],
          githubUrl: profile.githubUrl || '',
          leetcodeUrl: profile.leetcodeUrl || '',
          linkedinUrl: profile.linkedinUrl || '',
          portfolioUrl: profile.portfolioUrl || '',
        });
      }
    } catch (error) {
      console.error('Failed to fetch profile:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      await axios.put('/api/students/profile', {
        ...formData,
        ugPercentage: parseFloat(formData.ugPercentage),
        tenthPercentage: parseFloat(formData.tenthPercentage),
        twelfthPercentage: formData.twelfthPercentage ? parseFloat(formData.twelfthPercentage) : null,
      });

      toast({
        title: 'Success',
        description: 'Profile updated successfully',
      });

      router.push('/profile');
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.response?.data?.error || 'Failed to update profile',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const addSkill = () => {
    if (skillInput.trim() && !formData.technicalSkills.includes(skillInput.trim())) {
      setFormData({
        ...formData,
        technicalSkills: [...formData.technicalSkills, skillInput.trim()],
      });
      setSkillInput('');
    }
  };

  const removeSkill = (skill: string) => {
    setFormData({
      ...formData,
      technicalSkills: formData.technicalSkills.filter(s => s !== skill),
    });
  };

  const addInterest = () => {
    if (interestInput.trim() && !formData.areasOfInterest.includes(interestInput.trim())) {
      setFormData({
        ...formData,
        areasOfInterest: [...formData.areasOfInterest, interestInput.trim()],
      });
      setInterestInput('');
    }
  };

  const removeInterest = (interest: string) => {
    setFormData({
      ...formData,
      areasOfInterest: formData.areasOfInterest.filter(i => i !== interest),
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Edit Profile</h1>
        <div className="space-x-2">
          <Button type="button" variant="outline" onClick={() => router.back()}>
            Cancel
          </Button>
          <Button type="submit" disabled={loading}>
            {loading ? 'Saving...' : 'Save Changes'}
          </Button>
        </div>
      </div>

      {/* Personal Information */}
      <Card>
        <CardHeader>
          <CardTitle>Personal Information</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="fullName">Full Name *</Label>
              <Input
                id="fullName"
                value={formData.fullName}
                onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="dateOfBirth">Date of Birth *</Label>
              <Input
                id="dateOfBirth"
                type="date"
                value={formData.dateOfBirth}
                onChange={(e) => setFormData({ ...formData, dateOfBirth: e.target.value })}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="gender">Gender *</Label>
              <select
                id="gender"
                value={formData.gender}
                onChange={(e) => setFormData({ ...formData, gender: e.target.value })}
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                required
              >
                <option value="MALE">Male</option>
                <option value="FEMALE">Female</option>
                <option value="OTHER">Other</option>
              </select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="contactNumber">Contact Number *</Label>
              <Input
                id="contactNumber"
                value={formData.contactNumber}
                onChange={(e) => setFormData({ ...formData, contactNumber: e.target.value })}
                placeholder="10-digit number"
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="whatsappNumber">WhatsApp Number</Label>
              <Input
                id="whatsappNumber"
                value={formData.whatsappNumber}
                onChange={(e) => setFormData({ ...formData, whatsappNumber: e.target.value })}
                placeholder="10-digit number"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="personalEmail">Personal Email *</Label>
              <Input
                id="personalEmail"
                type="email"
                value={formData.personalEmail}
                onChange={(e) => setFormData({ ...formData, personalEmail: e.target.value })}
                required
              />
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
            <div className="space-y-2">
              <Label htmlFor="ugDegree">UG Degree *</Label>
              <Input
                id="ugDegree"
                value={formData.ugDegree}
                onChange={(e) => setFormData({ ...formData, ugDegree: e.target.value })}
                placeholder="e.g., B.Tech CSE"
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="ugCollege">UG College *</Label>
              <Input
                id="ugCollege"
                value={formData.ugCollege}
                onChange={(e) => setFormData({ ...formData, ugCollege: e.target.value })}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="ugPercentage">UG Percentage/CGPA *</Label>
              <Input
                id="ugPercentage"
                type="number"
                step="0.01"
                value={formData.ugPercentage}
                onChange={(e) => setFormData({ ...formData, ugPercentage: e.target.value })}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="schoolName">School Name *</Label>
              <Input
                id="schoolName"
                value={formData.schoolName}
                onChange={(e) => setFormData({ ...formData, schoolName: e.target.value })}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="tenthPercentage">10th Percentage *</Label>
              <Input
                id="tenthPercentage"
                type="number"
                step="0.01"
                value={formData.tenthPercentage}
                onChange={(e) => setFormData({ ...formData, tenthPercentage: e.target.value })}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="twelfthPercentage">12th/Diploma Percentage</Label>
              <Input
                id="twelfthPercentage"
                type="number"
                step="0.01"
                value={formData.twelfthPercentage}
                onChange={(e) => setFormData({ ...formData, twelfthPercentage: e.target.value })}
              />
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
          <div className="space-y-2">
            <Label>Technical Skills *</Label>
            <div className="flex gap-2">
              <Input
                value={skillInput}
                onChange={(e) => setSkillInput(e.target.value)}
                placeholder="Add a skill (e.g., React, Python)"
                onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addSkill())}
              />
              <Button type="button" onClick={addSkill}>Add</Button>
            </div>
            <div className="flex flex-wrap gap-2 mt-2">
              {formData.technicalSkills.map((skill) => (
                <span
                  key={skill}
                  className="bg-secondary px-3 py-1 rounded-full text-sm flex items-center gap-2"
                >
                  {skill}
                  <button
                    type="button"
                    onClick={() => removeSkill(skill)}
                    className="text-destructive hover:text-destructive/80"
                  >
                    ×
                  </button>
                </span>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <Label>Areas of Interest *</Label>
            <div className="flex gap-2">
              <Input
                value={interestInput}
                onChange={(e) => setInterestInput(e.target.value)}
                placeholder="Add an interest (e.g., Web Development)"
                onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addInterest())}
              />
              <Button type="button" onClick={addInterest}>Add</Button>
            </div>
            <div className="flex flex-wrap gap-2 mt-2">
              {formData.areasOfInterest.map((interest) => (
                <span
                  key={interest}
                  className="bg-primary text-primary-foreground px-3 py-1 rounded-full text-sm flex items-center gap-2"
                >
                  {interest}
                  <button
                    type="button"
                    onClick={() => removeInterest(interest)}
                    className="hover:opacity-80"
                  >
                    ×
                  </button>
                </span>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Professional Links */}
      <Card>
        <CardHeader>
          <CardTitle>Professional Links</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="githubUrl">GitHub Profile</Label>
              <Input
                id="githubUrl"
                type="url"
                value={formData.githubUrl}
                onChange={(e) => setFormData({ ...formData, githubUrl: e.target.value })}
                placeholder="https://github.com/username"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="leetcodeUrl">LeetCode Profile</Label>
              <Input
                id="leetcodeUrl"
                type="url"
                value={formData.leetcodeUrl}
                onChange={(e) => setFormData({ ...formData, leetcodeUrl: e.target.value })}
                placeholder="https://leetcode.com/username"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="linkedinUrl">LinkedIn Profile</Label>
              <Input
                id="linkedinUrl"
                type="url"
                value={formData.linkedinUrl}
                onChange={(e) => setFormData({ ...formData, linkedinUrl: e.target.value })}
                placeholder="https://linkedin.com/in/username"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="portfolioUrl">Portfolio Website</Label>
              <Input
                id="portfolioUrl"
                type="url"
                value={formData.portfolioUrl}
                onChange={(e) => setFormData({ ...formData, portfolioUrl: e.target.value })}
                placeholder="https://yourportfolio.com"
              />
            </div>
          </div>
        </CardContent>
      </Card>
    </form>
  );
}
