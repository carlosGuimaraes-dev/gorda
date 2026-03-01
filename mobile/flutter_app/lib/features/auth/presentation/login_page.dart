import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/design_theme.dart';
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
      extendBodyBehindAppBar: true,
      body: DsBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DsSpaceTokens.space6),
              child: DsCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Hero(
                      tag: 'logo',
                      child: Icon(
                        Icons.cleaning_services_rounded,
                        size: 72,
                        color: DsColorTokens.actionPrimary,
                      ),
                    ),
                    const SizedBox(height: DsSpaceTokens.space4),
                    Text(
                      'AG Home Organizer',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: DsColorTokens.textPrimary,
                            letterSpacing: -0.5,
                          ),
                    ),
                    Text(
                      'Premium Cleaning Management',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DsColorTokens.textSecondary,
                          ),
                    ),
                    const SizedBox(height: DsSpaceTokens.space8),
                    TextField(
                      controller: _userController,
                      decoration: InputDecoration(
                        labelText: strings.user,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: DsSpaceTokens.space4),
                    TextField(
                      controller: _passController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: DsSpaceTokens.space8),
                    DsPrimaryButton(
                      title: strings.signIn,
                      onPressed: authState.isLoading ? () {} : _doLogin,
                      isDisabled: authState.isLoading,
                    ),
                    if (authState.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: DsSpaceTokens.space4),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
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
      extendBodyBehindAppBar: true,
      body: DsBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DsSpaceTokens.space6),
            child: Column(
              children: [
                const SizedBox(height: DsSpaceTokens.space8),
                const Hero(
                  tag: 'logo',
                  child: Icon(
                    Icons.account_circle_outlined,
                    size: 64,
                    color: DsColorTokens.actionPrimary,
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space4),
                Text(
                  'Choose your role',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DsColorTokens.textPrimary,
                      ),
                ),
                const SizedBox(height: DsSpaceTokens.space12),
                DsCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(DsSpaceTokens.space4),
                    leading: const Icon(Icons.manage_accounts,
                        size: 40, color: DsColorTokens.actionPrimary),
                    title: Text(strings.manager,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: DsColorTokens.textPrimary)),
                    subtitle: Text('Manage schedules, finances, and teams.',
                        style: TextStyle(color: DsColorTokens.textSecondary)),
                    onTap: () {
                      ref
                          .read(authStateProvider.notifier)
                          .selectRole(UserRole.manager);
                    },
                  ),
                ),
                const SizedBox(height: DsSpaceTokens.space2),
                DsCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(DsSpaceTokens.space4),
                    leading: const Icon(Icons.person,
                        size: 40, color: DsColorTokens.actionPrimary),
                    title: Text(strings.employee,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: DsColorTokens.textPrimary)),
                    subtitle: Text('View your schedule and earnings.',
                        style: TextStyle(color: DsColorTokens.textSecondary)),
                    onTap: () {
                      ref
                          .read(authStateProvider.notifier)
                          .selectRole(UserRole.employee);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

