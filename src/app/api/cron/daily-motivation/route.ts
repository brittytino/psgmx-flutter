import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/db/prisma';
import { callOpenRouter, type OpenRouterMessage } from '@/lib/openrouter/client';
import { pusherServer } from '@/lib/pusher/server';

export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';

export async function GET(request: NextRequest) {
  try {
    // Verify cron secret
    const authHeader = request.headers.get('authorization');
    const cronSecret = process.env.CRON_SECRET;
    
    if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Check if quote already exists for today
    const existingQuote = await prisma.motivationQuote.findUnique({
      where: { date: today },
    });

    if (existingQuote) {
      return NextResponse.json({
        success: true,
        message: 'Quote already exists for today',
        quote: existingQuote,
      });
    }

    // Generate new motivational quote
    const messages: OpenRouterMessage[] = [
      {
        role: 'system',
        content: 'You are a motivational quote generator. Generate inspiring, positive, and professional quotes suitable for students and professionals.',
      },
      {
        role: 'user',
        content: 'Generate a single motivational quote about success, learning, perseverance, or career growth. Provide ONLY the quote and its author in the format: "Quote text" - Author Name. If the quote is original, use "Anonymous" as the author.',
      },
    ];

    const response = await callOpenRouter(messages, 'google/gemini-2.0-flash-exp:free');

    // Parse the response
    const match = response.match(/"([^"]+)"\s*-\s*(.+)/);
    
    let quote = response;
    let author = 'Anonymous';
    
    if (match) {
      quote = match[1];
      author = match[2].trim();
    }

    // Save to database
    const motivationQuote = await prisma.motivationQuote.create({
      data: {
        quote,
        author,
        date: today,
      },
    });

    // Send to all active groups via Pusher
    if (process.env.PUSHER_KEY) {
      try {
        const groups = await prisma.group.findMany({
          where: { isActive: true },
          select: { id: true },
        });

        const channels = groups.map(g => `group-${g.id}`);
        if (channels.length > 0) {
          await pusherServer.triggerBatch(
            channels.map(channel => ({
              channel,
              name: 'daily-motivation',
              data: {
                quote: motivationQuote.quote,
                author: motivationQuote.author,
                date: motivationQuote.date,
              },
            }))
          );
        }
      } catch (error) {
        console.error('Failed to send via Pusher:', error);
      }
    }

    return NextResponse.json({
      success: true,
      message: 'Daily motivation quote generated',
      quote: motivationQuote,
    });
  } catch (error: any) {
    console.error('Daily motivation quote cron error:', error);
    return NextResponse.json(
      { error: 'Failed to generate quote', message: error.message },
      { status: 500 }
    );
  }
}
