'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertCircle, Trash2 } from 'lucide-react';
import axios from 'axios';

export default function DeleteProjectPage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [project, setProject] = useState<any>(null);

  useEffect(() => {
    fetchProject();
  }, [params.id]);

  const fetchProject = async () => {
    try {
      const response = await axios.get(`/api/projects/${params.id}`);
      setProject(response.data.data);
    } catch (error) {
      console.error('Failed to fetch project:', error);
    }
  };

  const handleDelete = async () => {
    if (!confirm(`Are you sure you want to delete "${project.title}"? This action cannot be undone.`)) {
      return;
    }

    setLoading(true);

    try {
      await axios.delete(`/api/projects/${params.id}`);
      alert('Project deleted successfully!');
      router.push('/projects');
    } catch (error) {
      alert('Failed to delete project');
    } finally {
      setLoading(false);
    }
  };

  if (!project) return <div>Loading...</div>;

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h1 className="text-3xl font-bold text-red-700">Delete Project</h1>
        <p className="text-muted-foreground mt-1">
          Confirm project deletion
        </p>
      </div>

      <Alert variant="destructive">
        <AlertCircle className="h-5 w-5" />
        <AlertDescription>
          <p className="font-semibold mb-2">Warning: This action cannot be undone!</p>
          <p>You are about to permanently delete this project and all its associated data.</p>
        </AlertDescription>
      </Alert>

      <Card className="border-red-200">
        <CardHeader>
          <CardTitle>Project Details</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div>
            <p className="text-sm text-muted-foreground">Title</p>
            <p className="font-medium">{project.title}</p>
          </div>

          <div>
            <p className="text-sm text-muted-foreground">Description</p>
            <p className="text-sm">{project.description}</p>
          </div>

          <div>
            <p className="text-sm text-muted-foreground">Technologies</p>
            <p className="text-sm">{project.technologiesUsed?.join(', ')}</p>
          </div>
        </CardContent>
      </Card>

      <div className="flex gap-2">
        <Button variant="destructive" onClick={handleDelete} disabled={loading}>
          <Trash2 className="h-4 w-4 mr-2" />
          {loading ? 'Deleting...' : 'Delete Project'}
        </Button>
        <Button variant="outline" onClick={() => router.back()}>
          Cancel
        </Button>
      </div>
    </div>
  );
}
