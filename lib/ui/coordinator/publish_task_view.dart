import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_attendance.dart';
import '../../services/firestore_service.dart';

class PublishTaskView extends StatefulWidget {
  const PublishTaskView({super.key});

  @override
  State<PublishTaskView> createState() => _PublishTaskViewState();
}

class _PublishTaskViewState extends State<PublishTaskView> {
  final _formKey = GlobalKey<FormState>();
  final _leetcodeCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    
    final task = DailyTask(
      date: dateStr,
      leetcodeUrl: _leetcodeCtrl.text.trim(),
      csTopic: _topicCtrl.text.trim(),
      csTopicDescription: _descCtrl.text.trim(),
      motivationQuote: "Auto-generated", // Or add field
    );

    try {
      await Provider.of<SupabaseDbService>(context, listen: false).publishDailyTask(task);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Published!')));
        // Clear form
        _leetcodeCtrl.clear();
        _topicCtrl.clear();
        _descCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
             Row(
               children: [
                 Text("Date: ${_selectedDate.toLocal().toString().split(' ')[0]}"),
                 const Spacer(),
                 TextButton(onPressed: () async {
                   final d = await showDatePicker(context: context, firstDate: DateTime(2025), lastDate: DateTime(2030), initialDate: _selectedDate);
                   if (d != null) setState(() => _selectedDate = d);
                 }, child: const Text("Change Date"))
               ],
             ),
             const SizedBox(height: 16),
             TextFormField(
               controller: _leetcodeCtrl,
               decoration: const InputDecoration(labelText: 'LeetCode URL', border: OutlineInputBorder()),
               validator: (v) => v!.isEmpty ? 'Required' : null,
             ),
             const SizedBox(height: 16),
             TextFormField(
               controller: _topicCtrl,
               decoration: const InputDecoration(labelText: 'CS Topic Title', border: OutlineInputBorder()),
               validator: (v) => v!.isEmpty ? 'Required' : null,
             ),
             const SizedBox(height: 16),
             TextFormField(
               controller: _descCtrl,
               decoration: const InputDecoration(labelText: 'Description / Resources', border: OutlineInputBorder()),
               maxLines: 3,
               validator: (v) => v!.isEmpty ? 'Required' : null,
             ),
             const SizedBox(height: 24),
             SizedBox(
               width: double.infinity,
               height: 50,
               child: FilledButton(
                 onPressed: _isLoading ? null : _submit,
                 child: _isLoading ? const CircularProgressIndicator() : const Text("Publish Task"),
               ),
             )
          ],
        ),
      ),
    );
  }
}
