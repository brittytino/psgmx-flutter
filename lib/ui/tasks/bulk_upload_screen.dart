import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../providers/user_provider.dart';
import '../../services/task_upload_service.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/premium_card.dart';

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;
  bool _isUploading = false;
  String? _errorMessage;
  bool _uploadComplete = false;
  int _successCount = 0;
  int _errorCount = 0;
  List<String> _errors = [];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _uploadComplete
        ? _buildSuccessView()
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Format Instructions Card
                _buildFormatCard(colorScheme, isDark),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Download Template Button
                _buildDownloadButton(colorScheme),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // File Selection Area
                if (_selectedFile == null)
                  _buildFilePicker(colorScheme, isDark)
                else
                  _buildSelectedFile(colorScheme, isDark),
                
                // Error Message
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildErrorCard(),
                ],
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Upload Button
                if (_selectedFile != null && !_isUploading)
                  _buildUploadButton(colorScheme),
                
                if (_isUploading)
                  _buildUploadingIndicator(colorScheme),
              ],
            ),
          );
  }

  Widget _buildFormatCard(ColorScheme colorScheme, bool isDark) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Excel File Format',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your Excel file must have these columns:',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Column chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColumnChip('Date', colorScheme, true),
              _buildColumnChip('Leetcode Topic', colorScheme, false),
              _buildColumnChip('Leetcode URL', colorScheme, false),
              _buildColumnChip('Core CS Topic', colorScheme, false),
              _buildColumnChip('Description', colorScheme, false),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          
          _buildFormatRule('•  Date format: YYYY-MM-DD (e.g., 2026-01-29)', colorScheme),
          const SizedBox(height: 6),
          _buildFormatRule('•  Leave Leetcode or Core CS columns empty if not applicable', colorScheme),
          const SizedBox(height: 6),
          _buildFormatRule('•  One task per day for each type (Leetcode & Core CS)', colorScheme),
        ],
      ),
    );
  }

  Widget _buildColumnChip(String label, ColorScheme colorScheme, bool required) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: required 
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (required)
            const Icon(Icons.star, size: 10, color: Colors.orange),
          if (required) const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: required ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatRule(String text, ColorScheme colorScheme) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
    );
  }

  Widget _buildDownloadButton(ColorScheme colorScheme) {
    return OutlinedButton.icon(
      onPressed: _downloadTemplate,
      icon: const Icon(Icons.download_outlined, size: 20),
      label: const Text('Download Excel Template'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }

  Widget _buildFilePicker(ColorScheme colorScheme, bool isDark) {
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: isDark 
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : colorScheme.primaryContainer.withValues(alpha: 0.1),
          border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Click to select Excel file',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Only .xlsx and .xls files supported',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFile(ColorScheme colorScheme, bool isDark) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: colorScheme.onPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile!.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedFile = null;
                    _fileBytes = null;
                    _errorMessage = null;
                  });
                },
                icon: Icon(Icons.close, color: colorScheme.error),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'File ready to upload',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(ColorScheme colorScheme) {
    return FilledButton.icon(
      onPressed: _uploadTasks,
      icon: const Icon(Icons.cloud_upload_rounded),
      label: const Text('Upload Tasks'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildUploadingIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Uploading tasks...',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please wait',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Upload Complete!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            PremiumCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _buildStatRow(
                    'Successfully Uploaded',
                    _successCount.toString(),
                    Colors.green,
                  ),
                  if (_errorCount > 0) ...[
                    const SizedBox(height: 12),
                    _buildStatRow(
                      'Errors',
                      _errorCount.toString(),
                      Colors.red,
                    ),
                  ],
                ],
              ),
            ),
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _errors.map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _uploadComplete = false;
                        _selectedFile = null;
                        _fileBytes = null;
                        _successCount = 0;
                        _errorCount = 0;
                        _errors = [];
                      });
                    },
                    child: const Text('Upload More'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      // Reset state to show tasks tab or stay on success
                      setState(() {
                        _uploadComplete = false;
                        _selectedFile = null;
                        _fileBytes = null;
                        _successCount = 0;
                        _errorCount = 0;
                        _errors = [];
                      });
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Tasks uploaded successfully!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        withData: true, // Important: Get file bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check if bytes are available
        if (file.bytes == null) {
          setState(() {
            _errorMessage = 'Could not read file data. Please try again.';
          });
          return;
        }

        setState(() {
          _selectedFile = file;
          _fileBytes = file.bytes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick file: $e';
      });
    }
  }

  void _downloadTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template download feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _uploadTasks() async {
    if (_selectedFile == null || _fileBytes == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final uploadService = TaskUploadService();

      // Parse the Excel file using bytes
      final sheets = await uploadService.parseExcelFile(
        _fileBytes!,
        _selectedFile!.name,
      );

      // Upload tasks
      final result = await uploadService.uploadTasks(
        sheets: sheets,
        uploadedBy: userProvider.currentUser!.uid,
        fileName: _selectedFile!.name,
      );

      setState(() {
        _isUploading = false;
        _uploadComplete = true;
        _successCount = result.successCount;
        _errorCount = result.errorCount;
        _errors = result.errors;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString();
      });
    }
  }
}
