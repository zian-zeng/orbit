class Constants {
  static const String appName = 'Orbit';
  static const String appTitle = 'Orbit';
  static const String appDescription =
      'Local-first student support workspace';
  static const String chatHistoryBox = 'chat_history';
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings';
  static const String monitorHistoryBox = 'monitor_history';
  static const String assistantFeedbackBox = 'assistant_feedback';
  static const String agentAuditLogBox = 'agent_audit_log';
  static const String skillRegistryBox = 'skill_registry';

  static const String chatMessagesBox = 'chat_messages_';

  static const String geminiDB = 'gemini.db';
  static const String geminiTextModel = 'gemini-2.5-flash';
  static const String geminiVisionModel = 'gemini-2.5-flash';
  static const String localAgentModel = 'local-gemma-orbit';
  static const String assistantSystemInstruction =
      'You are ORBIT, a local-first multi-agent assistant for student academic support, planning, and well-being. '
      'Give clear, accurate, and concise answers. Use labels, history, and stress signals only when they are available. '
      'Never claim live access to Canvas, Google Calendar, campus resources, or datasets unless that data is provided. '
      'If the request is unclear, ask one short clarifying question instead of guessing.';
}
