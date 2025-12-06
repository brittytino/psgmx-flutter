'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Download, FileSpreadsheet, CheckCircle } from 'lucide-react';
import axios from 'axios';
import * as XLSX from 'xlsx';

export default function ExportStudentsPage() {
  const [exporting, setExporting] = useState(false);
  const [exportOptions, setExportOptions] = useState({
    includeProfiles: true,
    includeLeetCode: true,
    includeProjects: false,
    classSection: '',
    academicYear: '',
  });

  const handleExport = async () => {
    setExporting(true);

    try {
      const response = await axios.get('/api/students', {
        params: {
          classSection: exportOptions.classSection || undefined,
          academicYear: exportOptions.academicYear || undefined,
        },
      });

      const students = response.data.data;

      // Prepare data for export
      const exportData = students.map((student: any) => {
        const row: any = {
          'Register Number': student.registerNumber,
          'Email': student.email,
          'Class': student.classSection,
          'Year': student.academicYear,
          'Batch': `${student.batchStartYear}-${student.batchEndYear}`,
        };

        if (exportOptions.includeProfiles && student.studentProfile) {
          row['Full Name'] = student.studentProfile.fullName || '';
          row['Contact'] = student.studentProfile.contactNumber || '';
          row['Personal Email'] = student.studentProfile.personalEmail || '';
          row['UG Degree'] = student.studentProfile.ugDegree || '';
          row['UG College'] = student.studentProfile.ugCollege || '';
          row['UG CGPA'] = student.studentProfile.ugPercentage || '';
          row['10th %'] = student.studentProfile.tenthPercentage || '';
          row['12th %'] = student.studentProfile.twelfthPercentage || '';
          row['Skills'] = student.studentProfile.technicalSkills?.join(', ') || '';
        }

        if (exportOptions.includeLeetCode && student.leetcodeProfile) {
          row['LeetCode Total'] = student.leetcodeProfile.totalSolved || 0;
          row['LeetCode Easy'] = student.leetcodeProfile.easySolved || 0;
          row['LeetCode Medium'] = student.leetcodeProfile.mediumSolved || 0;
          row['LeetCode Hard'] = student.leetcodeProfile.hardSolved || 0;
        }

        return row;
      });

      // Create workbook and download
      const worksheet = XLSX.utils.json_to_sheet(exportData);
      const workbook = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(workbook, worksheet, 'Students');

      const fileName = `students_export_${new Date().toISOString().split('T')[0]}.xlsx`;
      XLSX.writeFile(workbook, fileName);

      alert(`Exported ${students.length} students successfully!`);
    } catch (error) {
      console.error('Export failed:', error);
      alert('Failed to export students');
    } finally {
      setExporting(false);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h1 className="text-3xl font-bold">Export Students</h1>
        <p className="text-muted-foreground mt-1">
          Download student data in Excel format
        </p>
      </div>

      <Alert className="bg-blue-50 border-blue-200">
        <FileSpreadsheet className="h-5 w-5 text-blue-600" />
        <AlertDescription className="text-blue-800">
          Export student data including profiles, academic information, and statistics
          in Excel format for analysis or backup purposes.
        </AlertDescription>
      </Alert>

      <Card>
        <CardHeader>
          <CardTitle>Export Options</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-3">
            <Label className="text-base font-semibold">Data to Include:</Label>
            
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="includeProfiles"
                checked={exportOptions.includeProfiles}
                onChange={(e) =>
                  setExportOptions({ ...exportOptions, includeProfiles: e.target.checked })
                }
                className="h-4 w-4"
              />
              <Label htmlFor="includeProfiles" className="font-normal">
                Profile Information (Name, Contact, Academic Details)
              </Label>
            </div>

            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="includeLeetCode"
                checked={exportOptions.includeLeetCode}
                onChange={(e) =>
                  setExportOptions({ ...exportOptions, includeLeetCode: e.target.checked })
                }
                className="h-4 w-4"
              />
              <Label htmlFor="includeLeetCode" className="font-normal">
                LeetCode Statistics
              </Label>
            </div>

            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="includeProjects"
                checked={exportOptions.includeProjects}
                onChange={(e) =>
                  setExportOptions({ ...exportOptions, includeProjects: e.target.checked })
                }
                className="h-4 w-4"
              />
              <Label htmlFor="includeProjects" className="font-normal">
                Project Details
              </Label>
            </div>
          </div>

          <div className="border-t pt-4">
            <Label className="text-base font-semibold">Filters (Optional):</Label>
            <div className="grid grid-cols-2 gap-4 mt-3">
              <div className="space-y-2">
                <Label htmlFor="classSection">Class Section</Label>
                <select
                  id="classSection"
                  value={exportOptions.classSection}
                  onChange={(e) =>
                    setExportOptions({ ...exportOptions, classSection: e.target.value })
                  }
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                >
                  <option value="">All Classes</option>
                  <option value="G1">G1</option>
                  <option value="G2">G2</option>
                </select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="academicYear">Academic Year</Label>
                <select
                  id="academicYear"
                  value={exportOptions.academicYear}
                  onChange={(e) =>
                    setExportOptions({ ...exportOptions, academicYear: e.target.value })
                  }
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                >
                  <option value="">All Years</option>
                  <option value="1">Year 1</option>
                  <option value="2">Year 2</option>
                </select>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <Button onClick={handleExport} disabled={exporting} className="w-full">
        <Download className={`h-4 w-4 mr-2 ${exporting ? 'animate-bounce' : ''}`} />
        {exporting ? 'Exporting...' : 'Export to Excel'}
      </Button>
    </div>
  );
}
