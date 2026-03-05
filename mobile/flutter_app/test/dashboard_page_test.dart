import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ag_home_organizer_flutter/core/i18n/app_strings.dart';
import 'package:ag_home_organizer_flutter/features/auth/domain/user_session.dart';
import 'package:ag_home_organizer_flutter/features/dashboard/presentation/dashboard_page.dart';
import 'package:ag_home_organizer_flutter/features/offline/application/offline_store.dart';

class _TestOfflineStore extends OfflineStore {
  _TestOfflineStore(this._state);

  final OfflineState _state;

  @override
  OfflineState build() => _state;
}

void main() {
  testWidgets(
    'manager dashboard keeps sections visible when there are no tasks in period',
    (tester) async {
      final seeded = OfflineState(
        session: const UserSession(
          token: 'token',
          name: 'Manager',
          role: UserRole.manager,
        ),
        tasks: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineStoreProvider.overrideWith(() => _TestOfflineStore(seeded)),
          ],
          child: const MaterialApp(
            locale: Locale('en', 'US'),
            supportedLocales: AppStrings.supportedLocales,
            home: DashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Operations'), findsOneWidget);
      expect(find.text('No services in this period.'), findsOneWidget);
      expect(find.text('Monthly closing'), findsOneWidget);
      expect(find.text('Closing wizard'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
    },
  );
}
