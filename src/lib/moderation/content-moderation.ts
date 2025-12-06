import { callOpenRouter, type OpenRouterMessage } from '@/lib/openrouter/client';

export interface ModerationResult {
  isSafe: boolean;
  flagged: boolean;
  categories: {
    sexual: boolean;
    hate: boolean;
    violence: boolean;
    harassment: boolean;
    selfHarm: boolean;
  };
  scores: {
    sexual: number;
    hate: number;
    violence: number;
    harassment: number;
    selfHarm: number;
  };
  reason?: string;
}

const MODERATION_PROMPT = `You are a content moderation AI. Analyze the following message for inappropriate content.
Check for:
1. Sexual content or explicit material
2. Hate speech, racism, or discrimination
3. Violence or threats
4. Harassment or bullying
5. Self-harm content

Respond ONLY with a valid JSON object in this exact format:
{
  "isSafe": true/false,
  "flagged": true/false,
  "categories": {
    "sexual": true/false,
    "hate": true/false,
    "violence": true/false,
    "harassment": true/false,
    "selfHarm": true/false
  },
  "scores": {
    "sexual": 0.0-1.0,
    "hate": 0.0-1.0,
    "violence": 0.0-1.0,
    "harassment": 0.0-1.0,
    "selfHarm": 0.0-1.0
  },
  "reason": "explanation if flagged"
}

Message to analyze: `;

export async function moderateContent(content: string): Promise<ModerationResult> {
  try {
    const messages: OpenRouterMessage[] = [
      {
        role: 'system',
        content: 'You are a content moderation assistant. Always respond with valid JSON only.',
      },
      {
        role: 'user',
        content: `${MODERATION_PROMPT}"${content}"`,
      },
    ];
    
    const result = await callOpenRouter(messages, 'google/gemini-2.0-flash-exp:free');
    
    if (!result) {
      throw new Error('No response from moderation AI');
    }
    
    // Parse JSON response
    const parsed = JSON.parse(result.trim());
    
    return {
      isSafe: parsed.isSafe ?? true,
      flagged: parsed.flagged ?? false,
      categories: {
        sexual: parsed.categories?.sexual ?? false,
        hate: parsed.categories?.hate ?? false,
        violence: parsed.categories?.violence ?? false,
        harassment: parsed.categories?.harassment ?? false,
        selfHarm: parsed.categories?.selfHarm ?? false,
      },
      scores: {
        sexual: parsed.scores?.sexual ?? 0,
        hate: parsed.scores?.hate ?? 0,
        violence: parsed.scores?.violence ?? 0,
        harassment: parsed.scores?.harassment ?? 0,
        selfHarm: parsed.scores?.selfHarm ?? 0,
      },
      reason: parsed.reason,
    };
  } catch (error) {
    console.error('Content moderation error:', error);
    
    // Fallback: simple keyword-based moderation
    return fallbackModeration(content);
  }
}

function fallbackModeration(content: string): ModerationResult {
  const lowerContent = content.toLowerCase();
  
  const sexualKeywords = ['sex', 'porn', 'xxx', 'nude', 'explicit'];
  const hateKeywords = ['hate', 'racist', 'nigger', 'faggot', 'retard'];
  const violenceKeywords = ['kill', 'murder', 'bomb', 'terrorist', 'weapon'];
  const harassmentKeywords = ['stupid', 'idiot', 'loser', 'ugly', 'die'];
  
  const sexual = sexualKeywords.some(kw => lowerContent.includes(kw));
  const hate = hateKeywords.some(kw => lowerContent.includes(kw));
  const violence = violenceKeywords.some(kw => lowerContent.includes(kw));
  const harassment = harassmentKeywords.some(kw => lowerContent.includes(kw));
  const selfHarm = lowerContent.includes('suicide') || lowerContent.includes('kill myself');
  
  const flagged = sexual || hate || violence || harassment || selfHarm;
  
  return {
    isSafe: !flagged,
    flagged,
    categories: {
      sexual,
      hate,
      violence,
      harassment,
      selfHarm,
    },
    scores: {
      sexual: sexual ? 0.8 : 0,
      hate: hate ? 0.8 : 0,
      violence: violence ? 0.8 : 0,
      harassment: harassment ? 0.8 : 0,
      selfHarm: selfHarm ? 0.8 : 0,
    },
    reason: flagged ? 'Content flagged by keyword filter' : undefined,
  };
}

export async function batchModerateContent(
  contents: string[]
): Promise<ModerationResult[]> {
  const results = await Promise.all(
    contents.map(content => moderateContent(content))
  );
  
  return results;
}
