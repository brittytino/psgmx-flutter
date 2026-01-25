import 'package:flutter/material.dart';
import '../../../core/theme/app_dimens.dart';
import '../../widgets/premium_card.dart';
import '../../../models/leetcode_stats.dart';
import '../leaderboard_screen.dart';

class LeaderboardCard extends StatelessWidget {
  final List<LeetCodeStats> topSolvers;

  const LeaderboardCard({super.key, required this.topSolvers});

  @override
  Widget build(BuildContext context) {
    if (topSolvers.isEmpty) return const SizedBox.shrink();

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'WEEKLY TOP SOLVERS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...topSolvers.asMap().entries.map((entry) {
            final idx = entry.key;
            final user = entry.value;
            final isFirst = idx == 0;
            final isSecond = idx == 1;
            // isThird removed
            
            Color badgeColor;
            if (isFirst) {
              badgeColor = const Color(0xFFFFD700); // Gold
            } else if (isSecond) {
              badgeColor = const Color(0xFFC0C0C0); // Silver
            } else {
              badgeColor = const Color(0xFFCD7F32); // Bronze
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeColor),
                    ),
                    child: Text(
                      '${idx + 1}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${user.weeklyScore} solved this week', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${user.totalSolved} Total', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)
                    ),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen())
                );
              },
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: const Text("View All Leaderboards"),
            ),
          )
        ],
      ),
    );
  }
}
