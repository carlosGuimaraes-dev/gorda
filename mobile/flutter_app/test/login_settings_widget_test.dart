import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ag_home_organizer_flutter/features/auth/domain/user_session.dart';
import 'package:ag_home_organizer_flutter/features/auth/presentation/login_page.dart';
import 'package:ag_home_organizer_flutter/features/offline/application/offline_store.dart';
import 'package:ag_home_organizer_flutter/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('login shows role selector in same screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.text('Employee'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);
  });

  testWidgets('settings notification toggle persists in OfflineStore',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(offlineStoreProvider.notifier)
        .login(user: 'manager', role: UserRole.manager);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    final before = container
        .read(offlineStoreProvider)
        .notificationPreferences
        .enableClientNotifications;

    await tester.tap(find.text('Notifications for clients'));
    await tester.pumpAndSettle();

    final after = container
        .read(offlineStoreProvider)
        .notificationPreferences
        .enableClientNotifications;

    expect(after, isNot(equals(before)));
  });
}
