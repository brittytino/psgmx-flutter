import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../models/attendance.dart';
import '../../../services/attendance_service.dart';
import '../../../services/attendance_schedule_service.dart';

enum _DateQuickFilter {
  all,
  recent30,
  recent90,
  thisYear,
}

class IndividualAttendanceWizard extends StatefulWidget {
  final List<AttendanceSummary> allStudents;
  final String markedBy;

  const IndividualAttendanceWizard({
    super.key,
    required this.allStudents,
    required this.markedBy,
  });

  @override
  State<IndividualAttendanceWizard> createState() =>
      _IndividualAttendanceWizardState();
}

class _IndividualAttendanceWizardState
    extends State<IndividualAttendanceWizard> {
  final AttendanceService _attendanceService = AttendanceService();
  final AttendanceScheduleService _scheduleService =
      AttendanceScheduleService();
  final TextEditingController _searchController = TextEditingController();

  final Set<String> _selectedStudentIds = <String>{};
  final Set<DateTime> _selectedDates = <DateTime>{};
  List<DateTime> _availableClassDays = [];
  Map<String, List<AttendanceStatus>> _existingStatusMap = {};
  AttendanceStatus _selectedStatus = AttendanceStatus.present;

  int _currentStep = 0;
  bool _isSaving = false;
  bool _isLoadingDates = true;
  String? _errorMessage;
  _DateQuickFilter _dateQuickFilter = _DateQuickFilter.all;

  late final Map<String, String?> _studentTeamMap = {
    for (final student in widget.allStudents) student.studentId: student.teamId,
  };

  @override
  void initState() {
    super.initState();
    _loadAvailableDates();
  }

  Future<void> _loadAvailableDates() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final scheduledDates = await _scheduleService.getScheduledDates();
      final days = scheduledDates
          .map((date) =>
              DateTime(date.date.year, date.date.month, date.date.day))
          .where((date) => !date.isAfter(today))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      if (mounted) {
        setState(() {
          _availableClassDays = days;
          _isLoadingDates = false;
        });

        // After loading dates, if we have selected students, load their history
        if (_selectedStudentIds.isNotEmpty) {
          _loadExistingAttendance();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load class days: $e';
          _isLoadingDates = false;
        });
      }
    }
  }

  Future<void> _loadExistingAttendance() async {
    if (_selectedStudentIds.isEmpty || _availableClassDays.isEmpty) return;

    // We only load for the FIRST selected student for visualization simplicity
    // or we could aggregate. Let's try to load for all selected to show "Any Marked".
    // For now, let's just fetch for the first few students to avoid query explosion
    // OR fetch range for these students.

    try {
      // Just fetch for the first student as a reference if multiple are selected,
      // or if we want to show accurate data, we need to be smart.
      // Let's assume the user usually does this for 1 student as the name implies "Individual".

      final studentId = _selectedStudentIds.first;
      final history = await _attendanceService.getStudentAttendanceHistory(
          studentId: studentId,
          startDate: _availableClassDays.last,
          endDate: _availableClassDays.first);

      if (mounted) {
        setState(() {
          final Map<String, List<AttendanceStatus>> newMap = {};

          for (final record in history) {
            final dateStr = record.date.toIso8601String().split('T')[0];
            if (!newMap.containsKey(dateStr)) {
              newMap[dateStr] = [];
            }
            if (record.status != AttendanceStatus.na) {
              newMap[dateStr]!.add(record.status);
            }
          }
          _existingStatusMap = newMap;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.95;
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.95,
        child: Container(
          height: height,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildStepContent()),
              const SizedBox(height: AppSpacing.md),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const steps = ['Select students', 'Choose dates', 'Preview'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          steps[_currentStep],
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Step ${_currentStep + 1} of 3',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: (_currentStep + 1) / 3,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStudentSelectionStep();
      case 1:
        return _buildDateRangeStep();
      default:
        return _buildPreviewStep();
    }
  }

  Widget _buildStudentSelectionStep() {
    final filteredStudents = widget.allStudents.where((student) {
      if (_searchController.text.isEmpty) return true;
      final query = _searchController.text.toLowerCase();
      return student.name.toLowerCase().contains(query) ||
          student.regNo.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionStats(),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search by name or Register No',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.done_all, size: 16),
              label: const Text('Select All'),
              onPressed: () {
                setState(() {
                  for (final student in filteredStudents) {
                    _selectedStudentIds.add(student.studentId);
                  }
                });
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.clear_all, size: 16),
              label: const Text('Deselect All'),
              onPressed: () => setState(_selectedStudentIds.clear),
            ),
            ActionChip(
              avatar: const Icon(Icons.flip, size: 16),
              label: const Text('Invert'),
              onPressed: () {
                setState(() {
                  for (final student in filteredStudents) {
                    if (_selectedStudentIds.contains(student.studentId)) {
                      _selectedStudentIds.remove(student.studentId);
                    } else {
                      _selectedStudentIds.add(student.studentId);
                    }
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: filteredStudents.isEmpty
              ? Center(
                  child: Text(
                    'No students match your search',
                    style: GoogleFonts.inter(color: Colors.grey[600]),
                  ),
                )
              : ListView.separated(
                  itemCount: filteredStudents.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    final isSelected =
                        _selectedStudentIds.contains(student.studentId);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.05)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _toggleStudent(student.studentId),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Transform.scale(
                                scale: 1.1,
                                child: Checkbox(
                                  value: isSelected,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                  activeColor:
                                      Theme.of(context).colorScheme.primary,
                                  onChanged: (_) =>
                                      _toggleStudent(student.studentId),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            student.regNo,
                                            style: GoogleFonts.sourceCodePro(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (student.teamId != null)
                                          Text(
                                            'Team ${student.teamId}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color
                                                  ?.withValues(alpha: 0.7),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDateRangeStep() {
    final visibleDays = _visibleClassDays;
    final selectedVisibleCount = visibleDays
        .where((date) => _selectedDates.any((d) => _isSameDay(d, date)))
        .length;
    final allVisibleSelected =
        visibleDays.isNotEmpty && selectedVisibleCount == visibleDays.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Stats Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedDates.length} days selected',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${visibleDays.length} visible • ${_availableClassDays.length} total scheduled',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedDates.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selectedDates.clear()),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDateFilterChip(_DateQuickFilter.all, 'All'),
            _buildDateFilterChip(_DateQuickFilter.recent30, 'Last 30d'),
            _buildDateFilterChip(_DateQuickFilter.recent90, 'Last 90d'),
            _buildDateFilterChip(_DateQuickFilter.thisYear, 'This Year'),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Header + Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Classes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  if (allVisibleSelected) {
                    _selectedDates.removeWhere(
                      (selected) => visibleDays
                          .any((visible) => _isSameDay(visible, selected)),
                    );
                  } else {
                    _selectedDates.addAll(visibleDays);
                  }
                });
              },
              icon: Icon(
                allVisibleSelected ? Icons.deselect : Icons.select_all,
                size: 18,
              ),
              label: Text(
                allVisibleSelected ? 'Deselect All' : 'Select All',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        if (_isLoadingDates)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_availableClassDays.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No class days found',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (visibleDays.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_alt_off, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No scheduled dates for this filter',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: visibleDays.length,
              itemBuilder: (context, index) {
                final date = visibleDays[index];
                final isSelected =
                    _selectedDates.any((d) => _isSameDay(d, date));
                final isToday = _isSameDay(date, DateTime.now());

                final dateKey = date.toIso8601String().split('T')[0];
                final existingStatuses = _existingStatusMap[dateKey];
                final hasHistory =
                    existingStatuses != null && existingStatuses.isNotEmpty;
                final existingStatus =
                    hasHistory ? existingStatuses.first : null;

                return InkWell(
                  onTap: () => _toggleDate(date),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .cardColor, // Replaced scaffoldBackgroundColor
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey
                                .withValues(alpha: 0.3), // More generic grey
                        width: isSelected ? 0 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('MMM d').format(date),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isToday
                                    ? 'Today'
                                    : DateFormat('EEEE').format(date),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.7),
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasHistory && !isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color:
                                    existingStatus == AttendanceStatus.present
                                        ? Colors.green
                                        : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        if (hasHistory && isSelected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                existingStatus == AttendanceStatus.present
                                    ? 'P'
                                    : 'A',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      existingStatus == AttendanceStatus.present
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: AppSpacing.md),
        _buildStatusSelector(),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewStep() {
    final selectedStudents = widget.allStudents
        .where((student) => _selectedStudentIds.contains(student.studentId))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final dates = _selectedDates.toList()..sort((a, b) => a.compareTo(b));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            icon: Icons.people_alt,
            title: 'Students selected',
            value: _selectedStudentIds.length.toString(),
            subtitle: 'Multi-select enabled',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSummaryCard(
            icon: Icons.calendar_today,
            title: 'Valid working days',
            value: dates.length.toString(),
            subtitle: 'Auto-filtered based on schedule',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSummaryCard(
            icon: Icons.fact_check,
            title: 'Status to mark',
            value: _selectedStatus == AttendanceStatus.present
                ? 'Present'
                : 'Absent',
            subtitle: 'Applies to every selection',
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildPreviewList('Students (${selectedStudents.length})',
              selectedStudents.map((s) => '${s.name} — ${s.regNo}').toList()),
          const SizedBox(height: AppSpacing.lg),
          _buildPreviewList('Dates (${dates.length})',
              dates.map((d) => DateFormat('EEE, MMM d').format(d)).toList()),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Total records that will be updated: ${selectedStudents.length * dates.length}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPreviewList(String title, List<String> items) {
    final visibleItems = items.take(5).toList();
    final remaining = items.length - visibleItems.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...visibleItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: Colors.grey),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                '+$remaining more',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionStats({bool showStudents = true}) {
    final students = _selectedStudentIds.length;
    final dates = _selectedDates.length;

    return Row(
      children: [
        if (showStudents)
          _buildBadge(
            label: 'Selected',
            value: students.toString(),
            icon: Icons.check_circle,
          )
        else
          _buildBadge(
            label: 'Days',
            value: dates.toString(),
            icon: Icons.calendar_today,
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            showStudents
                ? 'Select students to mark'
                : 'Tap days to toggle selection',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$value $label',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mark Attendance As',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusOption(
                  status: AttendanceStatus.present,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  label: 'Present',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusOption(
                  status: AttendanceStatus.absent,
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  label: 'Absent',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption({
    required AttendanceStatus status,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    final isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = status),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? color
                    : Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color
                        ?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    final canProceed = _currentStep == 0
        ? _selectedStudentIds.isNotEmpty
        : _currentStep == 1
            ? _selectedDates.isNotEmpty && !_isLoadingDates
            : true;

    return Row(
      children: [
        if (_currentStep > 0)
          TextButton.icon(
            onPressed:
                _isSaving ? null : () => setState(() => _currentStep -= 1),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Back'),
          ),
        if (_currentStep > 0) const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton(
            onPressed: !canProceed || _isSaving
                ? null
                : () async {
                    if (_currentStep < 2) {
                      setState(() {
                        _currentStep += 1;
                      });
                      return;
                    }
                    await _handleSave();
                  },
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(_currentStep < 2 ? 'Next' : 'Confirm & Save'),
          ),
        ),
      ],
    );
  }

  void _toggleStudent(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
    });

    if (_availableClassDays.isNotEmpty) {
      _loadExistingAttendance();
    }
  }

  void _toggleDate(DateTime date) {
    setState(() {
      final existing =
          _selectedDates.where((d) => _isSameDay(d, date)).firstOrNull;

      if (existing != null) {
        _selectedDates.remove(existing);
      } else {
        _selectedDates.add(date);
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DateTime> get _visibleClassDays {
    if (_availableClassDays.isEmpty) return const [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime? cutoff = switch (_dateQuickFilter) {
      _DateQuickFilter.all => null,
      _DateQuickFilter.recent30 => today.subtract(const Duration(days: 30)),
      _DateQuickFilter.recent90 => today.subtract(const Duration(days: 90)),
      _DateQuickFilter.thisYear => DateTime(today.year, 1, 1),
    };

    final filtered = _availableClassDays.where((day) {
      if (cutoff == null) return true;
      return !day.isBefore(cutoff);
    }).toList();

    filtered.sort((a, b) => b.compareTo(a));
    return filtered;
  }

  Widget _buildDateFilterChip(_DateQuickFilter filter, String label) {
    final isSelected = _dateQuickFilter == filter;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        setState(() {
          _dateQuickFilter = filter;
        });
      },
      labelStyle: GoogleFonts.inter(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final result = await _attendanceService.markAttendanceForIndividuals(
        studentIds: _selectedStudentIds.toList(),
        dates: _selectedDates.toList(),
        status: _selectedStatus,
        markedBy: widget.markedBy,
        studentTeamMap: _studentTeamMap,
      );

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save attendance: $e')),
      );
    }
  }
}
