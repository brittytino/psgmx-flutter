'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Plus, Edit, Trash2 } from 'lucide-react';
import Link from 'next/link';
import axios from 'axios';

export default function CustomFieldsPage() {
  const [fields, setFields] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchFields();
  }, []);

  const fetchFields = async () => {
    try {
      const response = await axios.get('/api/admin/custom-fields');
      setFields(response.data.data || []);
    } catch (error) {
      console.error('Failed to fetch custom fields:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this custom field? All associated data will be lost.')) return;

    try {
      await axios.delete(`/api/admin/custom-fields/${id}`);
      setFields(fields.filter((f) => f.id !== id));
    } catch (error) {
      alert('Failed to delete field');
    }
  };

  if (loading) return <div>Loading...</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Custom Fields</h1>
          <p className="text-muted-foreground mt-1">
            Manage additional profile fields for students
          </p>
        </div>
        <Link href="/admin/custom-fields/manage">
          <Button>
            <Plus className="h-4 w-4 mr-2" />
            Add Custom Field
          </Button>
        </Link>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Custom Fields ({fields.length})</CardTitle>
        </CardHeader>
        <CardContent>
          {fields.length === 0 ? (
            <p className="text-center text-muted-foreground py-8">
              No custom fields created yet
            </p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-4">Field Name</th>
                    <th className="text-left py-3 px-4">Field Type</th>
                    <th className="text-left py-3 px-4">Required</th>
                    <th className="text-left py-3 px-4">Status</th>
                    <th className="text-left py-3 px-4">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {fields.map((field) => (
                    <tr key={field.id} className="border-b hover:bg-muted/50">
                      <td className="py-3 px-4 font-medium">{field.fieldName}</td>
                      <td className="py-3 px-4">
                        <Badge variant="outline">{field.fieldType}</Badge>
                      </td>
                      <td className="py-3 px-4">
                        {field.isRequired ? (
                          <Badge className="bg-red-100 text-red-700">Required</Badge>
                        ) : (
                          <Badge variant="secondary">Optional</Badge>
                        )}
                      </td>
                      <td className="py-3 px-4">
                        {field.isActive ? (
                          <Badge className="bg-green-100 text-green-700">Active</Badge>
                        ) : (
                          <Badge variant="secondary">Inactive</Badge>
                        )}
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex gap-2">
                          <Link href={`/admin/custom-fields/manage?id=${field.id}`}>
                            <Button variant="ghost" size="sm">
                              <Edit className="h-4 w-4" />
                            </Button>
                          </Link>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleDelete(field.id)}
                          >
                            <Trash2 className="h-4 w-4 text-destructive" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
