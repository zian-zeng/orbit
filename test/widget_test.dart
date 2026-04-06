import 'package:flutter_test/flutter_test.dart';
import 'package:chatbotapp/providers/chat_provider.dart';
import 'package:chatbotapp/providers/settings_provider.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/providers/voice_input_provider.dart';
import 'package:chatbotapp/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> pumpChatScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => VoiceInputProvider()),
      ],
      child: MaterialApp(
        home: const ChatScreen(),
        theme: ThemeData(useMaterial3: true),
      ),
    ),
  );
}

void main() {
  testWidgets('Chat screen renders empty state', (WidgetTester tester) async {
    await pumpChatScreen(tester);

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('How can I help?'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Map out a plan'), findsOneWidget);
    expect(find.text('Draft a polished reply'), findsOneWidget);
  });

  testWidgets('Selecting a recommendation prefills the composer', (
    WidgetTester tester,
  ) async {
    await pumpChatScreen(tester);

    await tester.tap(find.text('Draft a polished reply'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(
      textField.controller?.text,
      'Help me draft a clear, polished message about: ',
    );
  });

  testWidgets('Label override reshapes recommendations', (
    WidgetTester tester,
  ) async {
    await pumpChatScreen(tester);

    await tester.tap(find.text('Image analysis'));
    await tester.pumpAndSettle();

    expect(find.text('Analyze an image'), findsOneWidget);
  });
}
