import { callOpenRouter, OpenRouterMessage } from './client';

export interface ModerationResult {
  isClean: boolean;
  flags: string[];
  confidence: number;
}

export async function moderateContent(content: string): Promise<ModerationResult> {
  const messages: OpenRouterMessage[] = [
    {
      role: 'system',
      content: `You are a content moderator. Analyze the following message for:
1. Sexual content
2. Hate speech
3. Racism
4. Offensive language
5. Harassment or bullying

Respond in JSON format:
{
  "isClean": boolean,
  "flags": ["flag1", "flag2"],
  "confidence": 0.0-1.0
}`,
    },
    {
      role: 'user',
      content: `Moderate this message: "${content}"`,
    },
  ];

  try {
    const response = await callOpenRouter(messages);
    const result = JSON.parse(response);
    
    return {
      isClean: result.isClean ?? true,
      flags: result.flags ?? [],
      confidence: result.confidence ?? 0,
    };
  } catch (error) {
    console.error('Content moderation error:', error);
    // Default to allowing content if moderation fails
    return {
      isClean: true,
      flags: [],
      confidence: 0,
    };
  }
}

export async function shouldBlockMessage(content: string): Promise<boolean> {
  const result = await moderateContent(content);
  return !result.isClean && result.confidence > 0.7;
}
