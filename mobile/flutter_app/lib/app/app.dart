import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/user_session.dart';
import '../features/auth/presentation/login_page.dart';
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
  ProviderSubscription<AsyncValue<UserSession?>>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
    _authSubscription = ref.listenManual<AsyncValue<UserSession?>>(
      authStateProvider,
      (previous, next) {
        final storeNotifier = ref.read(offlineStoreProvider.notifier);
        final storeSession = ref.read(offlineStoreProvider).session;
        final session = next.valueOrNull;

        if (session == null) {
          if (storeSession != null) {
            storeNotifier.logout();
          }
          return;
        }

        if (storeSession?.name == session.name &&
            storeSession?.role == session.role) {
          return;
        }

        storeNotifier.login(user: session.name, role: session.role);
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(offlineStoreProvider);
    final locale = Locale(store.languageCode, store.countryCode);
    
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'AG Home Organizer',
      theme: buildAppTheme(),
      locale: locale,
      supportedLocales: AppStrings.supportedLocales,
      home: _showSplash || authState.isLoading
          ? const SplashView()
          : authState.value == null
              ? const LoginPage()
              : HomeShell(role: authState.value!.role),
    );
  }
}
