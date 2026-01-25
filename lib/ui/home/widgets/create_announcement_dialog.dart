import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/announcement_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../core/theme/app_dimens.dart';

class CreateAnnouncementDialog extends StatefulWidget {
  const CreateAnnouncementDialog({super.key});

  @override
  State<CreateAnnouncementDialog> createState() => _CreateAnnouncementDialogState();
}

class _CreateAnnouncementDialogState extends State<CreateAnnouncementDialog> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _isPriority = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _msgCtrl.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final user = context.read<UserProvider>().currentUser;
      if (user == null) return;

      await context.read<AnnouncementProvider>().createAnnouncement(
        title: _titleCtrl.text.trim(),
        message: _msgCtrl.text.trim(),
        isPriority: _isPriority,
        expiry: null, // Dialog doesn't support expiry yet
      );
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Announcement'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _msgCtrl,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                hintText: 'Details about placement class...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: const Text('Priority Notification'),
              subtitle: const Text('Send push notification to all students'),
              value: _isPriority,
              onChanged: (v) => setState(() => _isPriority = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancel')
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : const Text('Post'),
        ),
      ],
    );
  }
}
