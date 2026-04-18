import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/hive/assistant_feedback_entry.dart';
import 'package:chatbotapp/hive/chat_history.dart';
import 'package:chatbotapp/hive/monitor_history_entry.dart';
import 'package:chatbotapp/hive/settings.dart';
import 'package:chatbotapp/hive/user_model.dart';
import 'package:hive/hive.dart';

class Boxes {
  // get the chat history box
  static Box<ChatHistory> getChatHistory() =>
      Hive.box<ChatHistory>(Constants.chatHistoryBox);

  // get user box
  static Box<UserModel> getUser() => Hive.box<UserModel>(Constants.userBox);

  // get settings box
  static Box<Settings> getSettings() =>
      Hive.box<Settings>(Constants.settingsBox);

  // get monitor history box
  static Box<MonitorHistoryEntry> getMonitorHistory() =>
      Hive.box<MonitorHistoryEntry>(Constants.monitorHistoryBox);

  // get assistant feedback box
  static Box<AssistantFeedbackEntry> getAssistantFeedback() =>
      Hive.box<AssistantFeedbackEntry>(Constants.assistantFeedbackBox);
}
