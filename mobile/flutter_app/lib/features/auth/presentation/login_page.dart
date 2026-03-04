import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/design_theme.dart';
import '../../../core/i18n/app_strings.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/user_session.dart';
import '../../offline/application/offline_store.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  UserRole _role = UserRole.manager;

  Future<void> _doLogin() async {
    final username = _userController.text.trim();
    final password = _passController.text;
    if (username.isEmpty) return;

    await ref.read(authStateProvider.notifier).login(
          username,
          password,
          role: _role,
        );

    ref.read(offlineStoreProvider.notifier).login(user: username, role: _role);
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
                      strings.welcomeBack,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: DsColorTokens.textPrimary,
                            letterSpacing: -0.5,
                          ),
                    ),
                    Text(
                      strings.signInSubtitle,
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
                      decoration: InputDecoration(
                        labelText: strings.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: DsSpaceTokens.space4),
                    SegmentedButton<UserRole>(
                      segments: [
                        ButtonSegment<UserRole>(
                          value: UserRole.employee,
                          label: Text(strings.employee),
                        ),
                        ButtonSegment<UserRole>(
                          value: UserRole.manager,
                          label: Text(strings.manager),
                        ),
                      ],
                      selected: {_role},
                      onSelectionChanged: (value) {
                        setState(() => _role = value.first);
                      },
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
