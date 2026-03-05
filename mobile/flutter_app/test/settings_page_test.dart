import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ag_home_organizer_flutter/features/auth/domain/user_session.dart';
import 'package:ag_home_organizer_flutter/features/offline/application/offline_store.dart';
import 'package:ag_home_organizer_flutter/features/offline/domain/app_preferences.dart';
import 'package:ag_home_organizer_flutter/features/settings/presentation/settings_page.dart';

class _TestOfflineStore extends OfflineStore {
  _TestOfflineStore(this._state);

  final OfflineState _state;

  @override
  OfflineState build() => _state;
}

void main() {
  testWidgets('shows warning when all delivery channels are disabled',
      (tester) async {
    final seeded = OfflineState(
      session: const UserSession(
        token: 'token',
        name: 'manager',
        role: UserRole.manager,
      ),
      appPreferences: const AppPreferences(
        enableWhatsApp: false,
        enableTextMessages: false,
        enableEmail: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineStoreProvider.overrideWith(() => _TestOfflineStore(seeded)),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(
        'No active channels. Enable at least one to avoid delivery failures.',
      ),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No active channels. Enable at least one to avoid delivery failures.',
      ),
      findsOneWidget,
    );
  });
}
