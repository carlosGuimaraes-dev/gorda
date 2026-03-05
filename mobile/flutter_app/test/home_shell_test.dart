import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ag_home_organizer_flutter/features/auth/domain/user_session.dart';
import 'package:ag_home_organizer_flutter/features/offline/application/offline_store.dart';
import 'package:ag_home_organizer_flutter/features/offline/domain/log_entries.dart';
import 'package:ag_home_organizer_flutter/features/shell/home_shell.dart';

class _TestOfflineStore extends OfflineStore {
  _TestOfflineStore(this._state);

  final OfflineState _state;

  @override
  OfflineState build() => _state;
}

void main() {
  testWidgets('manager role shows clients destination', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeShell(role: UserRole.manager),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final navClientsIcon = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.groups_2_rounded),
    );
    expect(navClientsIcon, findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await tester.pumpAndSettle();

    final menuClientsIcon = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byIcon(Icons.groups_2_rounded),
    );
    expect(menuClientsIcon, findsOneWidget);
  });

  testWidgets('employee role hides clients destination', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeShell(role: UserRole.employee),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final navClientsIcon = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.groups_2_rounded),
    );
    expect(navClientsIcon, findsNothing);

    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await tester.pumpAndSettle();

    final menuClientsIcon = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byIcon(Icons.groups_2_rounded),
    );
    expect(menuClientsIcon, findsNothing);
  });

  testWidgets('home menu shows navigation and catalogs sections', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeShell(role: UserRole.manager),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byIcon(Icons.build_circle_outlined),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.space_dashboard_rounded), findsWidgets);
    expect(find.byIcon(Icons.calendar_today_rounded), findsWidgets);
    expect(find.byIcon(Icons.groups_2_rounded), findsWidgets);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsWidgets);
    expect(find.byIcon(Icons.tune_rounded), findsWidgets);
    expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
    expect(find.byIcon(Icons.flag_circle_outlined), findsOneWidget);
  });

  testWidgets('settings destination shows conflict badge count', (tester) async {
    final seeded = OfflineState(
      conflictLog: [
        ConflictLogEntry(
          id: 'c1',
          entity: 'client',
          field: 'email',
          summary: 'one',
          timestamp: DateTime(2026, 1, 1),
        ),
        ConflictLogEntry(
          id: 'c2',
          entity: 'client',
          field: 'email',
          summary: 'two',
          timestamp: DateTime(2026, 1, 1),
        ),
        ConflictLogEntry(
          id: 'c3',
          entity: 'client',
          field: 'email',
          summary: 'three',
          timestamp: DateTime(2026, 1, 1),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineStoreProvider.overrideWith(() => _TestOfflineStore(seeded)),
        ],
        child: const MaterialApp(
          home: HomeShell(role: UserRole.manager),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
  });
}
