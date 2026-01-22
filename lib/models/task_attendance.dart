class DailyTask {
  final String date; // YYYY-MM-DD
  final String leetcodeUrl;
  final String csTopic;
  final String csTopicDescription;
  final String motivationQuote;

  DailyTask({
    required this.date,
    required this.leetcodeUrl,
    required this.csTopic,
    required this.csTopicDescription,
    required this.motivationQuote,
  });

  factory DailyTask.fromMap(Map<String, dynamic> map, String id) {
    return DailyTask(
      date: map['date'] ?? id,
      leetcodeUrl: map['leetcode_url'] ?? map['leetcodeUrl'] ?? '',
      csTopic: map['cs_topic'] ?? map['csTopic'] ?? '',
      csTopicDescription: map['cs_topic_description'] ?? map['csTopicDescription'] ?? '',
      motivationQuote: map['motivation_quote'] ?? map['motivationQuote'] ?? '',
    );
  }
}

class AttendanceRecord {
  final String id;
  final String date;
  final String studentUid;
  final String regNo;
  final String teamId;
  final bool isPresent;
  final DateTime timestamp;
  final String markedBy;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.studentUid,
    required this.regNo,
    required this.teamId,
    required this.isPresent,
    required this.timestamp,
    required this.markedBy,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceRecord(
      id: id,
      date: map['date'] ?? '',
      studentUid: map['student_uid'] ?? map['studentUid'] ?? '',
      regNo: map['reg_no'] ?? map['regNo'] ?? '',
      teamId: map['team_id'] ?? map['teamId'] ?? '',
      isPresent: map['status'] == 'PRESENT',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp'].toString())
          : DateTime.now(),
      markedBy: map['marked_by'] ?? map['markedBy'] ?? '',
    );
  }
}
