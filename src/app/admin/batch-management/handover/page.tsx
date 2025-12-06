'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { UserPlus, Info } from 'lucide-react';
import axios from 'axios';

export default function HandoverAdminPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    registerNumber: '',
    email: '',
    password: '',
    confirmPassword: '',
    batchStartYear: new Date().getFullYear(),
    batchEndYear: new Date().getFullYear() + 2,
    classSection: 'G1',
    academicYear: 1,
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (formData.password !== formData.confirmPassword) {
      alert('Passwords do not match!');
      return;
    }

    if (!confirm('Are you sure you want to create a new super admin for handover?')) return;

    setLoading(true);

    try {
      await axios.post('/api/admin/batch/handover', {
        newAdminData: {
          registerNumber: formData.registerNumber,
          email: formData.email,
          password: formData.password,
          batchStartYear: formData.batchStartYear,
          batchEndYear: formData.batchEndYear,
          classSection: formData.classSection,
          academicYear: formData.academicYear,
        },
      });

      alert('New super admin created successfully! Handover complete.');
      router.push('/admin/batch-management');
    } catch (error: any) {
      alert(error.response?.data?.error || 'Failed to complete handover');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h1 className="text-3xl font-bold">Admin Handover</h1>
        <p className="text-muted-foreground mt-1">
          Create a new super administrator for the incoming batch
        </p>
      </div>

      <Alert className="bg-blue-50 border-blue-200">
        <Info className="h-5 w-5 text-blue-600" />
        <AlertDescription className="text-blue-800">
          <p className="font-semibold mb-1">Handover Process:</p>
          <ul className="list-disc ml-5 space-y-1 text-sm">
            <li>This creates a new super admin account for the next batch</li>
            <li>The new admin will have full access to manage their batch</li>
            <li>Your current admin access will remain active</li>
            <li>Ensure you provide credentials to the new administrator securely</li>
          </ul>
        </AlertDescription>
      </Alert>

      <form onSubmit={handleSubmit}>
        <Card>
          <CardHeader>
            <CardTitle>
              <UserPlus className="inline h-5 w-5 mr-2" />
              New Admin Details
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="registerNumber">Register Number *</Label>
                <Input
                  id="registerNumber"
                  value={formData.registerNumber}
                  onChange={(e) => setFormData({ ...formData, registerNumber: e.target.value })}
                  placeholder="e.g., 2026MCA001"
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
                  placeholder="newadmin@psgtech.ac.in"
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="password">Password *</Label>
                <Input
                  id="password"
                  type="password"
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="confirmPassword">Confirm Password *</Label>
                <Input
                  id="confirmPassword"
                  type="password"
                  value={formData.confirmPassword}
                  onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
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
            </div>
          </CardContent>
        </Card>

        <div className="flex gap-2 mt-6">
          <Button type="submit" disabled={loading}>
            <UserPlus className="h-4 w-4 mr-2" />
            {loading ? 'Creating Admin...' : 'Create Super Admin & Handover'}
          </Button>
          <Button type="button" variant="outline" onClick={() => router.back()}>
            Cancel
          </Button>
        </div>
      </form>
    </div>
  );
}
