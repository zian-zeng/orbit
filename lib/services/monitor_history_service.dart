import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/hive/boxes.dart';
import 'package:chatbotapp/hive/monitor_history_entry.dart';
import 'package:chatbotapp/services/student_monitor_service.dart';
import 'package:hive/hive.dart';

class MonitorHistoryService {
  const MonitorHistoryService();

  Future<MonitorHistoryEntry> recordReport(
    StudentMonitorReport report, {
    DateTime? now,
  }) async {
    final createdAt = now ?? DateTime.now();
    final entry = MonitorHistoryEntry(
      id: _entryId(report, createdAt),
      createdAt: createdAt,
      studentEmail: _studentKey(report.email),
      source: report.isLive ? 'live' : 'demo',
      stressScore: report.snapshot.stressRiskScore,
      deadlines: report.snapshot.deadlinesNextSevenDays,
      calendarHours: report.snapshot.calendarHoursNextSevenDays,
      placeCount: report.snapshot.places.length,
      routeCount: report.snapshot.routes.length,
      labels: report.profileLabels.take(10).toList(growable: false),
      sourceNote: report.snapshot.sourceNotes.take(2).join(' '),
    );

    if (!Hive.isBoxOpen(Constants.monitorHistoryBox)) {
      return entry;
    }

    await Boxes.getMonitorHistory().put(entry.id, entry);
    return entry;
  }

  List<MonitorHistoryEntry> loadRecent({
    required String email,
    int limit = 30,
  }) {
    if (!Hive.isBoxOpen(Constants.monitorHistoryBox)) {
      return const [];
    }
    final studentKey = _studentKey(email);
    final entries = Boxes.getMonitorHistory()
        .values
        .where((entry) => entry.studentEmail == studentKey)
        .toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    return entries.take(limit).toList(growable: false).reversed.toList();
  }

  Future<void> clearForStudent({required String email}) async {
    if (!Hive.isBoxOpen(Constants.monitorHistoryBox)) {
      return;
    }
    final studentKey = _studentKey(email);
    final box = Boxes.getMonitorHistory();
    final keys = box.keys.where((key) {
      final entry = box.get(key);
      return entry?.studentEmail == studentKey;
    }).toList(growable: false);
    await box.deleteAll(keys);
  }

  String _entryId(StudentMonitorReport report, DateTime createdAt) {
    final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    return '${_studentKey(report.email)}|${report.isLive ? 'live' : 'demo'}|'
        '${day.toIso8601String()}';
  }

  String _studentKey(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized.isEmpty ? 'demo-student' : normalized;
  }
}
