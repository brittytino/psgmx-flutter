import 'package:flutter/material.dart';
import '../../../core/theme/app_dimens.dart';
import '../../widgets/premium_card.dart';

class BirthdayGreetingCard extends StatelessWidget {
  final String userName;
  
  const BirthdayGreetingCard({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ').first;
    
    return PremiumCard(
      backgroundColor: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
      hasBorder: true,
      child: Row(
        children: [
          // Birthday Icon
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '🎂',
              style: TextStyle(fontSize: 32),
            ),
          ),
          
          const SizedBox(width: AppSpacing.lg),
          
          // Birthday Message
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Happy Birthday!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF6B6B),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Wishing you a fantastic year ahead, $firstName! 🎉',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
