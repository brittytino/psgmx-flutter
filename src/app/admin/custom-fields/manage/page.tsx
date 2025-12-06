'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import axios from 'axios';

export default function ManageCustomFieldPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const fieldId = searchParams.get('id');
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    fieldName: '',
    fieldLabel: '',
    fieldType: 'TEXT',
    isRequired: false,
    isActive: true,
    options: '',
    placeholder: '',
    helpText: '',
  });

  useEffect(() => {
    if (fieldId) {
      fetchField();
    }
  }, [fieldId]);

  const fetchField = async () => {
    try {
      const response = await axios.get(`/api/admin/custom-fields/${fieldId}`);
      const field = response.data.data;
      setFormData({
        fieldName: field.fieldName,
        fieldLabel: field.fieldLabel,
        fieldType: field.fieldType,
        isRequired: field.isRequired,
        isActive: field.isActive,
        options: field.options?.join('\n') || '',
        placeholder: field.placeholder || '',
        helpText: field.helpText || '',
      });
    } catch (error) {
      console.error('Failed to fetch field:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const data = {
        ...formData,
        options: formData.options ? formData.options.split('\n').filter((o) => o.trim()) : null,
      };

      if (fieldId) {
        await axios.put(`/api/admin/custom-fields/${fieldId}`, data);
        alert('Custom field updated successfully!');
      } else {
        await axios.post('/api/admin/custom-fields', data);
        alert('Custom field created successfully!');
      }

      router.push('/admin/custom-fields');
    } catch (error: any) {
      alert(error.response?.data?.error || 'Failed to save custom field');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h1 className="text-3xl font-bold">
          {fieldId ? 'Edit Custom Field' : 'Create Custom Field'}
        </h1>
        <p className="text-muted-foreground mt-1">
          {fieldId ? 'Update custom field settings' : 'Add a new custom field to student profiles'}
        </p>
      </div>

      <form onSubmit={handleSubmit}>
        <Card>
          <CardHeader>
            <CardTitle>Field Configuration</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="fieldName">Field Name (Internal) *</Label>
                <Input
                  id="fieldName"
                  value={formData.fieldName}
                  onChange={(e) => setFormData({ ...formData, fieldName: e.target.value })}
                  placeholder="e.g., github_username"
                  required
                  disabled={!!fieldId}
                />
                <p className="text-xs text-muted-foreground">
                  Use lowercase with underscores. Cannot be changed after creation.
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="fieldLabel">Field Label (Display) *</Label>
                <Input
                  id="fieldLabel"
                  value={formData.fieldLabel}
                  onChange={(e) => setFormData({ ...formData, fieldLabel: e.target.value })}
                  placeholder="e.g., GitHub Username"
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="fieldType">Field Type *</Label>
                <select
                  id="fieldType"
                  value={formData.fieldType}
                  onChange={(e) => setFormData({ ...formData, fieldType: e.target.value })}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  required
                >
                  <option value="TEXT">Text</option>
                  <option value="TEXTAREA">Text Area</option>
                  <option value="NUMBER">Number</option>
                  <option value="EMAIL">Email</option>
                  <option value="URL">URL</option>
                  <option value="DATE">Date</option>
                  <option value="SELECT">Dropdown</option>
                  <option value="CHECKBOX">Checkbox</option>
                </select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="placeholder">Placeholder Text</Label>
                <Input
                  id="placeholder"
                  value={formData.placeholder}
                  onChange={(e) => setFormData({ ...formData, placeholder: e.target.value })}
                  placeholder="Enter placeholder text"
                />
              </div>
            </div>

            {formData.fieldType === 'SELECT' && (
              <div className="space-y-2">
                <Label htmlFor="options">Options (one per line) *</Label>
                <Textarea
                  id="options"
                  value={formData.options}
                  onChange={(e) => setFormData({ ...formData, options: e.target.value })}
                  placeholder="Option 1&#10;Option 2&#10;Option 3"
                  rows={5}
                  required
                />
              </div>
            )}

            <div className="space-y-2">
              <Label htmlFor="helpText">Help Text</Label>
              <Textarea
                id="helpText"
                value={formData.helpText}
                onChange={(e) => setFormData({ ...formData, helpText: e.target.value })}
                placeholder="Additional information about this field"
                rows={3}
              />
            </div>

            <div className="flex gap-4">
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="isRequired"
                  checked={formData.isRequired}
                  onChange={(e) => setFormData({ ...formData, isRequired: e.target.checked })}
                  className="h-4 w-4"
                />
                <Label htmlFor="isRequired">Required Field</Label>
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="isActive"
                  checked={formData.isActive}
                  onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                  className="h-4 w-4"
                />
                <Label htmlFor="isActive">Active</Label>
              </div>
            </div>
          </CardContent>
        </Card>

        <div className="flex gap-2 mt-6">
          <Button type="submit" disabled={loading}>
            {loading ? 'Saving...' : fieldId ? 'Update Field' : 'Create Field'}
          </Button>
          <Button type="button" variant="outline" onClick={() => router.back()}>
            Cancel
          </Button>
        </div>
      </form>
    </div>
  );
}
