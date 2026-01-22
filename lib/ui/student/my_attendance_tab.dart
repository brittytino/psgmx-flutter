import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/task_attendance.dart';

class MyAttendanceTab extends StatelessWidget {
  const MyAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    final firestore = Provider.of<SupabaseDbService>(context);

    if (user == null) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<List<AttendanceRecord>>(
            stream: firestore.getStudentAttendance(user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final records = snapshot.data!;
              final presentCount = records.where((r) => r.isPresent).length;
              final total = records.length; // Or total working days if needed, but relative % is fine
              final percentage = total == 0 ? 0 : (presentCount / total * 100).toStringAsFixed(1);

              return Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem("Present", "$presentCount"),
                      _StatItem("Total", "$total"),
                      _StatItem("Percentage", "$percentage%"),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AttendanceRecord>>(
            stream: firestore.getStudentAttendance(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final records = snapshot.data ?? [];
              if (records.isEmpty) {
                return const Center(child: Text("No attendance records found."));
              }
              
              return ListView.separated(
                itemCount: records.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final record = records[index];
                  // Parse date string or use timestamp
                  final DateTime date = DateTime.parse(record.date); // Provided id is YYYY-MM-DD
                  final formattedDate = DateFormat('MMM dd, yyyy (EEE)').format(date);
                  
                  return ListTile(
                    leading: Icon(
                      record.isPresent ? Icons.check_circle : Icons.cancel,
                      color: record.isPresent ? Colors.green : Colors.red,
                    ),
                    title: Text(formattedDate),
                    trailing: Text(record.isPresent ? 'Present' : 'Absent', 
                      style: TextStyle(
                        color: record.isPresent ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold
                      )
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
