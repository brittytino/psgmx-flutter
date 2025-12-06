'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { RefreshCw, CheckCircle, AlertCircle, Info } from 'lucide-react';
import axios from 'axios';

export default function LeetCodeSyncPage() {
  const [syncing, setSyncing] = useState(false);
  const [result, setResult] = useState<any>(null);

  const handleSync = async () => {
    setSyncing(true);
    setResult(null);

    try {
      const response = await axios.post('/api/leetcode/sync');
      setResult({
        success: true,
        message: 'LeetCode sync completed successfully!',
        data: response.data.data,
      });
    } catch (error: any) {
      setResult({
        success: false,
        message: error.response?.data?.error || 'Failed to sync LeetCode data',
      });
    } finally {
      setSyncing(false);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h1 className="text-3xl font-bold">LeetCode Sync</h1>
        <p className="text-muted-foreground mt-1">
          Manually sync LeetCode statistics for all students
        </p>
      </div>

      <Alert className="bg-blue-50 border-blue-200">
        <Info className="h-5 w-5 text-blue-600" />
        <AlertDescription className="text-blue-800">
          <p className="font-semibold mb-1">Sync Information:</p>
          <ul className="list-disc ml-5 space-y-1 text-sm">
            <li>This process will update LeetCode stats for all students</li>
            <li>It may take several minutes to complete</li>
            <li>Automatic sync runs daily at midnight</li>
            <li>Only students with LeetCode usernames will be synced</li>
          </ul>
        </AlertDescription>
      </Alert>

      <Card>
        <CardHeader>
          <CardTitle>Manual Sync</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">
            Click the button below to start syncing LeetCode data for all students who have
            provided their LeetCode username in their profile.
          </p>

          <Button onClick={handleSync} disabled={syncing} className="w-full">
            <RefreshCw className={`h-4 w-4 mr-2 ${syncing ? 'animate-spin' : ''}`} />
            {syncing ? 'Syncing LeetCode Data...' : 'Start Sync'}
          </Button>

          {result && (
            <Alert
              variant={result.success ? 'default' : 'destructive'}
              className={result.success ? 'bg-green-50 border-green-200' : ''}
            >
              {result.success ? (
                <CheckCircle className="h-5 w-5 text-green-600" />
              ) : (
                <AlertCircle className="h-5 w-5" />
              )}
              <AlertDescription
                className={result.success ? 'text-green-800' : ''}
              >
                {result.message}
                {result.data && (
                  <div className="mt-2 text-sm">
                    <p>Synced: {result.data.synced || 0} students</p>
                    <p>Failed: {result.data.failed || 0} students</p>
                  </div>
                )}
              </AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Sync History</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            Last sync: Check the LeetCode statistics page for the latest sync information.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
