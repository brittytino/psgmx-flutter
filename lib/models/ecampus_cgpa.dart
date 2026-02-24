/// Per-semester SGPA entry.
class SemesterSgpa {
  final String semester;
  final double sgpa;

  const SemesterSgpa({required this.semester, required this.sgpa});

  factory SemesterSgpa.fromJson(Map<String, dynamic> json) {
    return SemesterSgpa(
      semester: json['semester'] as String? ?? '',
      sgpa: (json['sgpa'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Individual course result entry.
class CourseResult {
  final String semester;
  final String code;
  final String title;
  final int credits;
  final String grade;
  final String result;

  const CourseResult({
    required this.semester,
    required this.code,
    required this.title,
    required this.credits,
    required this.grade,
    required this.result,
  });

  factory CourseResult.fromJson(Map<String, dynamic> json) {
    return CourseResult(
      semester: json['semester'] as String? ?? '',
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      grade: json['grade'] as String? ?? '',
      result: json['result'] as String? ?? '',
    );
  }

  bool get isPassed {
    const failGrades = {'RA', 'SA', 'W', ''};
    return !failGrades.contains(grade.toUpperCase());
  }
}

/// Top-level model for CGPA payload stored in Supabase.
class EcampusCgpa {
  final String regNo;
  final double cgpa;
  final int totalCredits;
  final String latestSemester;
  final int totalSemesters;
  final List<SemesterSgpa> semesterSgpa;
  final List<CourseResult> courses;
  final DateTime syncedAt;

  const EcampusCgpa({
    required this.regNo,
    required this.cgpa,
    required this.totalCredits,
    required this.latestSemester,
    required this.totalSemesters,
    required this.semesterSgpa,
    required this.courses,
    required this.syncedAt,
  });

  factory EcampusCgpa.fromSupabase(Map<String, dynamic> row) {
    final data = row['data'] as Map<String, dynamic>;
    final syncedAtRaw = row['synced_at'] as String? ?? '';

    return EcampusCgpa(
      regNo: row['reg_no'] as String? ?? '',
      cgpa: (data['cgpa'] as num?)?.toDouble() ?? 0.0,
      totalCredits: (data['total_credits'] as num?)?.toInt() ?? 0,
      latestSemester: data['latest_semester'] as String? ?? '',
      totalSemesters: (data['total_semesters'] as num?)?.toInt() ?? 0,
      semesterSgpa: (data['semester_sgpa'] as List<dynamic>? ?? [])
          .map((e) => SemesterSgpa.fromJson(e as Map<String, dynamic>))
          .toList(),
      courses: (data['courses'] as List<dynamic>? ?? [])
          .map((e) => CourseResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      syncedAt: syncedAtRaw.isNotEmpty
          ? DateTime.tryParse(syncedAtRaw) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Courses grouped by semester (sorted ascending).
  Map<String, List<CourseResult>> get coursesBySemester {
    final map = <String, List<CourseResult>>{};
    for (final c in courses) {
      map.putIfAbsent(c.semester, () => []).add(c);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}
