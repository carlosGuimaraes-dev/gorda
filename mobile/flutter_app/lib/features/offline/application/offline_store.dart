import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/domain/user_session.dart';
import '../../clients/domain/client.dart';
import '../../employees/domain/employee.dart';
import '../../finance/domain/finance_entry.dart';
import '../../services/domain/service_task.dart';
import '../domain/pending_change.dart';

final offlineStoreProvider =
    NotifierProvider<OfflineStore, OfflineState>(OfflineStore.new);

class OfflineState {
  const OfflineState({
    this.clients = const [],
    this.employees = const [],
    this.tasks = const [],
    this.finance = const [],
    this.pendingChanges = const [],
    this.session,
    this.lastSync,
    this.languageCode = 'en',
    this.countryCode = 'US',
  });

  final List<Client> clients;
  final List<Employee> employees;
  final List<ServiceTask> tasks;
  final List<FinanceEntry> finance;
  final List<PendingChange> pendingChanges;
  final UserSession? session;
  final DateTime? lastSync;
  final String languageCode;
  final String countryCode;

  OfflineState copyWith({
    List<Client>? clients,
    List<Employee>? employees,
    List<ServiceTask>? tasks,
    List<FinanceEntry>? finance,
    List<PendingChange>? pendingChanges,
    UserSession? session,
    bool clearSession = false,
    DateTime? lastSync,
    String? languageCode,
    String? countryCode,
  }) {
    return OfflineState(
      clients: clients ?? this.clients,
      employees: employees ?? this.employees,
      tasks: tasks ?? this.tasks,
      finance: finance ?? this.finance,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      session: clearSession ? null : (session ?? this.session),
      lastSync: lastSync ?? this.lastSync,
      languageCode: languageCode ?? this.languageCode,
      countryCode: countryCode ?? this.countryCode,
    );
  }
}

class OfflineStore extends Notifier<OfflineState> {
  final Uuid _uuid = const Uuid();

  @override
  OfflineState build() {
    return _seedState();
  }

  String get languageCode => state.languageCode;
  String get countryCode => state.countryCode;
  UserSession? get session => state.session;

  void login({required String user, required UserRole role}) {
    final normalizedUser = user.trim();
    if (normalizedUser.isEmpty) return;

    var employees = state.employees;
    if (role == UserRole.employee &&
        employees.every((employee) => employee.id != normalizedUser)) {
      employees = [
        ...employees,
        Employee(
          id: normalizedUser,
          name: normalizedUser,
          team: 'Field',
          roleTitle: 'Field Employee',
          currency: EmployeeCurrency.usd,
        ),
      ];
    }

    state = state.copyWith(
      employees: employees,
      session: UserSession(token: _uuid.v4(), name: normalizedUser, role: role),
    );
  }

  void logout() {
    state = state.copyWith(clearSession: true);
  }

  void setLocale({required String languageCode, required String countryCode}) {
    state =
        state.copyWith(languageCode: languageCode, countryCode: countryCode);
  }

  void addClient(Client client) {
    final nextClients = [...state.clients, client];
    state = state.copyWith(
      clients: nextClients,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.addClient,
        client.id,
      ),
    );
  }

  void addTask(ServiceTask task) {
    final nextTasks = [...state.tasks, task]
      ..sort((a, b) => a.date.compareTo(b.date));
    state = state.copyWith(
      tasks: nextTasks,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.addTask,
        task.id,
      ),
    );
  }

  void updateTaskStatus({required String taskId, required TaskStatus status}) {
    final index = state.tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return;

    final updated = state.tasks[index].copyWith(status: status);
    final nextTasks = [...state.tasks];
    nextTasks[index] = updated;

    state = state.copyWith(
      tasks: nextTasks,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.updateTask,
        taskId,
      ),
    );
  }

  void syncPendingChangesStub() {
    if (state.pendingChanges.isEmpty) {
      state = state.copyWith(lastSync: DateTime.now());
      return;
    }

    final latestByEntity = <String, PendingChange>{};
    final sorted = [...state.pendingChanges]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    for (final item in sorted) {
      latestByEntity[item.entityId] = item;
    }

    state = state.copyWith(
      pendingChanges: const [],
      lastSync: DateTime.now(),
    );

    // TODO: Replace by real API sync + conflict resolution.
    // This mirrors the current Swift OfflineStore stub behavior.
    if (latestByEntity.isNotEmpty) {
      // ignore: avoid_print
      print('Synced ${latestByEntity.length} entities (stub).');
    }
  }

  List<PendingChange> _enqueueChange(
    List<PendingChange> queue,
    PendingOperation operation,
    String entityId,
  ) {
    return [
      ...queue,
      PendingChange(
        operation: operation,
        entityId: entityId,
        timestamp: DateTime.now(),
      ),
    ];
  }

  OfflineState _seedState() {
    final employees = [
      const Employee(
        id: 'maria',
        name: 'Maria',
        roleTitle: 'Team Lead',
        team: 'Team A',
        currency: EmployeeCurrency.usd,
        hourlyRate: 22,
      ),
      const Employee(
        id: 'lucas',
        name: 'Lucas',
        roleTitle: 'Technician',
        team: 'Team B',
        currency: EmployeeCurrency.usd,
        hourlyRate: 20,
      ),
    ];

    final clients = [
      const Client(
        id: 'client-1',
        name: 'Smith Family',
        address: '241 Oak Street',
        phone: '+1 415 555 0101',
      ),
      const Client(
        id: 'client-2',
        name: 'Johnson Residence',
        address: '110 Pine Avenue',
        phone: '+1 415 555 0188',
      ),
    ];

    final now = DateTime.now();
    final tasks = [
      ServiceTask(
        id: 'task-1',
        title: 'Weekly cleaning',
        date: now,
        status: TaskStatus.scheduled,
        assignedEmployeeId: 'maria',
        clientId: clients.first.id,
        clientName: clients.first.name,
        address: clients.first.address,
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 11, 0),
      ),
      ServiceTask(
        id: 'task-2',
        title: 'Grocery run',
        date: now.add(const Duration(days: 1)),
        status: TaskStatus.inProgress,
        assignedEmployeeId: 'lucas',
        clientId: clients.last.id,
        clientName: clients.last.name,
        address: clients.last.address,
        startTime: DateTime(now.year, now.month, now.day + 1, 14, 0),
        endTime: DateTime(now.year, now.month, now.day + 1, 15, 0),
      ),
    ];

    return OfflineState(
      clients: clients,
      employees: employees,
      tasks: tasks,
    );
  }
}
