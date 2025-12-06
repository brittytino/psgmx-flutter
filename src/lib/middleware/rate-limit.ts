import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/db/prisma';

interface RateLimitStore {
  [key: string]: {
    count: number;
    resetTime: number;
  };
}

// In-memory store as fallback if DB is unavailable
const store: RateLimitStore = {};

export interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
  useDatabase?: boolean;
}

export function rateLimit(config: RateLimitConfig) {
  return async (req: NextRequest): Promise<NextResponse | null> => {
    const ip = req.ip || req.headers.get('x-forwarded-for') || 'unknown';
    const route = req.nextUrl.pathname;
    const key = `${ip}-${route}`;
    const now = Date.now();

    // Use database-backed rate limiting if enabled
    if (config.useDatabase) {
      try {
        return await databaseRateLimit(ip, route, config);
      } catch (error) {
        console.error('Database rate limit failed, falling back to memory:', error);
        // Fall through to memory-based rate limiting
      }
    }

    // Memory-based rate limiting
    if (!store[key] || now > store[key].resetTime) {
      store[key] = {
        count: 1,
        resetTime: now + config.windowMs,
      };
      return null;
    }

    store[key].count++;

    if (store[key].count > config.maxRequests) {
      return NextResponse.json(
        { error: 'Too many requests, please try again later' },
        { 
          status: 429,
          headers: {
            'X-RateLimit-Remaining': '0',
            'X-RateLimit-Reset': store[key].resetTime.toString(),
            'Retry-After': Math.ceil((store[key].resetTime - now) / 1000).toString(),
          }
        }
      );
    }

    return null;
  };
}

async function databaseRateLimit(
  identifier: string, 
  route: string, 
  config: RateLimitConfig
): Promise<NextResponse | null> {
  const now = new Date();
  const windowStart = new Date(now.getTime() - config.windowMs);
  
  // Clean up old records
  await prisma.rateLimit.deleteMany({
    where: {
      windowStart: { lt: windowStart },
    },
  });
  
  // Get or create rate limit record
  const rateLimitRecord = await prisma.rateLimit.findUnique({
    where: {
      identifier_route: { identifier, route },
    },
  });
  
  if (!rateLimitRecord || rateLimitRecord.windowStart < windowStart) {
    // Create new or reset window
    await prisma.rateLimit.upsert({
      where: {
        identifier_route: { identifier, route },
      },
      create: {
        identifier,
        route,
        requests: 1,
        windowStart: now,
      },
      update: {
        requests: 1,
        windowStart: now,
      },
    });
    
    return null;
  }
  
  // Check if limit exceeded
  if (rateLimitRecord.requests >= config.maxRequests) {
    const resetTime = rateLimitRecord.windowStart.getTime() + config.windowMs;
    return NextResponse.json(
      { error: 'Too many requests, please try again later' },
      { 
        status: 429,
        headers: {
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': resetTime.toString(),
          'Retry-After': Math.ceil((resetTime - Date.now()) / 1000).toString(),
        }
      }
    );
  }
  
  // Increment request count
  await prisma.rateLimit.update({
    where: {
      identifier_route: { identifier, route },
    },
    data: {
      requests: { increment: 1 },
    },
  });
  
  return null;
}

// Cleanup old entries every 10 minutes
setInterval(() => {
  const now = Date.now();
  Object.keys(store).forEach(key => {
    if (now > store[key].resetTime) {
      delete store[key];
    }
  });
}, 600000);
