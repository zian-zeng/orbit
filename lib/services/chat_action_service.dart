import 'package:flutter/cupertino.dart';

enum ChatActionType {
  mapRoute,
  calendarEvent,
  emailUpdate,
}

class ChatAction {
  const ChatAction({
    required this.type,
    required this.label,
    required this.detail,
    required this.icon,
  });

  final ChatActionType type;
  final String label;
  final String detail;
  final IconData icon;
}

class ChatActionService {
  const ChatActionService();

  static const String demoMapUrl =
      'https://www.google.com/maps/dir/?api=1&origin=IRB,+College+Park,+MD&destination=NuVegan+Cafe,+College+Park,+MD&travelmode=walking';

  List<ChatAction> actionsForResponse(String text) {
    final normalized = text.toLowerCase();
    final actions = <ChatAction>[];

    if (_mentionsMapRoute(normalized)) {
      actions.add(
        const ChatAction(
          type: ChatActionType.mapRoute,
          label: 'Open walking route',
          detail: 'IRB to NuVegan Cafe in Google Maps.',
          icon: CupertinoIcons.map,
        ),
      );
    }

    if (_mentionsCalendar(normalized)) {
      actions.add(
        const ChatAction(
          type: ChatActionType.calendarEvent,
          label: 'Add calendar block',
          detail: 'Demo: create a Google Calendar planning event.',
          icon: CupertinoIcons.calendar_badge_plus,
        ),
      );
    }

    if (_mentionsEmail(normalized)) {
      actions.add(
        const ChatAction(
          type: ChatActionType.emailUpdate,
          label: 'Send email update',
          detail: 'Demo: send a short update/invite notification.',
          icon: CupertinoIcons.mail,
        ),
      );
    }

    return actions;
  }

  bool _mentionsMapRoute(String text) {
    return text.contains('nuvegan') ||
        text.contains('google maps') ||
        (text.contains('map') && text.contains('route')) ||
        (text.contains('walking') && text.contains('irb'));
  }

  bool _mentionsCalendar(String text) {
    return text.contains('calendar') ||
        text.contains('schedule') ||
        text.contains('study block') ||
        text.contains('planning block') ||
        text.contains('next 90 minutes');
  }

  bool _mentionsEmail(String text) {
    return text.contains('email') ||
        text.contains('send an update') ||
        text.contains('invite') ||
        text.contains('message your') ||
        text.contains('notify');
  }
}
