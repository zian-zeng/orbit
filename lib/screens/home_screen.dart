import 'package:flutter/material.dart';
import 'package:chatbotapp/screens/chat_screen.dart';
import 'package:chatbotapp/screens/onboarding_screen.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<UserProfileProvider>();

    if (!userProfile.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userProfile.shouldShowOnboarding) {
      return const OnboardingScreen();
    }

    return const ChatScreen();
  }
}
