import 'dart:io';

import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/demo/orbit_business_demo_scenario.dart';
import 'package:chatbotapp/hive/monitor_history_entry.dart';
import 'package:chatbotapp/services/monitor_history_service.dart';
import 'package:chatbotapp/services/student_monitor_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('orbit-monitor-test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(MonitorHistoryEntryAdapter());
    }
    await Hive.openBox<MonitorHistoryEntry>(Constants.monitorHistoryBox);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('records and loads daily monitor checkpoints', () async {
    const historyService = MonitorHistoryService();
    const monitorService = StudentMonitorService();
    final report = monitorService.fromDemo(
      OrbitBusinessDemoScenario.veganUmdStudent(),
    );

    await historyService.recordReport(
      report,
      now: DateTime(2026, 4, 18, 10),
    );
    await historyService.recordReport(
      report,
      now: DateTime(2026, 4, 19, 10),
    );

    final history = historyService.loadRecent(email: report.email);

    expect(history, hasLength(2));
    expect(history.first.dayLabel, '4/18');
    expect(history.last.dayLabel, '4/19');
    expect(history.last.deadlines, report.snapshot.deadlinesNextSevenDays);
    expect(history.last.labels, contains('vegan'));
  });

  test('upserts same-day monitor checkpoints', () async {
    const historyService = MonitorHistoryService();
    const monitorService = StudentMonitorService();
    final report = monitorService.fromDemo(
      OrbitBusinessDemoScenario.veganUmdStudent(),
    );

    await historyService.recordReport(
      report,
      now: DateTime(2026, 4, 18, 10),
    );
    await historyService.recordReport(
      report,
      now: DateTime(2026, 4, 18, 12),
    );

    final history = historyService.loadRecent(email: report.email);

    expect(history, hasLength(1));
    expect(history.single.createdAt.hour, 12);
  });

  test('clears history for one student', () async {
    const historyService = MonitorHistoryService();
    const monitorService = StudentMonitorService();
    final report = monitorService.fromDemo(
      OrbitBusinessDemoScenario.veganUmdStudent(),
    );

    await historyService.recordReport(report);
    await historyService.clearForStudent(email: report.email);

    expect(historyService.loadRecent(email: report.email), isEmpty);
  });
}
