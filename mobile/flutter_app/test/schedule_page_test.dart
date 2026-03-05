import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ag_home_organizer_flutter/features/auth/domain/user_session.dart';
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
}
