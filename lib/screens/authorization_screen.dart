import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/utilities/app_snackbar.dart';
import 'package:chatbotapp/widgets/startup/startup_stage_shell.dart';

class AuthorizationScreen extends StatefulWidget {
  const AuthorizationScreen({super.key});

  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _accessCodeController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  String get _configuredAccessCode =>
      _readConfiguredAccessCode();

  bool get _requiresAccessCode => _configuredAccessCode.isNotEmpty;
  Future<void> _authorize() async {
    if (_isSaving) {
      return;
    }

    final trimmedEmail = _emailController.text.trim();
    if (!_isValidSchoolEmail(trimmedEmail)) {
      showAppSnackBar(context, 'Use a valid UMD or Terpmail address');
      return;
    }

    if (_requiresAccessCode &&
        _accessCodeController.text.trim() != _configuredAccessCode) {
      showAppSnackBar(context, 'Access code does not match');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<UserProfileProvider>().authorizeSession(
            email: trimmedEmail,
            authorizationMethod:
                _requiresAccessCode ? 'access-code' : 'school-email',
          );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Could not authorize this device');
      setState(() {
        _isSaving = false;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StartupStageShell(
      stageLabel: 'Authorized Access',
      stageTitle: 'Authorize Orbit',
      stageDescription:
          'Use your school email to unlock the local workspace before setup. This keeps the prototype scoped to campus users and makes the rest of the startup flow easier to trust.',
      leadingPanel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orbit',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Student support, without the dashboard clutter.',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Authorize once, review the guide, then tailor the workspace to your semester.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          const _AsideBullet(
            icon: CupertinoIcons.lock_shield,
            title: 'Local-only by default',
            detail: 'Profile, guide state, and chat history stay on device.',
          ),
          const SizedBox(height: 14),
          const _AsideBullet(
            icon: CupertinoIcons.book,
            title: 'Guided first-run',
            detail: 'Orbit explains how routing, signals, and tools fit together.',
          ),
          const SizedBox(height: 14),
          const _AsideBullet(
            icon: CupertinoIcons.sparkles,
            title: 'Calmer setup',
            detail: 'Authorization, guide, and profile questions each get their own step.',
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StartupSectionFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'School access',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _requiresAccessCode
                      ? 'Enter your school email and the local access code configured for this demo.'
                      : 'Enter your UMD or Terpmail address to create a local session for this device.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'School email',
                    hintText: 'name@umd.edu',
                    errorText: _emailController.text.trim().isEmpty ||
                            _isValidSchoolEmail(_emailController.text)
                        ? null
                        : 'Use @umd.edu or @terpmail.umd.edu',
                  ),
                ),
                if (_requiresAccessCode) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _accessCodeController,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Access code',
                      hintText: 'Enter the demo code',
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Orbit does not claim remote identity verification here. This step authorizes a local session for the prototype.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: !_isSaving ? _authorize : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isSaving ? 'Authorizing...' : 'Continue to guide',
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidSchoolEmail(String value) {
    final trimmed = value.trim().toLowerCase();
    return RegExp(r'^[^@\s]+@(umd\.edu|terpmail\.umd\.edu)$')
        .hasMatch(trimmed);
  }

  String _readConfiguredAccessCode() {
    try {
      return dotenv.env['ORBIT_ACCESS_CODE']?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }
}

class _AsideBullet extends StatelessWidget {
  const _AsideBullet({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
