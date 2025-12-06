import axios from 'axios';

const LEETCODE_GRAPHQL_URL = 'https://leetcode.com/graphql';

export interface LeetCodeUserData {
  username: string;
  profile: {
    realName: string;
    ranking: number;
    reputation: number;
  };
  submitStats: {
    acSubmissionNum: Array<{
      difficulty: string;
      count: number;
      submissions: number;
    }>;
  };
}

export async function fetchLeetCodeProfile(username: string): Promise<LeetCodeUserData | null> {
  const query = `
    query getUserProfile($username: String!) {
      matchedUser(username: $username) {
        username
        profile {
          realName
          ranking
          reputation
        }
        submitStats {
          acSubmissionNum {
            difficulty
            count
            submissions
          }
        }
      }
    }
  `;

  try {
    const response = await axios.post(
      LEETCODE_GRAPHQL_URL,
      {
        query,
        variables: { username },
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Referer': 'https://leetcode.com',
        },
      }
    );

    const userData = response.data?.data?.matchedUser;
    if (!userData) return null;

    return {
      username: userData.username,
      profile: userData.profile || { realName: '', ranking: 0, reputation: 0 },
      submitStats: userData.submitStats || { acSubmissionNum: [] },
    };
  } catch (error) {
    console.error(`LeetCode fetch error for ${username}:`, error);
    return null;
  }
}

export function parseLeetCodeStats(data: LeetCodeUserData) {
  const stats = data.submitStats.acSubmissionNum || [];
  
  const easyCount = stats.find((s: any) => s.difficulty === 'Easy')?.count || 0;
  const mediumCount = stats.find((s: any) => s.difficulty === 'Medium')?.count || 0;
  const hardCount = stats.find((s: any) => s.difficulty === 'Hard')?.count || 0;
  
  return {
    totalSolved: easyCount + mediumCount + hardCount,
    easySolved: easyCount,
    mediumSolved: mediumCount,
    hardSolved: hardCount,
    ranking: data.profile.ranking,
    reputation: data.profile.reputation,
  };
}

export async function batchFetchLeetCodeProfiles(
  usernames: string[]
): Promise<Map<string, ReturnType<typeof parseLeetCodeStats> | null>> {
  const results = new Map<string, ReturnType<typeof parseLeetCodeStats> | null>();
  
  // Process in batches of 5 to avoid rate limiting
  const batchSize = 5;
  for (let i = 0; i < usernames.length; i += batchSize) {
    const batch = usernames.slice(i, i + batchSize);
    
    const promises = batch.map(async (username) => {
      try {
        const data = await fetchLeetCodeProfile(username);
        if (data) {
          results.set(username, parseLeetCodeStats(data));
        } else {
          results.set(username, null);
        }
      } catch (error) {
        console.error(`Failed to fetch LeetCode profile for ${username}:`, error);
        results.set(username, null);
      }
    });
    
    await Promise.all(promises);
    
    // Add delay between batches to avoid rate limiting
    if (i + batchSize < usernames.length) {
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }
  
  return results;
}
