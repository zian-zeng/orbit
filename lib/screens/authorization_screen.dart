import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:chatbotapp/providers/settings_provider.dart';
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
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoginMode = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _accessCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _configuredAccessCode => _readConfiguredAccessCode();

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

  Future<void> _login() async {
    if (_isSaving) {
      return;
    }

    final trimmedEmail = _emailController.text.trim().toLowerCase();
    if (trimmedEmail != UserProfileProvider.demoEmail) {
      showAppSnackBar(context, 'Use ${UserProfileProvider.demoEmail}');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await context.read<UserProfileProvider>().loginAsDemoUser(
            password: _passwordController.text,
          );
      if (!success) {
        if (!mounted) {
          return;
        }
        showAppSnackBar(context, 'Password does not match');
        setState(() {
          _isSaving = false;
        });
        return;
      }
      if (mounted) {
        context.read<SettingsProvider>().reloadSavedSettings();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Could not log in to the demo profile');
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

  Future<void> _useMayaDemoProfile() async {
    _emailController.text = UserProfileProvider.demoEmail;
    _passwordController.text = UserProfileProvider.demoPassword;
    await _login();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StartupStageShell(
      stageLabel: 'Authorized Access',
      stageTitle: _isLoginMode ? 'Log in to Orbit' : 'Authorize Orbit',
      stageDescription: _isLoginMode
          ? 'Use the stored demo account to open the personalized Maya Chen workspace without repeating setup.'
          : 'Use your school email to unlock the local workspace before setup. This keeps the prototype scoped to campus users and makes the rest of the startup flow easier to trust.',
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
            _isLoginMode
                ? 'Maya Chen is the seeded demo student for web and Android walkthroughs.'
                : 'Authorize once, review the guide, then tailor the workspace to your semester.',
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
            detail:
                'Orbit explains how routing, signals, and tools fit together.',
          ),
          const SizedBox(height: 14),
          const _AsideBullet(
            icon: CupertinoIcons.sparkles,
            title: 'Calmer setup',
            detail:
                'Authorization, guide, and profile questions each get their own step.',
          ),
          if (_isLoginMode) ...[
            const SizedBox(height: 14),
            const _AsideBullet(
              icon: CupertinoIcons.chart_bar_alt_fill,
              title: 'Seeded demo state',
              detail:
                  'Maya opens with labels, prior chats, monitor history, and demo connectors ready.',
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoSlidingSegmentedControl<bool>(
            groupValue: _isLoginMode,
            children: const {
              false: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('Sign up'),
              ),
              true: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('Log in'),
              ),
            },
            onValueChanged: (value) {
              if (value == null || value == _isLoginMode) {
                return;
              }
              setState(() {
                _isLoginMode = value;
                _emailController.clear();
                _accessCodeController.clear();
                _passwordController.clear();
              });
            },
          ),
          const SizedBox(height: 16),
          StartupSectionFrame(
            child: _isLoginMode
                ? _LoginForm(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    isSaving: _isSaving,
                    onChanged: () => setState(() {}),
                    onUseDemoProfile: _useMayaDemoProfile,
                  )
                : _SignupForm(
                    emailController: _emailController,
                    accessCodeController: _accessCodeController,
                    requiresAccessCode: _requiresAccessCode,
                    isValidSchoolEmail: _isValidSchoolEmail,
                    onChanged: () => setState(() {}),
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  !_isSaving ? (_isLoginMode ? _login : _authorize) : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isSaving
                    ? _isLoginMode
                        ? 'Logging in...'
                        : 'Authorizing...'
                    : _isLoginMode
                        ? 'Log in'
                        : 'Continue to guide',
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidSchoolEmail(String value) {
    final trimmed = value.trim().toLowerCase();
    return RegExp(r'^[^@\s]+@(umd\.edu|terpmail\.umd\.edu)$').hasMatch(trimmed);
  }

  String _readConfiguredAccessCode() {
    try {
      return dotenv.env['ORBIT_ACCESS_CODE']?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }
}

class _SignupForm extends StatelessWidget {
  const _SignupForm({
    required this.emailController,
    required this.accessCodeController,
    required this.requiresAccessCode,
    required this.isValidSchoolEmail,
    required this.onChanged,
  });

  final TextEditingController emailController;
  final TextEditingController accessCodeController;
  final bool requiresAccessCode;
  final bool Function(String value) isValidSchoolEmail;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
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
          requiresAccessCode
              ? 'Enter your school email and the local access code configured for this demo.'
              : 'Enter your UMD or Terpmail address to create a local session for this device.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: 'School email',
            hintText: 'name@umd.edu',
            errorText: emailController.text.trim().isEmpty ||
                    isValidSchoolEmail(emailController.text)
                ? null
                : 'Use @umd.edu or @terpmail.umd.edu',
          ),
        ),
        if (requiresAccessCode) ...[
          const SizedBox(height: 14),
          TextField(
            controller: accessCodeController,
            obscureText: true,
            onChanged: (_) => onChanged(),
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
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.isSaving,
    required this.onChanged,
    required this.onUseDemoProfile,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSaving;
  final VoidCallback onChanged;
  final VoidCallback onUseDemoProfile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stored demo account',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Log in as Maya Chen to skip signup, the guide, and onboarding. Password: ${UserProfileProvider.demoPassword}.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: UserProfileProvider.demoEmail,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: '12345',
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: isSaving ? null : onUseDemoProfile,
          icon: const Icon(CupertinoIcons.person_crop_circle_badge_checkmark),
          label: const Text('Use Maya demo profile'),
        ),
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
            'This is a local prototype login. It seeds a repeatable demo profile instead of performing remote identity verification.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
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
