import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ag_home_organizer_flutter/features/auth/domain/user_session.dart';
import 'package:ag_home_organizer_flutter/features/clients/domain/client.dart';
import 'package:ag_home_organizer_flutter/features/employees/domain/employee.dart';
import 'package:ag_home_organizer_flutter/features/offline/application/offline_store.dart';
import 'package:ag_home_organizer_flutter/features/schedule/presentation/schedule_page.dart';
import 'package:ag_home_organizer_flutter/features/services/domain/service_task.dart';

class _TestOfflineStore extends OfflineStore {
  _TestOfflineStore(this._state);

  final OfflineState _state;

  @override
  OfflineState build() => _state;
}

void main() {
  testWidgets(
    'employee sees assigned task when session stores employee name instead of id',
    (tester) async {
      final now = DateTime.now();
      final seeded = OfflineState(
        session: const UserSession(
          token: 'token',
          name: 'Maria',
          role: UserRole.employee,
        ),
        employees: const [
          Employee(
            id: 'maria',
            name: 'Maria',
            team: 'Team A',
            roleTitle: 'Technician',
          ),
        ],
        tasks: [
          ServiceTask(
            id: 'task-1',
            title: 'Weekly cleaning',
            date: now,
            status: TaskStatus.scheduled,
            assignedEmployeeId: 'maria',
            clientName: 'Smith Family',
            address: '241 Oak Street',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineStoreProvider.overrideWith(() => _TestOfflineStore(seeded)),
          ],
          child: const MaterialApp(
            home: SchedulePage(role: UserRole.employee),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Weekly cleaning'), findsOneWidget);
      expect(find.text('No services found for this filter.'), findsNothing);
    },
  );

  testWidgets('new service dialog validates required fields and saves',
      (tester) async {
    final now = DateTime.now();
    final seeded = OfflineState(
      session: const UserSession(
        token: 'token',
        name: 'Manager',
        role: UserRole.manager,
      ),
      employees: const [
        Employee(
          id: 'emp-1',
          name: 'Maria',
          team: 'Team A',
          roleTitle: 'Technician',
        ),
      ],
      clients: const [
        Client(
          id: 'client-1',
          name: 'Smith Family',
          address: '241 Oak Street',
        ),
      ],
      tasks: [
        ServiceTask(
          id: 'seed-task',
          title: 'Existing service',
          date: now,
          status: TaskStatus.scheduled,
          assignedEmployeeId: 'emp-1',
          clientName: 'Smith Family',
          address: '241 Oak Street',
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        offlineStoreProvider.overrideWith(() => _TestOfflineStore(seeded)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SchedulePage(role: UserRole.manager),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('schedule_add_service_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('schedule_form_client_picker')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('schedule_form_save_button')));
    await tester.pumpAndSettle();
    expect(find.text('Complete required fields.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('schedule_form_title')),
      'Window cleaning',
    );
    await tester.tap(find.byKey(const ValueKey('schedule_form_save_button')));
    await tester.pumpAndSettle();

    final hasNewTask = container
        .read(offlineStoreProvider)
        .tasks
        .any((task) => task.title == 'Window cleaning');
    expect(hasNewTask, isTrue);
  });
}
