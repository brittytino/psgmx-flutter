import 'package:flutter/material.dart';
import '../../widgets/premium_card.dart';
import '../../../../core/theme/app_dimens.dart';

class AttendanceActionCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasSubmitted; // NEW: Show if already submitted
  final int markedCount; // NEW: Number of students marked

  const AttendanceActionCard({
    super.key, 
    required this.onTap,
    this.hasSubmitted = false,
    this.markedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = hasSubmitted;
    
    return PremiumCard(
      color: isCompleted 
          ? theme.colorScheme.tertiaryContainer 
          : theme.colorScheme.primaryContainer,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isCompleted 
                  ? theme.colorScheme.tertiary 
                  : theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.check_circle_outline,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? 'Update Team Attendance' : 'Mark Team Attendance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted 
                        ? theme.colorScheme.onTertiaryContainer 
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  isCompleted 
                      ? '$markedCount marked • Tap to edit' 
                      : 'Action required for today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: (isCompleted 
                        ? theme.colorScheme.onTertiaryContainer 
                        : theme.colorScheme.onPrimaryContainer).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios, 
            size: 16,
            color: isCompleted 
                ? theme.colorScheme.onTertiaryContainer 
                : theme.colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }
}
