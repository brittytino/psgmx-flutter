import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A premium-styled notification bell icon with badge indicator
class NotificationBellIcon extends StatelessWidget {
  /// Number of unread notifications (0 = no badge)
  final int unreadCount;
  
  /// Callback when notification bell is tapped
  final VoidCallback? onTap;

  const NotificationBellIcon({
    super.key,
    this.unreadCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap ?? () {
          context.push('/notifications');
        },
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_rounded,
              color: colorScheme.onSurface,
              size: 22,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.error,
                        colorScheme.error.withValues(alpha: 0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.error.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: TextStyle(
                        color: colorScheme.onError,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        tooltip: unreadCount > 0 ? '$unreadCount new notifications' : 'Notifications',
        padding: const EdgeInsets.all(8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
