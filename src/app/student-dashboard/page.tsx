'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/hooks/useAuth';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { CheckCircle2, AlertCircle, FileText, FolderKanban, Code2 } from 'lucide-react';
import Link from 'next/link';
import axios from 'axios';
import { motion } from 'framer-motion';

export default function StudentDashboard() {
  const { user } = useAuth();
  const [profile, setProfile] = useState<any>(null);
  const [stats, setStats] = useState({
    projectCount: 0,
    documentCount: 0,
    leetcodeSolved: 0,
  });

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const [profileRes, projectsRes, docsRes] = await Promise.all([
        axios.get('/api/auth/session'),
        axios.get('/api/projects'),
        axios.get('/api/documents'),
      ]);

      setProfile(profileRes.data.data.studentProfile);
      setStats({
        projectCount: projectsRes.data.data.length,
        documentCount: docsRes.data.data.length,
        leetcodeSolved: 0, // Will be updated from LeetCode API
      });
    } catch (error) {
      console.error('Failed to fetch dashboard data:', error);
    }
  };

  const completionScore = profile?.profileCompletionScore || 0;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Welcome, {user?.fullName || user?.registerNumber}!</h1>
        <p className="text-muted-foreground mt-1">
          Here's an overview of your placement preparation
        </p>
      </div>

      {/* Profile Completion */}
      <Card>
        <CardHeader>
          <CardTitle>Profile Completion</CardTitle>
          <CardDescription>
            Complete your profile to increase visibility to recruiters
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-2xl font-bold">{completionScore}%</span>
            {completionScore >= 80 ? (
              <CheckCircle2 className="h-6 w-6 text-green-500" />
            ) : (
              <AlertCircle className="h-6 w-6 text-orange-500" />
            )}
          </div>
          <Progress value={completionScore} className="h-2" />
          {completionScore < 100 && (
            <Link href="/profile/edit">
              <Button variant="outline" className="w-full">
                Complete Profile
              </Button>
            </Link>
          )}
        </CardContent>
      </Card>

      {/* Quick Stats */}
      <div className="grid gap-4 md:grid-cols-3">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
        >
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Projects</CardTitle>
              <FolderKanban className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.projectCount}</div>
              <Link href="/projects">
                <Button variant="link" className="p-0 h-auto text-sm">
                  View all projects
                </Button>
              </Link>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Documents</CardTitle>
              <FileText className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.documentCount}</div>
              <Link href="/documents">
                <Button variant="link" className="p-0 h-auto text-sm">
                  Manage documents
                </Button>
              </Link>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
        >
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">LeetCode</CardTitle>
              <Code2 className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.leetcodeSolved}</div>
              <Link href="/profile/edit">
                <Button variant="link" className="p-0 h-auto text-sm">
                  Sync LeetCode
                </Button>
              </Link>
            </CardContent>
          </Card>
        </motion.div>
      </div>

      {/* Recent Announcements */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Announcements</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            No recent announcements
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
