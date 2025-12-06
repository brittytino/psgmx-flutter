'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Quote } from 'lucide-react';
import axios from 'axios';
import { motion } from 'framer-motion';

export default function MotivationQuote() {
  const [quote, setQuote] = useState<any>(null);

  useEffect(() => {
    fetchQuote();
  }, []);

  const fetchQuote = async () => {
    try {
      const response = await axios.get('/api/groups/motivation');
      setQuote(response.data.data);
    } catch (error) {
      console.error('Failed to fetch quote:', error);
    }
  };

  if (!quote) return null;

  return (
    <motion.div
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
    >
      <Card className="bg-gradient-to-r from-blue-50 to-indigo-50 border-primary/20">
        <CardContent className="p-6">
          <div className="flex gap-4">
            <Quote className="h-8 w-8 text-primary flex-shrink-0" />
            <div>
              <p className="text-lg font-medium text-gray-900 italic">
                "{quote.quote}"
              </p>
              {quote.author && (
                <p className="text-sm text-muted-foreground mt-2">
                  — {quote.author}
                </p>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
