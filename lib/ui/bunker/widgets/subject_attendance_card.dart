import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/ecampus_attendance.dart';

/// Card displaying attendance statistics for a single subject.
class SubjectAttendanceCard extends StatelessWidget {
  final SubjectAttendance subject;

  const SubjectAttendanceCard({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color statusColor = subject.isCritical
        ? const Color(0xFFEF5350)
        : subject.isSafe
            ? const Color(0xFF4CAF50)
            : const Color(0xFFFF9800);

    final Color bgColor = statusColor.withValues(alpha: isDark ? 0.14 : 0.09);

    final String statusLabel = subject.isCritical
        ? 'Critical'
        : subject.isSafe
            ? 'Safe'
            : 'Warning';

    final IconData statusIcon = subject.isCritical
        ? Icons.warning_amber_rounded
        : subject.isSafe
            ? Icons.check_circle_rounded
            : Icons.info_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : statusColor.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Colored top accent stripe
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withValues(alpha: 0.3)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: title + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.courseTitle,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                subject.courseCode,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 11, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Progress bar + percentage
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value:
                                (subject.percentage / 100).clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.08),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${subject.percentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 11),

                  // Stats pills row
                  Row(
                    children: [
                      _StatPill(
                        icon: Icons.access_time_rounded,
                        label: '${subject.totalPresent}/${subject.totalHours}',
                        color: theme.colorScheme.onSurface,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 7),
                      if (subject.isSafe && subject.canBunk > 0)
                        _StatPill(
                          icon: Icons.beach_access_rounded,
                          label: 'Bunk ${subject.canBunk}',
                          color: const Color(0xFF4CAF50),
                          isDark: isDark,
                        )
                      else if (!subject.isSafe && subject.classesToAttend > 0)
                        _StatPill(
                          icon: Icons.school_rounded,
                          label: 'Attend ${subject.classesToAttend}',
                          color: const Color(0xFFEF5350),
                          isDark: isDark,
                        )
                      else
                        _StatPill(
                          icon: Icons.balance_rounded,
                          label: 'On edge',
                          color: const Color(0xFFFF9800),
                          isDark: isDark,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.85)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
