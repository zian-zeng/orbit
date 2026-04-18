import 'package:chatbotapp/agents/orbit_models.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';
import 'package:chatbotapp/services/connected_apps_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ConnectedAppsService();

  test('summarizes connected proxy and approval-gated tools', () {
    final apps = service.build(
      config: const IntegrationConfig(
        externalDataEnabled: true,
        studentDataProxyUrl: 'http://127.0.0.1:8787',
        canvasBaseUrl: IntegrationConfig.umdCanvasBaseUrl,
        canvasAccessToken: '',
        googleAccessToken: '',
        googleMapsApiKey: '',
        defaultCampusOrigin: IntegrationConfig.defaultOrigin,
        defaultCampusDestination: IntegrationConfig.defaultDestination,
        cacheTtl: Duration(minutes: 5),
        requestTimeout: Duration(seconds: 2),
      ),
      allowExternalData: true,
      preferDemoFixture: false,
      labels: const ['stress_sensitive', 'commuter'],
    );

    final proxy = apps.singleWhere((app) => app.id == 'student_data_proxy');
    expect(proxy.status, ConnectedAppStatus.connected);
    expect(
      proxy.permissionDecisions
          .where((decision) => decision.toolId == 'course_professor_planner')
          .single
          .level,
      OrbitToolPermissionLevel.approvalRequired,
    );
  });

  test('demo fixture mode prevents live connector status', () {
    final apps = service.build(
      config: const IntegrationConfig(
        externalDataEnabled: true,
        studentDataProxyUrl: 'http://127.0.0.1:8787',
        canvasBaseUrl: IntegrationConfig.umdCanvasBaseUrl,
        canvasAccessToken: 'canvas-token',
        googleAccessToken: 'calendar-token',
        googleMapsApiKey: 'maps-key',
        defaultCampusOrigin: IntegrationConfig.defaultOrigin,
        defaultCampusDestination: IntegrationConfig.defaultDestination,
        cacheTtl: Duration(minutes: 5),
        requestTimeout: Duration(seconds: 2),
      ),
      allowExternalData: true,
      preferDemoFixture: true,
    );

    expect(
      apps.where((app) =>
          app.id != 'planetterp' && app.status == ConnectedAppStatus.connected),
      isEmpty,
    );
    expect(
      apps.singleWhere((app) => app.id == 'canvas').status,
      ConnectedAppStatus.demoOnly,
    );
  });
}
