import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/daily_task.dart';
import '../models/audit_log.dart';

class TaskUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========================================
  // SINGLE TASK OPERATIONS
  // ========================================

  Future<DailyTask> createTask({
    required DateTime date,
    required TopicType topicType,
    required String title,
    String? referenceLink,
    String? subject,
    required String uploadedBy,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      
      final response = await _supabase
          .from('daily_tasks')
          .insert({
            'date': dateString,
            'topic_type': topicType.name,
            'title': title,
            'reference_link': referenceLink,
            'subject': subject,
            'uploaded_by': uploadedBy,
          })
          .select()
          .single();

      return DailyTask.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create task: ${e.toString()}');
    }
  }

  Future<List<DailyTask>> getTasksForDate(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      
      final response = await _supabase
          .from('daily_tasks')
          .select()
          .eq('date', dateString)
          .order('topic_type');

      return (response as List)
          .map((data) => DailyTask.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tasks: ${e.toString()}');
    }
  }

  Future<List<DailyTask>> getTasksInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startString = startDate.toIso8601String().split('T')[0];
      final endString = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('daily_tasks')
          .select()
          .gte('date', startString)
          .lte('date', endString)
          .order('date', ascending: false);

      return (response as List)
          .map((data) => DailyTask.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tasks in range: ${e.toString()}');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase
          .from('daily_tasks')
          .delete()
          .eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to delete task: ${e.toString()}');
    }
  }

  // ========================================
  // BULK UPLOAD - CSV/XLSX PARSING
  // ========================================

  Future<List<TaskUploadSheet>> parseUploadFile({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      if (fileName.endsWith('.csv')) {
        return await _parseCsvFile(fileBytes);
      } else if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
        return await _parseExcelFile(fileBytes);
      } else {
        throw Exception('Unsupported file format. Use CSV or XLSX.');
      }
    } catch (e) {
      throw Exception('Failed to parse file: ${e.toString()}');
    }
  }

  Future<List<TaskUploadSheet>> _parseCsvFile(Uint8List fileBytes) async {
    try {
      final csvString = String.fromCharCodes(fileBytes);
      final rows = const CsvToListConverter().convert(csvString);

      if (rows.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Simple CSV format: Date, Type, Title, Link/Subject
      final taskRows = <TaskUploadRow>[];

      for (var i = 1; i < rows.length; i++) {
        // Skip header
        final row = rows[i];
        if (row.length < 3) continue;

        try {
          final date = _parseDate(row[0].toString());
          final typeString = row[1].toString().toLowerCase();
          final title = row[2].toString();
          final linkOrSubject = row.length > 3 ? row[3].toString() : null;

          final topicType = typeString.contains('leet')
              ? TopicType.leetcode
              : TopicType.core;

          taskRows.add(TaskUploadRow(
            date: date,
            title: title,
            referenceLink: topicType == TopicType.leetcode ? linkOrSubject : null,
            subject: topicType == TopicType.core ? linkOrSubject : null,
            topicType: topicType,
          ));
        } catch (e) {
          taskRows.add(TaskUploadRow(
            date: DateTime.now(),
            title: 'Error',
            topicType: TopicType.core,
            error: 'Row ${i + 1}: ${e.toString()}',
          ));
        }
      }

      return [
        TaskUploadSheet(
          sheetName: 'CSV Import',
          topicType: TopicType.core,
          rows: taskRows,
        ),
      ];
    } catch (e) {
      throw Exception('CSV parsing error: ${e.toString()}');
    }
  }

  Future<List<TaskUploadSheet>> _parseExcelFile(Uint8List fileBytes) async {
    try {
      final excel = Excel.decodeBytes(fileBytes);
      final sheets = <TaskUploadSheet>[];

      for (final sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName];
        if (sheet == null) continue;

        final topicType = _detectTopicType(sheetName);
        final rows = <TaskUploadRow>[];

        // Expected columns for LeetCode: Date, Topic, Question (URL)
        // Expected columns for Core: Date, Subject, Topic

        for (var i = 1; i < sheet.rows.length; i++) {
          // Skip header
          final row = sheet.rows[i];
          if (row.isEmpty) continue;

          try {
            final date = _parseDate(row[0]?.value?.toString() ?? '');
            
            if (topicType == TopicType.leetcode) {
              // LeetCode format
              final topic = row.length > 1 ? row[1]?.value?.toString() : null;
              final url = row.length > 2 ? row[2]?.value?.toString() : null;

              if (topic == null || topic.isEmpty) {
                throw Exception('Missing topic');
              }

              rows.add(TaskUploadRow(
                date: date,
                title: topic,
                referenceLink: url,
                topicType: TopicType.leetcode,
              ));
            } else {
              // Core format
              final subject = row.length > 1 ? row[1]?.value?.toString() : null;
              final topic = row.length > 2 ? row[2]?.value?.toString() : null;

              if (subject == null || subject.isEmpty || topic == null || topic.isEmpty) {
                throw Exception('Missing subject or topic');
              }

              rows.add(TaskUploadRow(
                date: date,
                title: topic,
                subject: subject,
                topicType: TopicType.core,
              ));
            }
          } catch (e) {
            rows.add(TaskUploadRow(
              date: DateTime.now(),
              title: 'Error',
              topicType: topicType,
              error: 'Sheet "$sheetName", Row ${i + 1}: ${e.toString()}',
            ));
          }
        }

        sheets.add(TaskUploadSheet(
          sheetName: sheetName,
          topicType: topicType,
          rows: rows,
        ));
      }

      return sheets;
    } catch (e) {
      throw Exception('Excel parsing error: ${e.toString()}');
    }
  }

  TopicType _detectTopicType(String sheetName) {
    final lower = sheetName.toLowerCase();
    if (lower.contains('leet') || lower.contains('question')) {
      return TopicType.leetcode;
    }
    return TopicType.core;
  }

  DateTime _parseDate(String dateString) {
    try {
      // Try various date formats
      // ISO format: 2024-01-15
      if (dateString.contains('-')) {
        return DateTime.parse(dateString);
      }
      
      // DD/MM/YYYY
      if (dateString.contains('/')) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }

      throw Exception('Invalid date format');
    } catch (e) {
      throw Exception('Invalid date: $dateString');
    }
  }

  // ========================================
  // BULK UPLOAD EXECUTION
  // ========================================

  Future<BulkUploadResult> uploadTasks({
    required List<TaskUploadSheet> sheets,
    required String uploadedBy,
    required String fileName,
  }) async {
    int successCount = 0;
    int errorCount = 0;
    final errors = <String>[];

    try {
      for (final sheet in sheets) {
        for (final row in sheet.rows) {
          if (!row.isValid) {
            errorCount++;
            errors.add(row.error ?? 'Unknown error');
            continue;
          }

          try {
            await createTask(
              date: row.date,
              topicType: row.topicType,
              title: row.title,
              referenceLink: row.referenceLink,
              subject: row.subject,
              uploadedBy: uploadedBy,
            );
            successCount++;
          } catch (e) {
            errorCount++;
            errors.add('Failed to upload "${row.title}": ${e.toString()}');
          }
        }
      }

      // Create audit log
      final auditLog = AuditLog.createBulkTaskUpload(
        actorId: uploadedBy,
        taskCount: successCount,
        fileName: fileName,
      );

      await _createAuditLog(auditLog);

      return BulkUploadResult(
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );
    } catch (e) {
      throw Exception('Bulk upload failed: ${e.toString()}');
    }
  }

  Future<void> _createAuditLog(AuditLog log) async {
    try {
      await _supabase.from('audit_logs').insert(log.toMap());
    } catch (e) {
      print('Failed to create audit log: $e');
    }
  }

  // ========================================
  // TEMPLATE GENERATION
  // ========================================

  List<List<String>> generateLeetCodeTemplate() {
    return [
      ['Date', 'Topic', 'Question URL'],
      ['2026-01-23', 'Two Sum', 'https://leetcode.com/problems/two-sum/'],
      ['2026-01-24', 'Add Two Numbers', 'https://leetcode.com/problems/add-two-numbers/'],
    ];
  }

  List<List<String>> generateCoreTopicTemplate() {
    return [
      ['Date', 'Subject', 'Topic'],
      ['2026-01-23', 'Data Structures', 'Binary Search Trees'],
      ['2026-01-24', 'Algorithms', 'Dynamic Programming'],
    ];
  }

  Uint8List generateExcelTemplate() {
    final excel = Excel.createExcel();

    // LeetCode Questions sheet
    final leetSheet = excel['LeetCode Questions'];
    leetSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Topic'),
      TextCellValue('Question URL'),
    ]);
    leetSheet.appendRow([
      TextCellValue('2026-01-23'),
      TextCellValue('Two Sum'),
      TextCellValue('https://leetcode.com/problems/two-sum/'),
    ]);

    // General Topics sheet
    final coreSheet = excel['General Topics'];
    coreSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Subject'),
      TextCellValue('Topic'),
    ]);
    coreSheet.appendRow([
      TextCellValue('2026-01-23'),
      TextCellValue('Data Structures'),
      TextCellValue('Binary Search Trees'),
    ]);

    // Remove default sheet
    excel.delete('Sheet1');

    return Uint8List.fromList(excel.encode()!);
  }
}

class BulkUploadResult {
  final int successCount;
  final int errorCount;
  final List<String> errors;

  BulkUploadResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });

  bool get hasErrors => errorCount > 0;
  bool get isSuccess => successCount > 0;
}
