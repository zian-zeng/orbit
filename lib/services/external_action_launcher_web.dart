// ignore_for_file: deprecated_member_use

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ExternalActionLauncher {
  const ExternalActionLauncher();

  Future<bool> openUrl(String url) async {
    html.window.open(url, '_blank');
    return true;
  }
}
