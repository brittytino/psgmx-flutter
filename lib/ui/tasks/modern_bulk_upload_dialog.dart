import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/task_upload_service.dart';

class ModernBulkUploadDialog extends StatefulWidget {
  const ModernBulkUploadDialog({super.key});

  @override
  State<ModernBulkUploadDialog> createState() => _ModernBulkUploadDialogState();
}

class _ModernBulkUploadDialogState extends State<ModernBulkUploadDialog> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.file_upload_outlined,
                      color: colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulk Task Upload',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Upload multiple tasks at once',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Format Info Card
                    _FormatInfoCard(),
                    
                    const SizedBox(height: 24),

                    // Download Template Button
                    OutlinedButton.icon(
                      onPressed: _downloadTemplate,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Download Excel Template'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colorScheme.primary),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // File Picker
                    _selectedFile == null
                        ? _FilePickerArea(
                            onFilePicked: (file) {
                              setState(() {
                                _selectedFile = file;
                                _errorMessage = null;
                              });
                            },
                          )
                        : _SelectedFileCard(
                            file: _selectedFile!,
                            onRemove: () {
                              setState(() {
                                _selectedFile = null;
                                _errorMessage = null;
                              });
                            },
                          ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: colorScheme.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                  color: colorScheme.onErrorContainer,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUploading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _selectedFile != null && !_isUploading
                          ? () => _showConfirmationDialog(context, userProvider)
                          : null,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(_isUploading ? 'Uploading...' : 'Upload Tasks'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadTemplate() async {
    try {
      final uploadService = TaskUploadService();
      final templateBytes = uploadService.generateExcelTemplate();

      // Save template
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel Template',
        fileName: 'PSGMX_Task_Upload_Template.xlsx',
        bytes: templateBytes,
      );

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template downloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download template: $e')),
        );
      }
    }
  }

  void _showConfirmationDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Confirm Upload',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to upload these tasks?',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.insert_drive_file_outlined,
                    label: 'File:',
                    value: _selectedFile!.name,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.info_outline,
                    label: 'Note:',
                    value: 'Existing tasks for the same date will be updated',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadFile(userProvider);
            },
            child: const Text('Confirm Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadFile(UserProvider userProvider) async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final uploadService = TaskUploadService();
      
      // Get file bytes from PlatformFile
      final fileBytes = _selectedFile!.bytes;
      if (fileBytes == null) {
        throw Exception('Could not read file data');
      }

      // Parse file
      final sheets = await uploadService.parseUploadFile(
        fileBytes: fileBytes,
        fileName: _selectedFile!.name,
      );

      // Upload tasks
      final result = await uploadService.uploadTasks(
        sheets: sheets,
        uploadedBy: userProvider.currentUser!.uid,
        fileName: _selectedFile!.name,
      );

      if (!mounted) return;

      if (result.hasErrors) {
        _showResultDialog(
          context,
          'Upload Completed with Errors',
          'Successfully uploaded ${result.successCount} tasks\n'
          'Failed: ${result.errorCount}\n\n'
          'Errors:\n${result.errors.join('\n')}',
          isError: true,
        );
      } else {
        Navigator.pop(context, true); // Close dialog and refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully uploaded ${result.successCount} tasks'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showResultDialog(
    BuildContext context,
    String title,
    String message, {
    bool isError = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isError ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: isError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!isError) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _FormatInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Excel File Format',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your Excel file must have this format:',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _FormatRow(
            columns: ['Date', 'Leetcode Topic', 'Leetcode URL', 'Core CS Topic', 'Description'],
          ),
          const SizedBox(height: 8),
          Text(
            '• Date format: YYYY-MM-DD (e.g., 2026-01-29)\n'
            '• Leave Leetcode or Core CS columns empty if not applicable\n'
            '• One task per day for each type (Leetcode & Core CS)',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatRow extends StatelessWidget {
  final List<String> columns;

  const _FormatRow({required this.columns});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: columns.map((col) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              col,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilePickerArea extends StatelessWidget {
  final Function(PlatformFile) onFilePicked;

  const _FilePickerArea({required this.onFilePicked});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _pickFile(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outline,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Click to select Excel file',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Only .xlsx and .xls files',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        onFilePicked(result.files.first);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }
}

class _SelectedFileCard extends StatelessWidget {
  final PlatformFile file;
  final VoidCallback onRemove;

  const _SelectedFileCard({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              color: colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(file.size / 1024).toStringAsFixed(2)} KB',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close, color: colorScheme.error),
            tooltip: 'Remove file',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
