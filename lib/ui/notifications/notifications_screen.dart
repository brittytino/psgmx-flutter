import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart' as model;
import '../../core/theme/app_dimens.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifService = Provider.of<NotificationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await notifService.markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              }
            },
            tooltip: 'Mark all as read',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Important'),
          ],
        ),
      ),
      body: FutureBuilder<List<model.AppNotification>>(
        future: notifService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load notifications',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final allNotifications = snapshot.data ?? [];
          
          if (allNotifications.isEmpty) {
            return _EmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _NotificationList(notifications: allNotifications),
              _NotificationList(
                notifications: allNotifications.where((n) => n.isRead == false || n.isRead == null).toList(),
              ),
              _NotificationList(
                notifications: allNotifications
                    .where((n) => n.type == model.NotificationType.alert)
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<model.AppNotification> notifications;

  const _NotificationList({required this.notifications});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return _EmptyState();
    }

    // Group by date
    final grouped = <String, List<model.AppNotification>>{};
    for (final notif in notifications) {
      final dateKey = DateFormat('yyyy-MM-dd').format(notif.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(notif);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dateNotifications = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                top: AppSpacing.lg,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                _formatDateHeader(date),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...dateNotifications.map((notif) => _NotificationCard(notification: notif)),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'TODAY';
    } else if (dateOnly == yesterday) {
      return 'YESTERDAY';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date).toUpperCase();
    } else {
      return DateFormat('MMM d, yyyy').format(date).toUpperCase();
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final model.AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifService = Provider.of<NotificationService>(context, listen: false);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onError),
      ),
      onDismissed: (_) async {
        await notifService.deleteNotification(notification.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        elevation: 0,
        color: (notification.isRead == true)
            ? colorScheme.surface
            : colorScheme.primaryContainer.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: (notification.isRead == true)
                ? colorScheme.outline.withValues(alpha: 0.2)
                : colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () async {
            if (notification.isRead != true) {
              await notifService.markAsRead(notification.id);
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getTypeColor(notification.type, colorScheme).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(notification.type),
                    color: _getTypeColor(notification.type, colorScheme),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: (notification.isRead == true)
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (notification.isRead != true)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(model.NotificationType type, ColorScheme colorScheme) {
    switch (type) {
      case model.NotificationType.alert:
        return colorScheme.error;
      case model.NotificationType.motivation:
        return colorScheme.tertiary;
      case model.NotificationType.reminder:
        return colorScheme.primary;
      case model.NotificationType.announcement:
        return colorScheme.secondary;
    }
  }

  IconData _getTypeIcon(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.alert:
        return Icons.warning_rounded;
      case model.NotificationType.motivation:
        return Icons.auto_awesome_rounded;
      case model.NotificationType.reminder:
        return Icons.schedule_rounded;
      case model.NotificationType.announcement:
        return Icons.campaign_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
