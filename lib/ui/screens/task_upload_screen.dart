import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/task_upload_service.dart';
import '../../services/enhanced_auth_service.dart';
import '../../models/daily_task.dart';

class TaskUploadScreen extends StatefulWidget {
  const TaskUploadScreen({super.key});

  @override
  State<TaskUploadScreen> createState() => _TaskUploadScreenState();
}

class _TaskUploadScreenState extends State<TaskUploadScreen> {
  bool _isLoading = false;
  List<TaskUploadSheet>? _parsedSheets;
  String? _fileName;
  Uint8List? _fileBytes;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<EnhancedAuthService>();
    final user = authService.effectiveUser;

    if (user == null || (!user.isPlacementRep && !user.isCoordinator)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Upload Tasks')),
        body: const Center(
          child: Text('Only Placement Reps and Coordinators can upload tasks'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Task Upload'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadTemplate,
            tooltip: 'Download Template',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parsedSheets == null
              ? _buildUploadArea()
              : _buildPreview(),
    );
  }

  Widget _buildUploadArea() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Upload CSV or XLSX File',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Drag & drop or click to select',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.file_upload),
              label: const Text('Select File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Format',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildFormatInfo(
                      'LeetCode Questions',
                      'Date | Topic | Question URL',
                    ),
                    const SizedBox(height: 8),
                    _buildFormatInfo(
                      'General Topics',
                      'Date | Subject | Topic',
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _downloadTemplate,
                      icon: const Icon(Icons.download),
                      label: const Text('Download Template'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatInfo(String title, String format) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          format,
          style: TextStyle(
            fontFamily: 'monospace',
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final totalRows = _parsedSheets!.fold<int>(
      0,
      (sum, sheet) => sum + sheet.rows.length,
    );
    final validRows = _parsedSheets!.fold<int>(
      0,
      (sum, sheet) => sum + sheet.validRowCount,
    );
    final errorRows = totalRows - validRows;

    return Column(
      children: [
        // Summary card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fileName ?? 'Unknown file',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    _buildSummaryStat('Total', totalRows.toString(), Colors.blue),
                    const SizedBox(width: 16),
                    _buildSummaryStat('Valid', validRows.toString(), Colors.green),
                    const SizedBox(width: 16),
                    _buildSummaryStat('Errors', errorRows.toString(), Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Sheet tabs and preview
        Expanded(
          child: DefaultTabController(
            length: _parsedSheets!.length,
            child: Column(
              children: [
                TabBar(
                  tabs: _parsedSheets!
                      .map((sheet) => Tab(text: sheet.sheetName))
                      .toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: _parsedSheets!
                        .map((sheet) => _buildSheetPreview(sheet))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Action buttons
        _buildActionBar(validRows, errorRows),
      ],
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSheetPreview(TaskUploadSheet sheet) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sheet.rows.length,
      itemBuilder: (context, index) {
        final row = sheet.rows[index];
        return Card(
          color: row.isValid ? null : Colors.red.shade50,
          child: ListTile(
            leading: Icon(
              row.isValid ? Icons.check_circle : Icons.error,
              color: row.isValid ? Colors.green : Colors.red,
            ),
            title: Text(row.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${_formatDate(row.date)}'),
                if (row.referenceLink != null) Text('Link: ${row.referenceLink}'),
                if (row.subject != null) Text('Subject: ${row.subject}'),
                if (!row.isValid)
                  Text(
                    'Error: ${row.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
            trailing: Chip(
              label: Text(row.topicType.displayName),
              labelStyle: const TextStyle(fontSize: 11),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBar(int validRows, int errorRows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
            ),
            const Spacer(),
            if (errorRows > 0)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$errorRows errors',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton.icon(
              onPressed: validRows > 0 ? _uploadTasks : null,
              icon: const Icon(Icons.cloud_upload),
              label: Text('Upload $validRows tasks'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (result == null) return;

      setState(() {
        _isLoading = true;
      });

      final file = result.files.first;
      _fileName = file.name;
      _fileBytes = file.bytes!;

      await _parseFile();
    } catch (e) {
      _showError('Failed to pick file: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _parseFile() async {
    try {
      final taskService = context.read<TaskUploadService>();

      final sheets = await taskService.parseUploadFile(
        fileBytes: _fileBytes!,
        fileName: _fileName!,
      );

      setState(() {
        _parsedSheets = sheets;
      });
    } catch (e) {
      _showError('Failed to parse file: $e');
      _reset();
    }
  }

  Future<void> _uploadTasks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Upload'),
        content: const Text('Are you sure you want to upload these tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<EnhancedAuthService>();
      final taskService = context.read<TaskUploadService>();
      final user = authService.currentUser!; // Use real user, not simulated

      final result = await taskService.uploadTasks(
        sheets: _parsedSheets!,
        uploadedBy: user.uid,
        fileName: _fileName!,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✓ ${result.successCount} tasks uploaded successfully'),
                if (result.hasErrors) ...[
                  const SizedBox(height: 8),
                  Text('✗ ${result.errorCount} tasks failed'),
                  const SizedBox(height: 8),
                  const Text('Errors:'),
                  ...result.errors.take(5).map((e) => Text('• $e')),
                  if (result.errors.length > 5)
                    Text('... and ${result.errors.length - 5} more'),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _reset();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      final taskService = context.read<TaskUploadService>();
      final template = taskService.generateExcelTemplate();

      // In a real app, you'd save this file
      // For now, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template generated (save functionality needed)'),
        ),
      );
    } catch (e) {
      _showError('Failed to generate template: $e');
    }
  }

  void _reset() {
    setState(() {
      _parsedSheets = null;
      _fileName = null;
      _fileBytes = null;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
