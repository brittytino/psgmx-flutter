/// CA test timetable for a single student.
class EcampusCaTimetable {
  final String regNo;
  final List<String> headers;
  final List<Map<String, String>> rows;
  final String? note;
  final DateTime syncedAt;

  const EcampusCaTimetable({
    required this.regNo,
    required this.headers,
    required this.rows,
    this.note,
    required this.syncedAt,
  });

  bool get hasData => rows.isNotEmpty;

  factory EcampusCaTimetable.fromSupabase(Map<String, dynamic> row) {
    final data = row['data'] as Map<String, dynamic>? ?? {};
    final syncedAtRaw = row['synced_at'] as String? ?? '';

    final rawHeaders = (data['headers'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final rawRows = (data['rows'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
        .toList();

    return EcampusCaTimetable(
      regNo: row['reg_no'] as String? ?? '',
      headers: rawHeaders,
      rows: rawRows,
      note: data['note'] as String?,
      syncedAt: DateTime.tryParse(syncedAtRaw) ?? DateTime.now(),
    );
  }
}
