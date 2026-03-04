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
  });

  final SyncPushResult pushResult;
  final SyncPullResult pullResult;

  @override
  Future<SyncPullResult> pullChanges({
    required DateTime? since,
    int limit = 500,
  }) async {
    return pullResult;
  }

  @override
  Future<SyncPushResult> pushChanges({
    required String deviceId,
    required DateTime clientTime,
    required List<SyncPushChange> changes,
  }) async {
    return pushResult;
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
        100, // 2h * 50, canceled task excluded
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
            const ConflictLogEntry(
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
            const ConflictLogEntry(
              id: 'conf-2',
              entity: 'finance_entry',
              field: 'amount',
              summary: 'Pull conflict',
              timestamp: DateTime(2026, 1, 2),
            ),
          ],
          auditEntries: [
            const AuditLogEntry(
              id: 'audit-1',
              entity: 'Finance',
              action: 'Updated',
              summary: 'Remote audit',
              actor: 'server',
              timestamp: DateTime(2026, 1, 2),
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
      expect(state.auditLog.any((item) => item.id == 'audit-1'), isTrue);
    });
  });
}
