/// A single CA (Continuous Assessment) test result for one subject.
class CaTestResult {
  final String test; // e.g. "CA1" or "CA2"
  final double? marks;
  final double? maxMarks;
  final double? percentage;

  const CaTestResult({
    required this.test,
    this.marks,
    this.maxMarks,
    this.percentage,
  });

  factory CaTestResult.fromJson(Map<String, dynamic> json) {
    return CaTestResult(
      test: json['test'] as String? ?? '',
      marks: (json['marks'] as num?)?.toDouble(),
      maxMarks: (json['max_marks'] as num?)?.toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
    );
  }

  /// Colour-coded status based on percentage.
  CaMarkStatus get status {
    final p = percentage;
    if (p == null) return CaMarkStatus.pending;
    if (p >= 75) return CaMarkStatus.good;
    if (p >= 50) return CaMarkStatus.average;
    return CaMarkStatus.poor;
  }
}

enum CaMarkStatus { pending, good, average, poor }

/// CA marks for a single subject (may contain CA1 and/or CA2).
class CaSubject {
  final String courseCode;
  final String courseTitle;
  final List<CaTestResult> caTests;

  const CaSubject({
    required this.courseCode,
    required this.courseTitle,
    required this.caTests,
  });

  factory CaSubject.fromJson(Map<String, dynamic> json) {
    return CaSubject(
      courseCode: json['course_code'] as String? ?? '',
      courseTitle: json['course_title'] as String? ?? '',
      caTests: (json['ca_tests'] as List<dynamic>? ?? [])
          .map((e) => CaTestResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Returns the CA1 test result if available.
  CaTestResult? get ca1 =>
      caTests.where((t) => t.test == 'CA1').firstOrNull;

  /// Returns the CA2 test result if available.
  CaTestResult? get ca2 =>
      caTests.where((t) => t.test == 'CA2').firstOrNull;

  /// Average percentage across all available tests.
  double? get averagePercentage {
    final valid = caTests
        .where((t) => t.percentage != null)
        .map((t) => t.percentage!)
        .toList();
    if (valid.isEmpty) return null;
    return valid.reduce((a, b) => a + b) / valid.length;
  }
}

/// Top-level model for the CA marks payload stored in Supabase.
class EcampusCaMarks {
  final String regNo;
  final List<CaSubject> subjects;
  /// Backend note, e.g. "CA marks not published yet".
  final String? note;
  final DateTime syncedAt;

  const EcampusCaMarks({
    required this.regNo,
    required this.subjects,
    this.note,
    required this.syncedAt,
  });

  bool get hasData => subjects.isNotEmpty;

  factory EcampusCaMarks.fromSupabase(Map<String, dynamic> row) {
    final data = row['data'] as Map<String, dynamic>? ?? {};
    final syncedAtRaw = row['synced_at'] as String? ?? '';

    return EcampusCaMarks(
      regNo: row['reg_no'] as String? ?? '',
      subjects: (data['subjects'] as List<dynamic>? ?? [])
          .map((e) => CaSubject.fromJson(e as Map<String, dynamic>))
          .where((s) => s.courseCode.isNotEmpty)
          .toList(),
      note: data['note'] as String?,
      syncedAt: DateTime.tryParse(syncedAtRaw) ?? DateTime.now(),
    );
  }
}
