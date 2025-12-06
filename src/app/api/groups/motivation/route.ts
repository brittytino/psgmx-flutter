import { NextRequest, NextResponse } from 'next/server';
import { handleError } from '@/lib/middleware/error-handler';
import prisma from '@/lib/db/prisma';

export async function GET(req: NextRequest) {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const quote = await prisma.motivationQuote.findFirst({
      where: {
        date: {
          gte: today,
        },
      },
    });

    return NextResponse.json({
      success: true,
      data: quote,
    });
  } catch (error) {
    return handleError(error);
  }
}
