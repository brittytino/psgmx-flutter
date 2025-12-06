import { callOpenRouter, OpenRouterMessage } from './client';

export async function generateMotivationQuote(): Promise<{ quote: string; author: string }> {
  const messages: OpenRouterMessage[] = [
    {
      role: 'system',
      content: 'You are a motivational speaker. Generate an inspiring quote for computer science students preparing for placements.',
    },
    {
      role: 'user',
      content: 'Generate a unique motivational quote about career success, technology, or personal growth. Format: "Quote" - Author',
    },
  ];

  try {
    const response = await callOpenRouter(messages);
    const parts = response.split(' - ');
    
    return {
      quote: parts[0]?.replace(/['"]/g, '').trim() || 'Stay focused and keep learning.',
      author: parts[1]?.trim() || 'Unknown',
    };
  } catch (error) {
    console.error('Motivation quote generation error:', error);
    return {
      quote: 'Success is not final, failure is not fatal: it is the courage to continue that counts.',
      author: 'Winston Churchill',
    };
  }
}
