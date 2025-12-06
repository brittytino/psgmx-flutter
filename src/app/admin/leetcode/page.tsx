'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { RefreshCw, Trophy, TrendingUp } from 'lucide-react';
import axios from 'axios';
import { formatDateTime } from '@/lib/utils/format';

export default function LeetCodeStatsPage() {
  const [stats, setStats] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const response = await axios.get('/api/leetcode/stats');
      setStats(response.data.data);
    } catch (error) {
      console.error('Failed to fetch LeetCode stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSyncAll = async () => {
    setSyncing(true);
    try {
      await axios.post('/api/leetcode/sync');
      alert('LeetCode sync started! This may take a few minutes.');
      fetchStats();
    } catch (error) {
      alert('Failed to start sync');
    } finally {
      setSyncing(false);
    }
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  const sortedStats = [...stats].sort((a, b) => b.totalSolved - a.totalSolved);
  const topPerformers = sortedStats.slice(0, 10);

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">LeetCode Statistics</h1>
          <p className="text-muted-foreground mt-1">
            Track student competitive programming progress
          </p>
        </div>
        <Button onClick={handleSyncAll} disabled={syncing}>
          <RefreshCw className={`h-4 w-4 mr-2 ${syncing ? 'animate-spin' : ''}`} />
          {syncing ? 'Syncing...' : 'Sync All'}
        </Button>
      </div>

      {/* Top Performers */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Trophy className="h-5 w-5 text-yellow-500" />
            Top 10 Performers
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {topPerformers.map((student, index) => (
              <div
                key={student.userId}
                className="flex items-center justify-between p-3 bg-muted/50 rounded-lg"
              >
                <div className="flex items-center gap-4">
                  <div className={`
                    h-10 w-10 rounded-full flex items-center justify-center font-bold
                    ${index === 0 ? 'bg-yellow-100 text-yellow-700' :
                      index === 1 ? 'bg-gray-100 text-gray-700' :
                      index === 2 ? 'bg-orange-100 text-orange-700' :
                      'bg-blue-100 text-blue-700'}
                  `}>
                    {index + 1}
                  </div>
                  <div>
                    <p className="font-medium">{student.fullName || student.registerNumber}</p>
                    <p className="text-sm text-muted-foreground">
                      {student.registerNumber}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <div className="text-right">
                    <p className="text-2xl font-bold text-primary">
                      {student.totalSolved}
                    </p>
                    <p className="text-xs text-muted-foreground">Problems Solved</p>
                  </div>
                  <div className="flex gap-2">
                    <Badge variant="secondary" className="bg-green-100 text-green-700">
                      E: {student.easySolved}
                    </Badge>
                    <Badge variant="secondary" className="bg-yellow-100 text-yellow-700">
                      M: {student.mediumSolved}
                    </Badge>
                    <Badge variant="secondary" className="bg-red-100 text-red-700">
                      H: {student.hardSolved}
                    </Badge>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* All Students */}
      <Card>
        <CardHeader>
          <CardTitle>All Students LeetCode Stats</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-3 px-4">Student</th>
                  <th className="text-left py-3 px-4">Register No</th>
                  <th className="text-left py-3 px-4">Total</th>
                  <th className="text-left py-3 px-4">Easy</th>
                  <th className="text-left py-3 px-4">Medium</th>
                  <th className="text-left py-3 px-4">Hard</th>
                  <th className="text-left py-3 px-4">Last Synced</th>
                </tr>
              </thead>
              <tbody>
                {sortedStats.map((student) => (
                  <tr key={student.userId} className="border-b hover:bg-muted/50">
                    <td className="py-3 px-4 font-medium">
                      {student.fullName || '-'}
                    </td>
                    <td className="py-3 px-4">{student.registerNumber}</td>
                    <td className="py-3 px-4">
                      <span className="font-bold text-primary">{student.totalSolved}</span>
                    </td>
                    <td className="py-3 px-4">{student.easySolved}</td>
                    <td className="py-3 px-4">{student.mediumSolved}</td>
                    <td className="py-3 px-4">{student.hardSolved}</td>
                    <td className="py-3 px-4 text-sm text-muted-foreground">
                      {student.lastSyncedAt ? formatDateTime(student.lastSyncedAt) : 'Never'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
