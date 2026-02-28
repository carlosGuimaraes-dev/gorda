import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/design_theme.dart';
import '../../core/design/design_tokens.dart';
import '../../core/i18n/app_strings.dart';
import '../application/auth_controller.dart';
import '../domain/user_session.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  Future<void> _doLogin() async {
    await ref.read(authStateProvider.notifier).login(
          _userController.text,
          _passController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final strings = AppStrings.of(Localizations.localeOf(context));

    return Scaffold(
      backgroundColor: AppThemeTokens.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cleaning_services_rounded,
                size: 64,
                color: AppThemeTokens.primary,
              ),
              const SizedBox(height: AppSpacing.large),
              Text(
                'AG Home Organizer',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppThemeTokens.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxLarge),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: authState.isLoading ? null : _doLogin,
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(strings.login, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleSelectionPage extends ConsumerWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(Localizations.localeOf(context));

    return Scaffold(
      appBar: AppBar(title: Text('Select Profile')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xLarge),
            Text(
              'Choose your role for this session:',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxLarge),
            ListTile(
              leading: const Icon(Icons.manage_accounts, size: 40),
              title: Text(strings.manager),
              subtitle: const Text('Manage schedules, finances, and teams.'),
              tileColor: AppThemeTokens.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                ref.read(authStateProvider.notifier).selectRole(UserRole.manager);
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            ListTile(
              leading: const Icon(Icons.person, size: 40),
              title: Text(strings.employee),
              subtitle: const Text('View your schedule and earnings.'),
              tileColor: AppThemeTokens.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                ref.read(authStateProvider.notifier).selectRole(UserRole.employee);
              },
            ),
          ],
        ),
      ),
    );
  }
}
