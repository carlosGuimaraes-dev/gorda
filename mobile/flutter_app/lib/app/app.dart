import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_strings.dart';
import '../core/theme/app_card.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/domain/user_session.dart';
import '../features/offline/application/offline_store.dart';
import '../features/shell/home_shell.dart';
import '../features/splash/presentation/splash_view.dart';

class AgApp extends ConsumerStatefulWidget {
  const AgApp({super.key});

  @override
  ConsumerState<AgApp> createState() => _AgAppState();
}

class _AgAppState extends ConsumerState<AgApp> {
  bool _showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(offlineStoreProvider);
    final locale = Locale(store.languageCode, store.countryCode);

    return MaterialApp(
      title: 'AG Home Organizer',
      theme: buildAppTheme(),
      locale: locale,
      supportedLocales: AppStrings.supportedLocales,
      home: _showSplash
          ? const SplashView()
          : store.session == null
              ? const _LoginPage()
              : HomeShell(role: store.session!.role),
    );
  }
}

class _LoginPage extends ConsumerStatefulWidget {
  const _LoginPage();

  @override
  ConsumerState<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<_LoginPage> {
  final TextEditingController _userController = TextEditingController();
  UserRole _role = UserRole.manager;

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(Localizations.localeOf(context));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.welcomeBack,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppThemeTokens.primaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.signInSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppThemeTokens.secondaryText,
                            ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _userController,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(labelText: strings.user),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<UserRole>(
                        segments: [
                          ButtonSegment<UserRole>(
                              value: UserRole.employee,
                              label: Text(strings.employee)),
                          ButtonSegment<UserRole>(
                              value: UserRole.manager,
                              label: Text(strings.manager)),
                        ],
                        selected: {_role},
                        onSelectionChanged: (value) =>
                            setState(() => _role = value.first),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          final user = _userController.text.trim();
                          if (user.isEmpty) return;
                          ref
                              .read(offlineStoreProvider.notifier)
                              .login(user: user, role: _role);
                        },
                        style: FilledButton.styleFrom(
                          shadowColor:
                              AppThemeTokens.primary.withOpacity(0.3),
                          elevation: 4,
                        ),
                        child: Text(strings.signIn),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
