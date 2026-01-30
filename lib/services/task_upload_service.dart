import 'package:flutter/foundation.dart';
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
          .upsert({ 
            'date': dateString,
            'topic_type': topicType.name,
            'title': title,
            'reference_link': referenceLink,
            'subject': subject,
            'uploaded_by': uploadedBy,
          }, onConflict: 'date, topic_type') // Enforce One Per Type Per Day
          .select()
          .single();

      return DailyTask.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create/update task: ${e.toString()}');
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
      
      // Use the first sheet only (unified format)
      final firstSheetName = excel.tables.keys.first;
      final sheet = excel.tables[firstSheetName];
      
      if (sheet == null) {
        throw Exception('No valid sheet found');
      }

      final leetCodeRows = <TaskUploadRow>[];
      final coreRows = <TaskUploadRow>[];

      // Expected columns: Date, Leetcode Topic, Leetcode URL, Core CS Topic, Description
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        try {
          final dateStr = row[0]?.value?.toString() ?? '';
          if (dateStr.isEmpty) continue;
          
          final date = _parseDate(dateStr);
          final leetcodeTopic = row.length > 1 ? (row[1]?.value?.toString() ?? '').trim() : '';
          final leetcodeUrl = row.length > 2 ? (row[2]?.value?.toString() ?? '').trim() : '';
          final coreSubject = row.length > 3 ? (row[3]?.value?.toString() ?? '').trim() : '';
          final description = row.length > 4 ? (row[4]?.value?.toString() ?? '').trim() : '';

          // Add LeetCode task if topic is present
          if (leetcodeTopic.isNotEmpty) {
            leetCodeRows.add(TaskUploadRow(
              date: date,
              title: leetcodeTopic,
              referenceLink: leetcodeUrl.isNotEmpty ? leetcodeUrl : null,
              topicType: TopicType.leetcode,
            ));
          }

          // Add Core CS task if subject is present
          if (coreSubject.isNotEmpty) {
            coreRows.add(TaskUploadRow(
              date: date,
              title: description.isNotEmpty ? description : coreSubject,
              subject: coreSubject,
              topicType: TopicType.core,
            ));
          }
        } catch (e) {
          // Add error row to both sheets to maintain visibility
          final errorRow = TaskUploadRow(
            date: DateTime.now(),
            title: 'Error',
            topicType: TopicType.core,
            error: 'Row ${i + 1}: ${e.toString()}',
          );
          leetCodeRows.add(errorRow);
          coreRows.add(errorRow);
        }
      }

      final sheets = <TaskUploadSheet>[];
      
      if (leetCodeRows.isNotEmpty) {
        sheets.add(TaskUploadSheet(
          sheetName: 'LeetCode Tasks',
          topicType: TopicType.leetcode,
          rows: leetCodeRows,
        ));
      }
      
      if (coreRows.isNotEmpty) {
        sheets.add(TaskUploadSheet(
          sheetName: 'Core CS Tasks',
          topicType: TopicType.core,
          rows: coreRows,
        ));
      }

      if (sheets.isEmpty) {
        throw Exception('No valid tasks found in the file');
      }

      return sheets;
    } catch (e) {
      throw Exception('Excel parsing error: ${e.toString()}');
    }
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
    
    // Deduplication Set: key = "YYYY-MM-DD_TOPIC"
    final Set<String> processedKeys = {};
    final List<TaskUploadRow> uniqueRows = [];

    // 1. Client-Side Deduplication & Validation
    try {
      for (final sheet in sheets) {
        for (final row in sheet.rows) {
          if (!row.isValid) {
            errorCount++;
            errors.add(row.error ?? 'Unknown error');
            continue;
          }

          final dateKey = row.date.toIso8601String().split('T')[0];
          final uniqueKey = '${dateKey}_${row.topicType.name}';

          if (processedKeys.contains(uniqueKey)) {
             errorCount++;
             errors.add('Duplicate Date detected: $dateKey (${row.topicType.name}). Removed from batch.');
             continue; // Skip duplicate
          }
          
          processedKeys.add(uniqueKey);
          uniqueRows.add(row);
        }
      }
      
      // 2. Process Unique Rows
      for (final row in uniqueRows) {
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
      debugPrint('Failed to create audit log: $e');
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

    // Single unified sheet
    final sheet = excel['Tasks'];
    
    // Header row
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Leetcode Topic'),
      TextCellValue('Leetcode URL'),
      TextCellValue('Core CS Topic'),
      TextCellValue('Description'),
    ]);
    
    // Example rows
    sheet.appendRow([
      TextCellValue('2026-01-29'),
      TextCellValue('Two Sum'),
      TextCellValue('https://leetcode.com/problems/two-sum/'),
      TextCellValue('Binary Search Trees'),
      TextCellValue('Understanding BST operations and traversals'),
    ]);
    
    sheet.appendRow([
      TextCellValue('2026-01-30'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('Dynamic Programming'),
      TextCellValue('Introduction to DP with memoization'),
    ]);
    
    sheet.appendRow([
      TextCellValue('2026-01-31'),
      TextCellValue('Valid Parentheses'),
      TextCellValue('https://leetcode.com/problems/valid-parentheses/'),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    // Remove default sheet
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

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
