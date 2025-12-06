'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertCircle, Trash2 } from 'lucide-react';
import axios from 'axios';

export default function GraduateBatchPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    batchStartYear: '',
    batchEndYear: '',
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const confirmMessage = `Are you absolutely sure you want to graduate batch ${formData.batchStartYear}-${formData.batchEndYear}?\n\nThis will PERMANENTLY DELETE:\n- All student records\n- All profiles and documents\n- All projects\n- All chat messages\n- All group data\n\nThis action CANNOT be undone!`;

    if (!confirm(confirmMessage)) return;

    setLoading(true);

    try {
      await axios.post('/api/admin/batch/graduate', {
        batchStartYear: parseInt(formData.batchStartYear),
        batchEndYear: parseInt(formData.batchEndYear),
      });

      alert('Batch graduated successfully!');
      router.push('/admin/batch-management');
    } catch (error: any) {
      alert(error.response?.data?.error || 'Failed to graduate batch');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h1 className="text-3xl font-bold text-red-700">Graduate Batch</h1>
        <p className="text-muted-foreground mt-1">
          Permanently remove all data for a graduating batch
        </p>
      </div>

      <Alert variant="destructive" className="border-red-300 bg-red-50">
        <AlertCircle className="h-5 w-5" />
        <AlertDescription>
          <p className="font-semibold mb-2">⚠️ DANGER ZONE - IRREVERSIBLE ACTION</p>
          <ul className="list-disc ml-5 space-y-1 text-sm">
            <li>This will delete ALL student data for the specified batch</li>
            <li>All profiles, documents, projects, and messages will be lost</li>
            <li>This action CANNOT be reversed or undone</li>
            <li>Make sure you have exported all necessary data before proceeding</li>
          </ul>
        </AlertDescription>
      </Alert>

      <form onSubmit={handleSubmit}>
        <Card className="border-red-200">
          <CardHeader>
            <CardTitle className="text-red-700">
              <Trash2 className="inline h-5 w-5 mr-2" />
              Batch Graduation Details
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="batchStartYear">Batch Start Year *</Label>
                <Input
                  id="batchStartYear"
                  type="number"
                  value={formData.batchStartYear}
                  onChange={(e) => setFormData({ ...formData, batchStartYear: e.target.value })}
                  placeholder="e.g., 2023"
                  required
                  min="2000"
                  max="2100"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="batchEndYear">Batch End Year *</Label>
                <Input
                  id="batchEndYear"
                  type="number"
                  value={formData.batchEndYear}
                  onChange={(e) => setFormData({ ...formData, batchEndYear: e.target.value })}
                  placeholder="e.g., 2025"
                  required
                  min="2000"
                  max="2100"
                />
              </div>
            </div>

            {formData.batchStartYear && formData.batchEndYear && (
              <Alert className="bg-orange-50 border-orange-200">
                <AlertDescription className="text-orange-800">
                  You are about to graduate batch <strong>{formData.batchStartYear}-{formData.batchEndYear}</strong>
                </AlertDescription>
              </Alert>
            )}
          </CardContent>
        </Card>

        <div className="flex gap-2 mt-6">
          <Button 
            type="submit" 
            variant="destructive" 
            disabled={loading || !formData.batchStartYear || !formData.batchEndYear}
          >
            <Trash2 className="h-4 w-4 mr-2" />
            {loading ? 'Graduating Batch...' : 'Graduate Batch (Delete All Data)'}
          </Button>
          <Button type="button" variant="outline" onClick={() => router.back()}>
            Cancel
          </Button>
        </div>
      </form>
    </div>
  );
}
