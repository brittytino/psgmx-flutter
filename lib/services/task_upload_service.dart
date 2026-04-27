import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
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

      return (response as List).map((data) => DailyTask.fromMap(data)).toList();
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

      return (response as List).map((data) => DailyTask.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to get tasks in range: ${e.toString()}');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('daily_tasks').delete().eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to delete task: ${e.toString()}');
    }
  }

  // ========================================
  // BULK UPLOAD - CSV/XLSX PARSING
  // ========================================

  /// Parse Excel file with proper error handling
  Future<List<TaskUploadSheet>> parseExcelFile(
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final normalizedFileName = fileName.toLowerCase();

      if (fileBytes.isEmpty) {
        throw Exception('File is empty or could not be read');
      }

      if (normalizedFileName.endsWith('.csv')) {
        return await _parseCsvFile(fileBytes);
      } else if (normalizedFileName.endsWith('.xlsx') ||
          normalizedFileName.endsWith('.xls')) {
        return await _parseExcelFile(fileBytes);
      } else {
        throw Exception('Unsupported file format. Use CSV or XLSX.');
      }
    } catch (e) {
      throw Exception('Failed to parse file: ${e.toString()}');
    }
  }

  Future<List<TaskUploadSheet>> parseUploadFile({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    return parseExcelFile(fileBytes, fileName);
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

          final topicType =
              typeString.contains('leet') ? TopicType.leetcode : TopicType.core;

          taskRows.add(TaskUploadRow(
            date: date,
            title: title,
            referenceLink:
                topicType == TopicType.leetcode ? linkOrSubject : null,
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

      final rows = sheet.rows
          .map((row) => row
              .map((cell) => (cell?.value?.toString() ?? '').trim())
              .toList())
          .toList();

      return _buildSheetsFromRows(rows);
    } catch (primaryError) {
      // Some XLSX files (especially from Google Sheets exports) can trigger
      // parser internals to throw null-check errors. Fallback to raw XML parse.
      debugPrint(
        '[TaskUploadService] Primary Excel parser failed, trying XML fallback: $primaryError',
      );

      try {
        final rows = _readXlsxRowsFallback(fileBytes);
        return _buildSheetsFromRows(rows);
      } catch (fallbackError) {
        throw Exception(
          'Excel parsing error: ${primaryError.toString()} (fallback failed: ${fallbackError.toString()})',
        );
      }
    }
  }

  List<TaskUploadSheet> _buildSheetsFromRows(List<List<String>> rows) {
    final leetCodeRows = <TaskUploadRow>[];
    final coreRows = <TaskUploadRow>[];

    // Expected columns: Date, Leetcode Topic, Leetcode URL, Core CS Topic, Description
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || _isRowEmpty(row)) continue;

      try {
        final dateStr = _getCell(row, 0);
        if (dateStr.isEmpty) continue;

        final date = _parseDate(dateStr);
        final leetcodeTopic = _getCell(row, 1);
        final leetcodeUrl = _getCell(row, 2);
        final coreSubject = _getCell(row, 3);
        final description = _getCell(row, 4);

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
  }

  List<List<String>> _readXlsxRowsFallback(Uint8List fileBytes) {
    final archive = ZipDecoder().decodeBytes(fileBytes);

    final workbookFile = archive.findFile('xl/workbook.xml');
    if (workbookFile == null) {
      throw Exception('Invalid workbook.xml in XLSX');
    }

    final workbookDoc = XmlDocument.parse(
      utf8.decode(_archiveFileBytes(workbookFile)),
    );

    final firstWorksheetPath =
        _resolveFirstWorksheetPath(archive, workbookDoc) ??
            _findFirstWorksheetPath(archive);

    if (firstWorksheetPath == null) {
      throw Exception('No worksheet found in XLSX');
    }

    final worksheetFile = archive.findFile(firstWorksheetPath);
    if (worksheetFile == null) {
      throw Exception('Worksheet not found: $firstWorksheetPath');
    }

    final sharedStrings = _readSharedStrings(archive);
    final worksheetDoc = XmlDocument.parse(
      utf8.decode(_archiveFileBytes(worksheetFile)),
    );

    final rows = <List<String>>[];
    for (final rowElement in worksheetDoc.findAllElements('row')) {
      final rowValues = <int, String>{};

      for (final cell in rowElement.findElements('c')) {
        final cellRef = cell.getAttribute('r') ?? '';
        final colIndex = _columnIndexFromCellReference(cellRef);
        if (colIndex < 0) continue;

        rowValues[colIndex] = _readCellValue(cell, sharedStrings).trim();
      }

      if (rowValues.isEmpty) {
        rows.add(const <String>[]);
        continue;
      }

      final maxCol = rowValues.keys.reduce((a, b) => a > b ? a : b);
      final row = List<String>.filled(maxCol + 1, '');
      rowValues.forEach((index, value) {
        row[index] = value;
      });
      rows.add(row);
    }

    return rows;
  }

  String? _resolveFirstWorksheetPath(Archive archive, XmlDocument workbookDoc) {
    final sheets = workbookDoc.findAllElements('sheet');
    if (sheets.isEmpty) return null;

    final firstSheet = sheets.first;
    final relId = firstSheet.getAttribute('r:id') ??
        firstSheet.getAttribute(
          'id',
          namespace:
              'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
        );

    if (relId == null || relId.isEmpty) return null;

    final relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
    if (relsFile == null) return null;

    final relsDoc = XmlDocument.parse(utf8.decode(_archiveFileBytes(relsFile)));
    for (final relation in relsDoc.findAllElements('Relationship')) {
      if (relation.getAttribute('Id') == relId) {
        final target = relation.getAttribute('Target');
        if (target == null || target.isEmpty) return null;
        if (target.startsWith('/')) return target.substring(1);
        if (target.startsWith('xl/')) return target;
        return 'xl/$target';
      }
    }

    return null;
  }

  String? _findFirstWorksheetPath(Archive archive) {
    final worksheetFiles = archive.files
        .where(
          (f) =>
              f.isFile &&
              f.name.startsWith('xl/worksheets/') &&
              f.name.endsWith('.xml'),
        )
        .map((f) => f.name)
        .toList()
      ..sort();

    if (worksheetFiles.isEmpty) return null;
    return worksheetFiles.first;
  }

  List<String> _readSharedStrings(Archive archive) {
    final file = archive.findFile('xl/sharedStrings.xml');
    if (file == null) return const <String>[];

    final doc = XmlDocument.parse(utf8.decode(_archiveFileBytes(file)));
    final values = <String>[];

    for (final si in doc.findAllElements('si')) {
      final text = si.findAllElements('t').map((t) => t.innerText).join();
      values.add(text);
    }

    return values;
  }

  List<int> _archiveFileBytes(ArchiveFile file) {
    final content = file.content;
    if (content is List<int>) {
      return content;
    }
    throw Exception('Unsupported archive file content: ${file.name}');
  }

  String _readCellValue(XmlElement cell, List<String> sharedStrings) {
    final type = cell.getAttribute('t');

    if (type == 'inlineStr') {
      return cell.findAllElements('t').map((t) => t.innerText).join();
    }

    final rawValue = cell.getElement('v')?.innerText ?? '';
    if (rawValue.isEmpty) return '';

    if (type == 's') {
      final sharedIndex = int.tryParse(rawValue);
      if (sharedIndex != null &&
          sharedIndex >= 0 &&
          sharedIndex < sharedStrings.length) {
        return sharedStrings[sharedIndex];
      }
      return '';
    }

    if (type == 'b') {
      return rawValue == '1' ? 'TRUE' : 'FALSE';
    }

    return rawValue;
  }

  int _columnIndexFromCellReference(String reference) {
    if (reference.isEmpty) return -1;

    final match = RegExp(r'([A-Z]+)').firstMatch(reference.toUpperCase());
    if (match == null) return -1;

    final colName = match.group(1)!;
    var index = 0;
    for (var i = 0; i < colName.length; i++) {
      index = (index * 26) + (colName.codeUnitAt(i) - 64);
    }
    return index - 1;
  }

  bool _isRowEmpty(List<String> row) {
    for (final value in row) {
      if (value.trim().isNotEmpty) return false;
    }
    return true;
  }

  String _getCell(List<String> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return row[index].trim();
  }

  DateTime _parseDate(String dateString) {
    try {
      final input = dateString.trim();
      if (input.isEmpty) {
        throw Exception('Empty date');
      }

      // Excel serial date (e.g., 45321 / 45321.0)
      final serial = double.tryParse(input);
      if (serial != null) {
        final baseDate = DateTime(1899, 12, 30);
        final parsed = baseDate.add(Duration(days: serial.floor()));
        return DateTime(parsed.year, parsed.month, parsed.day);
      }

      final isoParsed = DateTime.tryParse(input);
      if (isoParsed != null) {
        return DateTime(isoParsed.year, isoParsed.month, isoParsed.day);
      }

      final formats = <String>[
        'yyyy-MM-dd',
        'dd/MM/yyyy',
        'd/M/yyyy',
        'MM/dd/yyyy',
        'M/d/yyyy',
        'd MMM yyyy',
        'dd MMM yyyy',
        'd MMMM yyyy',
        'dd MMMM yyyy',
      ];

      for (final format in formats) {
        try {
          final parsed = DateFormat(format).parseStrict(input);
          return DateTime(parsed.year, parsed.month, parsed.day);
        } catch (_) {
          // Try next known format
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
            errors.add(
                'Duplicate Date detected: $dateKey (${row.topicType.name}). Removed from batch.');
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
      [
        '2026-01-24',
        'Add Two Numbers',
        'https://leetcode.com/problems/add-two-numbers/'
      ],
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
