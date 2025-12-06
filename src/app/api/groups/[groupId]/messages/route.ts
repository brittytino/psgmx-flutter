import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/db/prisma';
import { authenticate } from '@/lib/middleware/rbac';
import { rateLimit } from '@/lib/middleware/rate-limit';
import { moderateContent } from '@/lib/moderation/content-moderation';
import { createAuditLog, AUDIT_ACTIONS, ENTITY_TYPES } from '@/lib/audit/audit-log';
import { pusherServer } from '@/lib/pusher/server';
import { z } from 'zod';

const sendMessageSchema = z.object({
  content: z.string().min(1).max(5000),
});

// GET /api/groups/[groupId]/messages - Get messages for a group
export async function GET(
  request: NextRequest,
  { params }: { params: { groupId: string } }
) {
  const rateLimitResult = await rateLimit({
    windowMs: 60000,
    maxRequests: 60,
    useDatabase: true,
  })(request);
  
  if (rateLimitResult) return rateLimitResult;

  const authResult = await authenticate(request);
  if (!authResult.success) return authResult.response;
  
  const { user } = authResult;
  const { groupId } = params;

  try {
    // Check if user is member of the group
    const membership = await prisma.groupMember.findUnique({
      where: {
        groupId_userId: {
          groupId,
          userId: user.userId,
        },
      },
    });

    if (!membership) {
      return NextResponse.json(
        { error: 'Access denied. You are not a member of this group.' },
        { status: 403 }
      );
    }

    // Get pagination parameters
    const { searchParams } = new URL(request.url);
    const limit = parseInt(searchParams.get('limit') || '50');
    const cursor = searchParams.get('cursor');

    const messages = await prisma.message.findMany({
      where: {
        groupId,
        ...(cursor && { id: { lt: cursor } }),
      },
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        user: {
          select: {
            registerNumber: true,
            studentProfile: {
              select: { fullName: true },
            },
          },
        },
      },
    });

    return NextResponse.json({
      messages: messages.reverse(),
      hasMore: messages.length === limit,
      nextCursor: messages.length > 0 ? messages[0].id : null,
    });
  } catch (error: any) {
    console.error('Get messages error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch messages' },
      { status: 500 }
    );
  }
}

// POST /api/groups/[groupId]/messages - Send a message
export async function POST(
  request: NextRequest,
  { params }: { params: { groupId: string } }
) {
  const rateLimitResult = await rateLimit({
    windowMs: 60000,
    maxRequests: 30,
    useDatabase: true,
  })(request);
  
  if (rateLimitResult) return rateLimitResult;

  const authResult = await authenticate(request);
  if (!authResult.success) return authResult.response;
  
  const { user } = authResult;
  const { groupId } = params;

  try {
    const body = await request.json();
    const { content } = sendMessageSchema.parse(body);

    // Check if user is member of the group
    const membership = await prisma.groupMember.findUnique({
      where: {
        groupId_userId: {
          groupId,
          userId: user.userId,
        },
      },
    });

    if (!membership) {
      return NextResponse.json(
        { error: 'Access denied. You are not a member of this group.' },
        { status: 403 }
      );
    }

    // Content moderation
    const moderation = await moderateContent(content);

    if (!moderation.isSafe) {
      await createAuditLog({
        userId: user.userId,
        action: AUDIT_ACTIONS.MESSAGE_FLAGGED,
        entityType: ENTITY_TYPES.MESSAGE,
        ipAddress: request.ip,
        userAgent: request.headers.get('user-agent') || undefined,
        details: {
          groupId,
          content: content.substring(0, 100),
          moderation,
        },
      });

      return NextResponse.json(
        {
          error: 'Message contains inappropriate content and cannot be sent.',
          categories: moderation.categories,
          reason: moderation.reason,
        },
        { status: 400 }
      );
    }

    // Create message
    const message = await prisma.message.create({
      data: {
        groupId,
        userId: user.userId,
        content,
        isModerated: moderation.flagged,
        moderationFlags: moderation.flagged ? (moderation as any) : null,
      },
      include: {
        user: {
          select: {
            registerNumber: true,
            studentProfile: {
              select: { fullName: true },
            },
          },
        },
      },
    });

    await createAuditLog({
      userId: user.userId,
      action: AUDIT_ACTIONS.CREATE,
      entityType: ENTITY_TYPES.MESSAGE,
      entityId: message.id,
      ipAddress: request.ip,
      userAgent: request.headers.get('user-agent') || undefined,
      details: { groupId, isModerated: moderation.flagged },
    });

    // Send real-time notification via Pusher
    if (process.env.PUSHER_KEY) {
      try {
        await pusherServer.trigger(`group-${groupId}`, 'new-message', {
          id: message.id,
          content: message.content,
          createdAt: message.createdAt,
          user: {
            registerNumber: message.user.registerNumber,
            fullName: message.user.studentProfile?.fullName || 'Unknown',
          },
        });
      } catch (error) {
        console.error('Pusher trigger error:', error);
      }
    }

    return NextResponse.json({ success: true, message });
  } catch (error: any) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.errors },
        { status: 400 }
      );
    }
    
    console.error('Send message error:', error);
    return NextResponse.json(
      { error: 'Failed to send message' },
      { status: 500 }
    );
  }
}
