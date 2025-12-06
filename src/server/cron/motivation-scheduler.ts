import { generateMotivationQuote } from '@/lib/openrouter/motivation';
import prisma from '@/lib/db/prisma';

export async function generateDailyMotivation() {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Check if quote already exists for today
    const existing = await prisma.motivationQuote.findFirst({
      where: {
        date: {
          gte: today,
        },
      },
    });

    if (existing) {
      console.log('Motivation quote already exists for today');
      return;
    }

    // Generate new quote
    const { quote, author } = await generateMotivationQuote();

    await prisma.motivationQuote.create({
      data: {
        quote,
        author,
        date: new Date(),
      },
    });

    console.log('Daily motivation quote generated successfully');
  } catch (error) {
    console.error('Failed to generate motivation quote:', error);
  }
}

// Run every day at 6 AM
const getMillisecondsUntil6AM = () => {
  const now = new Date();
  const next6AM = new Date();
  next6AM.setHours(6, 0, 0, 0);

  if (now.getHours() >= 6) {
    next6AM.setDate(next6AM.getDate() + 1);
  }

  return next6AM.getTime() - now.getTime();
};

setTimeout(() => {
  generateDailyMotivation();
  // Then run every 24 hours
  setInterval(generateDailyMotivation, 24 * 60 * 60 * 1000);
}, getMillisecondsUntil6AM());
