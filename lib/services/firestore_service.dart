import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/task_attendance.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Task Methods ---
  Stream<DailyTask?> getDailyTask(String date) {
    return _db.collection('daily_tasks').doc(date).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DailyTask.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> publishDailyTask(DailyTask task) async {
    await _db.collection('daily_tasks').doc(task.date).set({
      'leetcodeUrl': task.leetcodeUrl,
      'csTopic': task.csTopic,
      'csTopicDescription': task.csTopicDescription,
      'motivationQuote': task.motivationQuote,
    });
  }

  // --- Student Methods ---
  Future<List<AppUser>> getTeamMembers(String teamId) async {
    final snapshot = await _db.collection('users')
        .where('teamId', isEqualTo: teamId)
        .where('roles.isStudent', isEqualTo: true)
        .get();
    
    return snapshot.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
  }

  // --- Attendance Methods ---
  Future<bool> isAttendanceSubmitted(String teamId, String date) async {
    final doc = await _db.collection('attendance_submissions').doc('${date}_$teamId').get();
    return doc.exists;
  }

  Future<void> submitAttendance({
    required String teamId,
    required String date,
    required String leaderUid,
    required Map<String, bool> studentStatus, // uid -> isPresent
  }) async {
    // 1. Transaction to Ensure Atomic Submission and Non-Duplication
    await _db.runTransaction((transaction) async {
      final submissionRef = _db.collection('attendance_submissions').doc('${date}_$teamId');
      final submissionDoc = await transaction.get(submissionRef);

      if (submissionDoc.exists) {
        throw Exception("Attendance already submitted for today.");
      }

      // 2. Create Submission Record
      transaction.set(submissionRef, {
        'date': date,
        'teamId': teamId,
        'submittedBy': leaderUid,
        'submittedAt': FieldValue.serverTimestamp(),
        'isLocked': false, // Will be locked by Cloud Function at 8 PM
      });

      // 3. Create Individual Records
      studentStatus.forEach((uid, isPresent) {
        // Need regNo to be stored, but we only have map of UID -> Bool here.
        // Ideally we pass full user objects or fetch them.
        // Optimisation: We assume the UI passed valid UIDs.
        // We need the key to be unique daily per student.
        // But to save writes, maybe we only write PRESENT? 
        // No, writing both is safer for explicit history.
        
        // Wait, for this demo, let's just write to attendance_records.
        // We'll need another read in cloud function if we want to fill usage details.
        // Or we just write data provided.
      });
    });
  }
  
  // Revised Submit Method
  Future<void> submitTeamAttendance(String teamId, String date, String leaderUid, List<AttendanceRecord> records) async {
     return _db.runTransaction((transaction) async {
      final submissionRef = _db.collection('attendance_submissions').doc('${date}_$teamId');
      final submissionDoc = await transaction.get(submissionRef);

      if (submissionDoc.exists) {
        throw Exception("Attendance already submitted for today.");
      }

      transaction.set(submissionRef, {
        'date': date,
        'teamId': teamId,
        'submittedBy': leaderUid,
        'submittedAt': FieldValue.serverTimestamp(),
        'isLocked': false,
      });

      for (var record in records) {
        final ref = _db.collection('attendance_records').doc('${date}_${record.regNo}');
        transaction.set(ref, {
          'date': date,
          'studentUid': record.studentUid,
          'regNo': record.regNo,
          'teamId': teamId,
          'status': record.isPresent ? 'PRESENT' : 'ABSENT',
          'markedBy': leaderUid,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // --- Student View ---
  Stream<List<AttendanceRecord>> getStudentAttendance(String uid) {
    return _db.collection('attendance_records')
        .where('studentUid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((d) => AttendanceRecord.fromMap(d.data(), d.id)).toList());
  }
  
  // --- Rep Override ---
  Future<void> overrideAttendance(String regNo, String date, bool newStatus, String repUid, String reason) async {
    final recordId = '${date}_$regNo';
    final ref = _db.collection('attendance_records').doc(recordId);
    
    // We also need to log this
    final logRef = _db.collection('audit_logs').doc();
    
    await _db.runTransaction((t) async {
       final doc = await t.get(ref);
       String prevStatus = "UNKNOWN";
       if (doc.exists) {
         prevStatus = doc.data()?['status'] ?? "UNKNOWN";
       }
       
       t.set(ref, {
         'status': newStatus ? 'PRESENT' : 'ABSENT',
         'overriddenBy': repUid,
         // Maintain other fields if it exists, theoretically merge: true but transaction set needs all data if strictly enforcing schema
         // For simplicity: upsert
         'date': date,
         'regNo': regNo,
         // 'studentUid': ... we might miss this if creating new record from scratch...
         // Assumption: Rep edits existing record usually. If creating new, Rep needs to know UID.
       }, SetOptions(merge: true));
       
       t.set(logRef, {
         'action': 'OVERRIDE_ATTENDANCE',
         'targetDate': date,
         'targetRegNo': regNo,
         'previousStatus': prevStatus,
         'newStatus': newStatus ? 'PRESENT' : 'ABSENT',
         'reason': reason,
         'performedBy': repUid,
         'timestamp': FieldValue.serverTimestamp(),
       });
    });
  }
}
