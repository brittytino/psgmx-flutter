'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { AlertCircle, Trash2, UserPlus } from 'lucide-react';
import axios from 'axios';

export default function BatchManagementPage() {
  const [graduatingBatch, setGraduatingBatch] = useState({
    startYear: '',
    endYear: '',
  });
  const [newAdmin, setNewAdmin] = useState({
    registerNumber: '',
    email: '',
    password: '',
    batchStartYear: '',
    batchEndYear: '',
    classSection: 'G1',
    academicYear: '1',
  });

  const handleGraduate = async () => {
    if (!confirm(`Are you sure you want to graduate batch ${graduatingBatch.startYear}-${graduatingBatch.endYear}? This will delete all student data permanently.`)) {
      return;
    }

    try {
      await axios.post('/api/admin/batch/graduate', {
        batchStartYear: parseInt(graduatingBatch.startYear),
        batchEndYear: parseInt(graduatingBatch.endYear),
      });

      alert('Batch graduated successfully!');
      setGraduatingBatch({ startYear: '', endYear: '' });
    } catch (error) {
      alert('Failed to graduate batch');
    }
  };

  const handleHandover = async () => {
    if (!confirm('Are you sure you want to create a new super admin and handover?')) {
      return;
    }

    try {
      await axios.post('/api/admin/batch/handover', {
        newAdminData: {
          registerNumber: newAdmin.registerNumber,
          email: newAdmin.email,
          password: newAdmin.password,
          batchStartYear: parseInt(newAdmin.batchStartYear),
          batchEndYear: parseInt(newAdmin.batchEndYear),
          classSection: newAdmin.classSection,
          academicYear: parseInt(newAdmin.academicYear),
        },
      });

      alert('Handover completed successfully!');
      setNewAdmin({
        registerNumber: '',
        email: '',
        password: '',
        batchStartYear: '',
        batchEndYear: '',
        classSection: 'G1',
        academicYear: '1',
      });
    } catch (error) {
      alert('Failed to complete handover');
    }
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h1 className="text-3xl font-bold">Batch Management</h1>
        <p className="text-muted-foreground mt-1">
          Manage batch graduation and admin handover
        </p>
      </div>

      {/* Graduate Batch */}
      <Card className="border-red-200">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-red-700">
            <Trash2 className="h-5 w-5" />
            Graduate Batch
          </CardTitle>
          <CardDescription>
            Remove all data for students who have completed their program
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Card className="border-red-200 bg-red-50/50">
            <CardContent className="p-4">
              <div className="flex gap-3">
                <AlertCircle className="h-5 w-5 text-red-600 flex-shrink-0 mt-0.5" />
                <div className="text-sm text-red-800">
                  <p className="font-medium">Warning: This action cannot be undone!</p>
                  <p className="mt-1">All student data including profiles, projects, documents, and messages will be permanently deleted.</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="gradStartYear">Batch Start Year</Label>
              <Input
                id="gradStartYear"
                type="number"
                value={graduatingBatch.startYear}
                onChange={(e) => setGraduatingBatch({ ...graduatingBatch, startYear: e.target.value })}
                placeholder="e.g., 2023"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="gradEndYear">Batch End Year</Label>
              <Input
                id="gradEndYear"
                type="number"
                value={graduatingBatch.endYear}
                onChange={(e) => setGraduatingBatch({ ...graduatingBatch, endYear: e.target.value })}
                placeholder="e.g., 2025"
              />
            </div>
          </div>

          <Button
            variant="destructive"
            onClick={handleGraduate}
            disabled={!graduatingBatch.startYear || !graduatingBatch.endYear}
          >
            <Trash2 className="h-4 w-4 mr-2" />
            Graduate Batch
          </Button>
        </CardContent>
      </Card>

      {/* Admin Handover */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <UserPlus className="h-5 w-5" />
            Admin Handover
          </CardTitle>
          <CardDescription>
            Create a new super admin for the next batch
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="adminRegNo">Register Number</Label>
              <Input
                id="adminRegNo"
                value={newAdmin.registerNumber}
                onChange={(e) => setNewAdmin({ ...newAdmin, registerNumber: e.target.value })}
                placeholder="e.g., 2025MCA001"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="adminEmail">Email</Label>
              <Input
                id="adminEmail"
                type="email"
                value={newAdmin.email}
                onChange={(e) => setNewAdmin({ ...newAdmin, email: e.target.value })}
                placeholder="admin@psgtech.ac.in"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="adminPassword">Password</Label>
              <Input
                id="adminPassword"
                type="password"
                value={newAdmin.password}
                onChange={(e) => setNewAdmin({ ...newAdmin, password: e.target.value })}
                placeholder="Secure password"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="adminClass">Class Section</Label>
              <select
                id="adminClass"
                value={newAdmin.classSection}
                onChange={(e) => setNewAdmin({ ...newAdmin, classSection: e.target.value })}
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              >
                <option value="G1">G1</option>
                <option value="G2">G2</option>
              </select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="adminBatchStart">Batch Start Year</Label>
              <Input
                id="adminBatchStart"
                type="number"
                value={newAdmin.batchStartYear}
                onChange={(e) => setNewAdmin({ ...newAdmin, batchStartYear: e.target.value })}
                placeholder="e.g., 2025"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="adminBatchEnd">Batch End Year</Label>
              <Input
                id="adminBatchEnd"
                type="number"
                value={newAdmin.batchEndYear}
                onChange={(e) => setNewAdmin({ ...newAdmin, batchEndYear: e.target.value })}
                placeholder="e.g., 2027"
              />
            </div>
          </div>

          <Button
            onClick={handleHandover}
            disabled={!newAdmin.registerNumber || !newAdmin.email || !newAdmin.password}
          >
            <UserPlus className="h-4 w-4 mr-2" />
            Create Super Admin
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
