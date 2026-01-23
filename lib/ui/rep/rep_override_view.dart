import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class RepOverrideView extends StatefulWidget {
  const RepOverrideView({super.key});

  @override
  State<RepOverrideView> createState() => _RepOverrideViewState();
}

class _RepOverrideViewState extends State<RepOverrideView> {
  final _regNoCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _submit() async {
    final regNo = _regNoCtrl.text.trim();
    final reason = _reasonCtrl.text.trim();
    if (regNo.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reg No and Reason required')));
      return;
    }

    setState(() => _isLoading = true);
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    final firestore = Provider.of<SupabaseDbService>(context, listen: false);
    final dateStr = _selectedDate.toIso8601String().split('T')[0];

    try {
      // Toggle to present (assuming override usually means fixing absent) or we should have a switch.
      // Let's ask user.
      bool? newStatus = await showDialog<bool>(
        context: context, 
        builder: (c) => AlertDialog(
          title: const Text("Set Status"),
          content: const Text("What should the new status be?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("ABSENT")),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("PRESENT")),
          ],
        )
      );

      if (newStatus == null) {
        setState(() => _isLoading = false);
        return;
      }

      await firestore.overrideAttendance(regNo, dateStr, newStatus, user!.uid, reason);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Override Logged & Updated')));
        _regNoCtrl.clear();
        _reasonCtrl.clear();
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("GOD MODE: Override Attendance", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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
          TextField(
            controller: _regNoCtrl,
            decoration: const InputDecoration(labelText: 'Student Reg No (ex: 25MX123)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(labelText: 'Reason (MANDATORY)', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          const Text(
            "Note: This action is permanently logged in the Audit Trail.",
            style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),
           SizedBox(
               width: double.infinity,
               height: 50,
               child: FilledButton(
                 style: FilledButton.styleFrom(backgroundColor: Colors.red),
                 onPressed: _isLoading ? null : _submit,
                 child: _isLoading ? const CircularProgressIndicator() : const Text("Update Record"),
               ),
             )
        ],
      ),
    );
  }
}
