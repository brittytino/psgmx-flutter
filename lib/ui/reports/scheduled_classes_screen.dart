import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/scheduled_date.dart';
import '../../services/attendance_schedule_service.dart';

class ScheduledClassesScreen extends StatefulWidget {
  const ScheduledClassesScreen({super.key});

  @override
  State<ScheduledClassesScreen> createState() => _ScheduledClassesScreenState();
}

class _ScheduledClassesScreenState extends State<ScheduledClassesScreen> {
  late AttendanceScheduleService _scheduleService;
  List<ScheduledDate> _scheduledDates = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scheduleService = AttendanceScheduleService();
    _loadScheduledDates();
  }

  Future<void> _loadScheduledDates() async {
    setState(() => _isLoading = true);
    try {
      final dates = await _scheduleService.getScheduledDates();
      dates.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _scheduledDates = dates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading scheduled classes: $e')),
        );
      }
    }
  }

  List<ScheduledDate> _getFilteredDates() {
    return _scheduledDates.where((item) {
      return item.date.year == _selectedMonth.year &&
          item.date.month == _selectedMonth.month;
    }).toList();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredDates = _getFilteredDates();
    final dateFormat = DateFormat('EEE, MMM d, y');
    final monthFormat = DateFormat('MMMM y');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scheduled Classes',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth,
                  ),
                  Expanded(
                    child: Text(
                      monthFormat.format(_selectedMonth),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
          ),

          // Scheduled classes list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 80,
                              color: Colors.grey.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No scheduled classes',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'for ${monthFormat.format(_selectedMonth)}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadScheduledDates,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: filteredDates.length,
                          itemBuilder: (context, index) {
                            final item = filteredDates[index];
                            final date = item.date;
                            // Check if date has "is working day" info (from database)
                            // For now, we'll assume all are working days unless noted
                            final isWorking = true;

                            // Check if date is today
                            final today = DateTime.now();
                            final isToday = date.year == today.year &&
                                date.month == today.month &&
                                date.day == today.day;

                            // Check if date is in past
                            final isPast = date.isBefore(DateTime(
                              today.year,
                              today.month,
                              today.day,
                            ));

                            return Container(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                  color: isToday
                                      ? colorScheme.primary.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                  width: isToday ? 2 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Date and status row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                dateFormat.format(date),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isWorking
                                                    ? 'Working Day'
                                                    : 'Holiday',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Status badges
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (isToday)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: AppSpacing.sm,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppRadius.sm),
                                                ),
                                                child: Text(
                                                  'Today',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                            if (isPast)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: AppSpacing.sm,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppRadius.sm),
                                                ),
                                                child: Text(
                                                  'Past',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isWorking
                                                    ? Colors.green
                                                        .withValues(alpha: 0.1)
                                                    : Colors.orange
                                                        .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppRadius.sm),
                                              ),
                                              child: Text(
                                                isWorking ? 'Class' : 'Off',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isWorking
                                                      ? Colors.green
                                                      : Colors.orange,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
