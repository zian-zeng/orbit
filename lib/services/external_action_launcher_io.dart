import 'package:flutter/services.dart';

class ExternalActionLauncher {
  const ExternalActionLauncher();

  static const MethodChannel _channel = MethodChannel('orbit/external_actions');

  Future<bool> openUrl(String url) async {
    final opened = await _channel.invokeMethod<bool>(
      'openUrl',
      {'url': url},
    );
    return opened ?? false;
  }
}
