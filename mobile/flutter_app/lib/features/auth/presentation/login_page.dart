import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/user_session.dart';

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DsSpaceTokens.space4),
            child: AppCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(
                    Icons.cleaning_services_rounded,
                    size: 64,
                    color: AppThemeTokens.primary,
                  ),
                  const SizedBox(height: DsSpaceTokens.space4),
                  Text(
                    'AG Home Organizer',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppThemeTokens.primaryText,
                        ),
                  ),
                  const SizedBox(height: DsSpaceTokens.space8),
                  TextField(
                    controller: _userController,
                    decoration: InputDecoration(
                      labelText: strings.user,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: DsSpaceTokens.space4),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: DsSpaceTokens.space4),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppThemeTokens.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DsRadiusTokens.radiusMd),
                        ),
                      ),
                      onPressed: authState.isLoading ? null : _doLogin,
                      child: authState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(strings.signIn, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
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
      backgroundColor: AppThemeTokens.background,
      appBar: AppBar(title: const Text('Select Profile')),
      body: Padding(
        padding: const EdgeInsets.all(DsSpaceTokens.space4),
        child: Column(
          children: [
            const SizedBox(height: DsSpaceTokens.space8),
            Text(
              'Choose your role for this session:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppThemeTokens.primaryText,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DsSpaceTokens.space12),
            AppCard(
              padding: const EdgeInsets.all(DsSpaceTokens.space4),
              child: ListTile(
                leading: const Icon(Icons.manage_accounts, size: 40, color: AppThemeTokens.primary),
                title: Text(strings.manager, style: const TextStyle(fontWeight: FontWeight.bold, color: AppThemeTokens.primaryText)),
                subtitle: Text('Manage schedules, finances, and teams.', style: TextStyle(color: AppThemeTokens.secondaryText)),
                onTap: () {
                  ref.read(authStateProvider.notifier).selectRole(UserRole.manager);
                },
              ),
            ),
            const SizedBox(height: DsSpaceTokens.space4),
            AppCard(
              padding: const EdgeInsets.all(DsSpaceTokens.space4),
              child: ListTile(
                leading: const Icon(Icons.person, size: 40, color: AppThemeTokens.primary),
                title: Text(strings.employee, style: const TextStyle(fontWeight: FontWeight.bold, color: AppThemeTokens.primaryText)),
                subtitle: Text('View your schedule and earnings.', style: TextStyle(color: AppThemeTokens.secondaryText)),
                onTap: () {
                  ref.read(authStateProvider.notifier).selectRole(UserRole.employee);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

