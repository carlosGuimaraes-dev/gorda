import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ag_home_organizer_flutter/features/auth/domain/user_session.dart';
import 'package:ag_home_organizer_flutter/features/clients/domain/client.dart';
import 'package:ag_home_organizer_flutter/features/employees/domain/employee.dart';
import 'package:ag_home_organizer_flutter/features/finance/domain/finance_entry.dart';
import 'package:ag_home_organizer_flutter/features/offline/application/offline_store.dart';
import 'package:ag_home_organizer_flutter/features/services/domain/service_task.dart';
import 'package:ag_home_organizer_flutter/features/services/domain/service_type.dart';
import 'package:ag_home_organizer_flutter/features/offline/application/sync_gateway.dart';
import 'package:ag_home_organizer_flutter/features/offline/domain/log_entries.dart';

class _FakeSyncGateway implements SyncGateway {
  _FakeSyncGateway({
    required this.pushResult,
    required this.pullResult,
    this.conflicts = const [],
    this.audit = const [],
  });

  final SyncPushResult pushResult;
  final SyncPullResult pullResult;
  final List<ConflictLogEntry> conflicts;
  final List<AuditLogEntry> audit;
  int pushCalls = 0;
  int pullCalls = 0;
  List<SyncPushChange> lastPushedChanges = const [];
  String? lastDeviceId;
  DateTime? lastClientTime;
  DateTime? lastPullSince;
  int? lastPullLimit;

  @override
  Future<SyncPullResult> pullChanges({
    required DateTime? since,
    int limit = 500,
  }) async {
    pullCalls += 1;
    lastPullSince = since;
    lastPullLimit = limit;
    return pullResult;
  }

  @override
  Future<SyncPushResult> pushChanges({
    required String deviceId,
    required DateTime clientTime,
    required List<SyncPushChange> changes,
  }) async {
    pushCalls += 1;
    lastDeviceId = deviceId;
    lastClientTime = clientTime;
    lastPushedChanges = changes;
    return pushResult;
  }

  @override
  Future<List<ConflictLogEntry>> fetchConflicts({required DateTime? since}) async {
    return conflicts;
  }

  @override
  Future<List<AuditLogEntry>> fetchAudit({required DateTime? since}) async {
    return audit;
  }
}

class _FailingSyncGateway implements SyncGateway {
  @override
  Future<List<AuditLogEntry>> fetchAudit({required DateTime? since}) async {
    throw Exception('offline');
  }

  @override
  Future<List<ConflictLogEntry>> fetchConflicts({required DateTime? since}) async {
    throw Exception('offline');
  }

  @override
  Future<SyncPullResult> pullChanges({required DateTime? since, int limit = 500}) async {
    throw Exception('offline');
  }

  @override
  Future<SyncPushResult> pushChanges({
    required String deviceId,
    required DateTime clientTime,
    required List<SyncPushChange> changes,
  }) async {
    throw Exception('offline');
  }
}

void main() {
  group('OfflineStore critical regression suite', () {
    test('login stores role-based session', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(offlineStoreProvider.notifier);
      notifier.login(user: 'manager-1', role: UserRole.manager);

      final state = container.read(offlineStoreProvider);
      expect(state.session, isNotNull);
      expect(state.session!.role, UserRole.manager);
      expect(state.session!.name, 'manager-1');
    });

    test('canceled tasks are excluded from invoice generation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(offlineStoreProvider.notifier);
      final stateBefore = container.read(offlineStoreProvider);
      final now = DateTime.now();

      notifier.addServiceType(
        const ServiceType(
          id: 'service-hourly',
          name: 'Hourly service',
          basePrice: 50,
          currency: FinanceCurrency.usd,
          pricingModel: ServicePricingModel.perHour,
        ),
      );

      notifier.addTask(
        ServiceTask(
          id: 'task-invoice-valid',
          title: 'Valid task',
          date: now,
          status: TaskStatus.completed,
          assignedEmployeeId: stateBefore.employees.first.id,
          clientId: stateBefore.clients.first.id,
          serviceTypeId: 'service-hourly',
          clientName: stateBefore.clients.first.name,
          address: stateBefore.clients.first.address,
          checkInTime: now.subtract(const Duration(hours: 2)),
          checkOutTime: now,
        ),
      );
      notifier.addTask(
        ServiceTask(
          id: 'task-invoice-canceled',
          title: 'Canceled task',
          date: now,
          status: TaskStatus.canceled,
          assignedEmployeeId: stateBefore.employees.first.id,
          clientId: stateBefore.clients.first.id,
          serviceTypeId: 'service-hourly',
          clientName: stateBefore.clients.first.name,
          address: stateBefore.clients.first.address,
          checkInTime: now.subtract(const Duration(hours: 3)),
          checkOutTime: now,
        ),
      );

      final beforeCount = container.read(offlineStoreProvider).finance.length;
      notifier.generateInvoicesForPeriod(
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
        dueDate: now.add(const Duration(days: 7)),
        clientId: stateBefore.clients.first.id,
      );

      final stateAfter = container.read(offlineStoreProvider);
      final generated = stateAfter.finance.sublist(beforeCount);
      expect(generated, isNotEmpty);
      expect(
        generated.last.amount,
        220, // seed task (120) + valid hourly task (100), canceled task excluded
      );
    });

    test('invoice dispute respects D+N window', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(offlineStoreProvider.notifier);

      final expiredInvoice = FinanceEntry(
        id: 'invoice-expired',
        title: 'Invoice expired',
        amount: 100,
        currency: FinanceCurrency.usd,
        type: FinanceEntryType.receivable,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        status: FinanceStatus.pending,
        kind: FinanceKind.invoiceClient,
      );
      notifier.addFinanceEntry(expiredInvoice);
      notifier.setAppPreferences(
        container.read(offlineStoreProvider).appPreferences.copyWith(
              disputeWindowDays: 0,
            ),
      );

      notifier.markInvoiceDisputed(
        'invoice-expired',
        isDisputed: true,
        reason: 'Late issue',
      );
      final blocked = container
          .read(offlineStoreProvider)
          .finance
          .firstWhere((entry) => entry.id == 'invoice-expired');
      expect(blocked.isDisputed, isFalse);

      notifier.setAppPreferences(
        container.read(offlineStoreProvider).appPreferences.copyWith(
              disputeWindowDays: 7,
            ),
      );
      notifier.markInvoiceDisputed(
        'invoice-expired',
        isDisputed: true,
        reason: 'Allowed by D+N',
      );
      final allowed = container
          .read(offlineStoreProvider)
          .finance
          .firstWhere((entry) => entry.id == 'invoice-expired');
      expect(allowed.isDisputed, isTrue);
      expect(allowed.disputeReason, 'Allowed by D+N');
    });

    test('reissue creates successor and links superseded invoice', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(offlineStoreProvider.notifier);
      final state = container.read(offlineStoreProvider);
      final source =
          state.finance.firstWhere((entry) => entry.kind == FinanceKind.invoiceClient);

      notifier.reissueInvoice(
        entryId: source.id,
        amount: 777,
        dueDate: DateTime.now().add(const Duration(days: 30)),
      );

      final updatedState = container.read(offlineStoreProvider);
      final old = updatedState.finance.firstWhere((entry) => entry.id == source.id);
      final replacement = updatedState.finance.firstWhere(
        (entry) => entry.supersedesId == source.id,
      );

      expect(old.supersededById, isNotNull);
      expect(replacement.id, old.supersededById);
      expect(replacement.amount, 777);
      expect(replacement.kind, FinanceKind.invoiceClient);
    });

    test('payroll generation uses check-in/out and excludes canceled tasks', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(offlineStoreProvider.notifier);

      notifier.addEmployee(
        const Employee(
          id: 'emp-payroll',
          name: 'Payroll Employee',
          team: 'Team X',
          roleTitle: 'Tech',
          currency: EmployeeCurrency.usd,
          hourlyRate: 25,
        ),
      );

      final now = DateTime.now();
      notifier.addTask(
        ServiceTask(
          id: 'task-payroll-valid',
          title: 'Payroll valid',
          date: now,
          status: TaskStatus.completed,
          assignedEmployeeId: 'emp-payroll',
          clientName: 'Client',
          address: 'Addr',
          checkInTime: now.subtract(const Duration(hours: 4)),
          checkOutTime: now.subtract(const Duration(hours: 1)),
        ),
      );
      notifier.addTask(
        ServiceTask(
          id: 'task-payroll-canceled',
          title: 'Payroll canceled',
          date: now,
          status: TaskStatus.canceled,
          assignedEmployeeId: 'emp-payroll',
          clientName: 'Client',
          address: 'Addr',
          checkInTime: now.subtract(const Duration(hours: 5)),
          checkOutTime: now.subtract(const Duration(hours: 1)),
        ),
      );

      final beforeCount = container.read(offlineStoreProvider).finance.length;
      notifier.generatePayrollsForPeriod(
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
        dueDate: now.add(const Duration(days: 7)),
        employeeId: 'emp-payroll',
      );

      final generated = container.read(offlineStoreProvider).finance.sublist(beforeCount);
      expect(generated, isNotEmpty);
      final payroll = generated.last;
      expect(payroll.kind, FinanceKind.payrollEmployee);
      expect(payroll.payrollHoursWorked, 3); // valid task only
      expect(payroll.amount, 75); // 3h * 25
    });

    test('check-in transitions task from scheduled to inProgress', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(offlineStoreProvider.notifier);
      final state = container.read(offlineStoreProvider);
      final timestamp = DateTime(2026, 1, 10, 9, 30);

      notifier.addTask(
        ServiceTask(
          id: 'task-checkin-transition',
          title: 'Check-in transition',
          date: timestamp,
          status: TaskStatus.scheduled,
          assignedEmployeeId: state.employees.first.id,
          clientName: 'Client',
          address: 'Address',
        ),
      );

      notifier.markTaskCheckIn('task-checkin-transition', timestamp);
      final updatedTask = container
          .read(offlineStoreProvider)
          .tasks
          .firstWhere((task) => task.id == 'task-checkin-transition');

      expect(updatedTask.checkInTime, timestamp);
      expect(updatedTask.status, TaskStatus.inProgress);
    });

    test('checkout without check-in does not set checkOutTime', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(offlineStoreProvider.notifier);
      final state = container.read(offlineStoreProvider);
      final timestamp = DateTime(2026, 1, 10, 10, 0);

      notifier.addTask(
        ServiceTask(
          id: 'task-checkout-without-checkin',
          title: 'Checkout without checkin',
          date: timestamp,
          status: TaskStatus.inProgress,
          assignedEmployeeId: state.employees.first.id,
          clientName: 'Client',
          address: 'Address',
        ),
      );

      notifier.markTaskCheckOut('task-checkout-without-checkin', timestamp);
      final updatedTask = container
          .read(offlineStoreProvider)
          .tasks
          .firstWhere((task) => task.id == 'task-checkout-without-checkin');

      expect(updatedTask.checkOutTime, isNull);
    });

    test('checkout before check-in does not set checkOutTime', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(offlineStoreProvider.notifier);
      final state = container.read(offlineStoreProvider);
      final checkInTime = DateTime(2026, 1, 10, 11, 0);
      final invalidCheckOut = DateTime(2026, 1, 10, 10, 30);

      notifier.addTask(
        ServiceTask(
          id: 'task-checkout-before-checkin',
          title: 'Checkout before checkin',
          date: checkInTime,
          status: TaskStatus.scheduled,
          assignedEmployeeId: state.employees.first.id,
          clientName: 'Client',
          address: 'Address',
        ),
      );
      notifier.markTaskCheckIn('task-checkout-before-checkin', checkInTime);
      notifier.markTaskCheckOut('task-checkout-before-checkin', invalidCheckOut);

      final updatedTask = container
          .read(offlineStoreProvider)
          .tasks
          .firstWhere((task) => task.id == 'task-checkout-before-checkin');

      expect(updatedTask.checkInTime, checkInTime);
      expect(updatedTask.checkOutTime, isNull);
    });

    test('sync stub clears queue and updates lastSync', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(offlineStoreProvider.notifier);

      notifier.addClient(
        const Client(
          id: 'sync-client',
          name: 'Sync Client',
          address: 'Addr',
          phone: '+1',
        ),
      );
      notifier.updateClient(
        const Client(
          id: 'sync-client',
          name: 'Sync Client Updated',
          address: 'Addr',
          phone: '+1',
        ),
      );
      final queuedBefore = container.read(offlineStoreProvider).pendingChanges.length;
      expect(queuedBefore, greaterThan(0));

      notifier.syncPendingChangesStub();
      final after = container.read(offlineStoreProvider);
      expect(after.pendingChanges, isEmpty);
      expect(after.lastSync, isNotNull);
    });

    test('syncPendingChanges merges remote conflicts and audit entries', () async {
      final now = DateTime.now();
      final fakeGateway = _FakeSyncGateway(
        pushResult: SyncPushResult(
          serverTime: now,
          conflicts: [
            ConflictLogEntry(
              id: 'conf-1',
              entity: 'client',
              field: 'email',
              summary: 'Push conflict',
              timestamp: DateTime(2026, 1, 1),
            ),
          ],
        ),
        pullResult: SyncPullResult(
          serverTime: now.add(const Duration(minutes: 1)),
          conflicts: [
            ConflictLogEntry(
              id: 'conf-2',
              entity: 'finance_entry',
              field: 'amount',
              summary: 'Pull conflict',
              timestamp: DateTime(2026, 1, 2),
            ),
          ],
          auditEntries: [
            AuditLogEntry(
              id: 'audit-1',
              entity: 'Finance',
              action: 'Updated',
              summary: 'Remote audit',
              actor: 'server',
              timestamp: DateTime(2026, 1, 2),
            ),
          ],
        ),
        conflicts: [
          ConflictLogEntry(
            id: 'conf-3',
            entity: 'task',
            field: 'status',
            summary: 'Endpoint conflict',
            timestamp: DateTime(2026, 1, 3),
          ),
        ],
        audit: [
          AuditLogEntry(
            id: 'audit-2',
            entity: 'Client',
            action: 'Created',
            summary: 'Endpoint audit',
            actor: 'server',
            timestamp: DateTime(2026, 1, 3),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          syncGatewayProvider.overrideWithValue(fakeGateway),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(offlineStoreProvider.notifier);

      notifier.addClient(
        const Client(
          id: 'sync-real-client',
          name: 'Sync Real',
          address: 'Addr',
          phone: '+1',
        ),
      );

      await notifier.syncPendingChanges();
      final state = container.read(offlineStoreProvider);
      expect(state.pendingChanges, isEmpty);
      expect(state.lastSync, now.add(const Duration(minutes: 1)));
      expect(state.conflictLog.any((item) => item.id == 'conf-1'), isTrue);
      expect(state.conflictLog.any((item) => item.id == 'conf-2'), isTrue);
      expect(state.conflictLog.any((item) => item.id == 'conf-3'), isTrue);
      expect(state.auditLog.any((item) => item.id == 'audit-1'), isTrue);
      expect(state.auditLog.any((item) => item.id == 'audit-2'), isTrue);
    });

    test('syncPendingChanges sends schedule payload for queued task changes', () async {
      final pushTime = DateTime.parse('2026-03-05T10:00:00Z');
      final pullTime = DateTime.parse('2026-03-05T10:01:00Z');
      final fakeGateway = _FakeSyncGateway(
        pushResult: SyncPushResult(serverTime: pushTime),
        pullResult: SyncPullResult(serverTime: pullTime),
      );

      final container = ProviderContainer(
        overrides: [
          syncGatewayProvider.overrideWithValue(fakeGateway),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(offlineStoreProvider.notifier);
      final state = container.read(offlineStoreProvider);

      final date = DateTime(2026, 3, 6, 9, 0);
      final startTime = DateTime(2026, 3, 6, 9, 0);
      final endTime = DateTime(2026, 3, 6, 11, 0);
      notifier.addTask(
        ServiceTask(
          id: 'task-sync-payload',
          title: 'Schedule payload task',
          date: date,
          status: TaskStatus.scheduled,
          assignedEmployeeId: state.employees.first.id,
          clientId: state.clients.first.id,
          serviceTypeId: state.serviceTypes.first.id,
          clientName: state.clients.first.name,
          address: state.clients.first.address,
          startTime: startTime,
          endTime: endTime,
          notes: 'Bring supplies',
        ),
      );
      notifier.updateTaskStatus(
        taskId: 'task-sync-payload',
        status: TaskStatus.inProgress,
      );

      await notifier.syncPendingChanges();

      expect(fakeGateway.pushCalls, 1);
      expect(fakeGateway.lastPushedChanges, hasLength(1));
      final pushed = fakeGateway.lastPushedChanges.first;
      expect(pushed.entity, 'task');
      expect(pushed.entityId, 'task-sync-payload');
      expect(pushed.operation, 'upsert');
      expect(pushed.payload['title'], 'Schedule payload task');
      expect(pushed.payload['status'], 'inProgress');
      expect(pushed.payload['notes'], 'Bring supplies');
      expect(pushed.payload['clientName'], state.clients.first.name);
      expect(pushed.payload['address'], state.clients.first.address);
      expect(
        DateTime.parse('${pushed.payload['date']}').toUtc(),
        date.toUtc(),
      );
      expect(
        DateTime.parse('${pushed.payload['startTime']}').toUtc(),
        startTime.toUtc(),
      );
      expect(
        DateTime.parse('${pushed.payload['endTime']}').toUtc(),
        endTime.toUtc(),
      );
      expect(container.read(offlineStoreProvider).pendingChanges, isEmpty);
      expect(container.read(offlineStoreProvider).lastSync, pullTime);
    });

    test('syncPendingChanges applies remote schedule changes without local queue', () async {
      final pullTime = DateTime.parse('2026-03-05T11:00:00Z');
      final remoteDate = DateTime.parse('2026-03-07T12:00:00Z');
      final fakeGateway = _FakeSyncGateway(
        pushResult: SyncPushResult(serverTime: DateTime.parse('2026-03-05T10:59:00Z')),
        pullResult: SyncPullResult(
          serverTime: pullTime,
          changes: [
            SyncRemoteChange(
              entity: 'task',
              entityId: 'remote-task-1',
              operation: 'upsert',
              serverUpdatedAt: DateTime.parse('2026-03-05T10:59:30Z'),
              payload: {
                'title': 'Remote schedule task',
                'date': remoteDate.toUtc().toIso8601String(),
                'status': 'completed',
                'assignedEmployeeId': 'maria',
                'clientId': 'client-1',
                'serviceTypeId': 'service-cleaning',
                'clientName': 'Smith Family',
                'address': '241 Oak Street',
                'notes': 'Remote note',
              },
            ),
          ],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          syncGatewayProvider.overrideWithValue(fakeGateway),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(offlineStoreProvider.notifier);

      expect(container.read(offlineStoreProvider).pendingChanges, isEmpty);

      await notifier.syncPendingChanges();

      final state = container.read(offlineStoreProvider);
      final remoteTask =
          state.tasks.firstWhere((task) => task.id == 'remote-task-1');
      expect(fakeGateway.pushCalls, 0);
      expect(fakeGateway.pullCalls, 1);
      expect(remoteTask.title, 'Remote schedule task');
      expect(remoteTask.status, TaskStatus.completed);
      expect(remoteTask.clientId, 'client-1');
      expect(remoteTask.clientName, 'Smith Family');
      expect(remoteTask.address, '241 Oak Street');
      expect(remoteTask.notes, 'Remote note');
      expect(remoteTask.date.toUtc(), remoteDate.toUtc());
      expect(state.lastSync, pullTime);
    });

    test(
      'syncPendingChanges creates conflict and keeps local task when remote collides with local pending',
      () async {
        final pullTime = DateTime.parse('2026-03-05T12:00:00Z');
        final fakeGateway = _FakeSyncGateway(
          pushResult: SyncPushResult(serverTime: DateTime.parse('2026-03-05T11:59:00Z')),
          pullResult: SyncPullResult(
            serverTime: pullTime,
            changes: [
              SyncRemoteChange(
                entity: 'task',
                entityId: 'task-conflict-1',
                operation: 'upsert',
                serverUpdatedAt: DateTime.parse('2026-03-05T11:59:30Z'),
                payload: {
                  'title': 'Remote title',
                  'date': DateTime(2026, 3, 8, 14, 0).toUtc().toIso8601String(),
                  'status': 'completed',
                  'assignedEmployeeId': 'maria',
                  'clientName': 'Smith Family',
                  'address': '241 Oak Street',
                },
              ),
            ],
          ),
        );

        final container = ProviderContainer(
          overrides: [
            syncGatewayProvider.overrideWithValue(fakeGateway),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(offlineStoreProvider.notifier);

        notifier.addTask(
          ServiceTask(
            id: 'task-conflict-1',
            title: 'Local title',
            date: DateTime(2026, 3, 8, 14, 0),
            status: TaskStatus.scheduled,
            assignedEmployeeId: 'maria',
            clientName: 'Smith Family',
            address: '241 Oak Street',
          ),
        );
        notifier.updateTaskStatus(
          taskId: 'task-conflict-1',
          status: TaskStatus.inProgress,
        );

        await notifier.syncPendingChanges();

        final state = container.read(offlineStoreProvider);
        final task = state.tasks.firstWhere((item) => item.id == 'task-conflict-1');
        expect(task.title, 'Local title');
        expect(task.status, TaskStatus.inProgress);
        expect(state.pendingChanges, isEmpty);
        expect(
          state.conflictLog.any(
            (entry) =>
                entry.entity == 'task' &&
                entry.summary.contains('task-conflict-1'),
          ),
          isTrue,
        );
      },
    );

    test(
      'syncPendingChanges merges remote task and preserves only locally edited fields',
      () async {
        final pullTime = DateTime.parse('2026-03-05T12:30:00Z');
        final fakeGateway = _FakeSyncGateway(
          pushResult: SyncPushResult(
            serverTime: DateTime.parse('2026-03-05T12:29:00Z'),
            applied: const [
              SyncAppliedChange(
                entity: 'task',
                entityId: 'task-1',
                operation: 'upsert',
              ),
            ],
          ),
          pullResult: SyncPullResult(
            serverTime: pullTime,
            changes: [
              SyncRemoteChange(
                entity: 'task',
                entityId: 'task-1',
                operation: 'upsert',
                serverUpdatedAt: DateTime.parse('2026-03-05T12:29:30Z'),
                payload: {
                  'title': 'Remote Retitled Task',
                  'date': DateTime(2026, 3, 10, 8, 0).toUtc().toIso8601String(),
                  'status': 'completed',
                  'assignedEmployeeId': 'lucas',
                  'clientId': 'client-2',
                  'serviceTypeId': 'service-grocery',
                  'clientName': 'Johnson Residence',
                  'address': '110 Pine Avenue',
                  'notes': 'Remote merged note',
                },
              ),
            ],
          ),
        );

        final container = ProviderContainer(
          overrides: [
            syncGatewayProvider.overrideWithValue(fakeGateway),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(offlineStoreProvider.notifier);

        notifier.updateTaskStatus(
          taskId: 'task-1',
          status: TaskStatus.inProgress,
        );
        await notifier.syncPendingChanges();

        final state = container.read(offlineStoreProvider);
        final task = state.tasks.firstWhere((item) => item.id == 'task-1');
        expect(task.status, TaskStatus.inProgress); // local field preserved
        expect(task.title, 'Remote Retitled Task'); // remote field merged
        expect(task.clientId, 'client-2');
        expect(task.clientName, 'Johnson Residence');
        expect(task.address, '110 Pine Avenue');
        expect(task.notes, 'Remote merged note');
        expect(state.pendingChanges, isEmpty);
        expect(
          state.conflictLog.any(
            (entry) =>
                entry.entity == 'task' &&
                entry.field == 'status' &&
                entry.summary.contains('task-1'),
          ),
          isTrue,
        );
        expect(state.lastSync, pullTime);
      },
    );

    test('syncPendingChanges keeps rejected changes in offline queue', () async {
      final pullTime = DateTime.parse('2026-03-05T13:00:00Z');
      final fakeGateway = _FakeSyncGateway(
        pushResult: SyncPushResult(
          serverTime: DateTime.parse('2026-03-05T12:59:00Z'),
          rejected: const [
            SyncRejectedChange(
              entity: 'client',
              entityId: 'sync-rejected-client',
              operation: 'upsert',
              reason: 'missing_required_fields',
              summary: 'Rejected client payload',
              fields: ['name'],
            ),
          ],
        ),
        pullResult: SyncPullResult(serverTime: pullTime),
      );

      final container = ProviderContainer(
        overrides: [
          syncGatewayProvider.overrideWithValue(fakeGateway),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(offlineStoreProvider.notifier);

      notifier.addClient(
        const Client(
          id: 'sync-rejected-client',
          name: 'Rejected Client',
          address: 'Addr',
          phone: '+1',
        ),
      );

      await notifier.syncPendingChanges();

      final state = container.read(offlineStoreProvider);
      expect(
        state.pendingChanges
            .any((item) => item.entityId == 'sync-rejected-client'),
        isTrue,
      );
      expect(
        state.conflictLog.any((item) => item.summary == 'Rejected client payload'),
        isTrue,
      );
      expect(state.lastSync, pullTime);
    });

    test('syncPendingChanges keeps queue on network error', () async {
      final container = ProviderContainer(
        overrides: [
          syncGatewayProvider.overrideWithValue(_FailingSyncGateway()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(offlineStoreProvider.notifier);

      notifier.addClient(
        const Client(
          id: 'sync-fail-client',
          name: 'Sync Fail',
          address: 'Addr',
          phone: '+1',
        ),
      );

      final queuedBefore = container.read(offlineStoreProvider).pendingChanges.length;
      expect(queuedBefore, greaterThan(0));

      await notifier.syncPendingChanges();
      final state = container.read(offlineStoreProvider);
      expect(state.pendingChanges.length, queuedBefore);
      expect(
        state.auditLog.any((item) => item.entity == 'Sync' && item.action == 'Error'),
        isTrue,
      );
    });
  });
}
