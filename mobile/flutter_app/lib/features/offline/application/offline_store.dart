import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/domain/user_session.dart';
import '../../clients/domain/client.dart';
import '../../employees/domain/employee.dart';
import '../../finance/domain/finance_entry.dart';
import '../../services/domain/service_type.dart';
import '../../services/domain/service_task.dart';
import '../../teams/domain/team.dart';
import '../domain/pending_change.dart';

final offlineStoreProvider =
    NotifierProvider<OfflineStore, OfflineState>(OfflineStore.new);

class OfflineState {
  const OfflineState({
    this.clients = const [],
    this.employees = const [],
    this.teams = const [],
    this.tasks = const [],
    this.serviceTypes = const [],
    this.finance = const [],
    this.pendingChanges = const [],
    this.session,
    this.lastSync,
    this.languageCode = 'en',
    this.countryCode = 'US',
  });

  final List<Client> clients;
  final List<Employee> employees;
  final List<Team> teams;
  final List<ServiceTask> tasks;
  final List<ServiceType> serviceTypes;
  final List<FinanceEntry> finance;
  final List<PendingChange> pendingChanges;
  final UserSession? session;
  final DateTime? lastSync;
  final String languageCode;
  final String countryCode;

  OfflineState copyWith({
    List<Client>? clients,
    List<Employee>? employees,
    List<Team>? teams,
    List<ServiceTask>? tasks,
    List<ServiceType>? serviceTypes,
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
      teams: teams ?? this.teams,
      tasks: tasks ?? this.tasks,
      serviceTypes: serviceTypes ?? this.serviceTypes,
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
    final teams = _normalizeTeams(
      currentTeams: state.teams,
      employees: employees,
    );

    state = state.copyWith(
      employees: employees,
      teams: teams,
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

  void updateClient(Client client) {
    final index = state.clients.indexWhere((item) => item.id == client.id);
    if (index < 0) return;
    final nextClients = [...state.clients];
    nextClients[index] = client;
    state = state.copyWith(
      clients: nextClients,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.updateClient,
        client.id,
      ),
    );
  }

  bool deleteClient(String clientId) {
    final hasLinkedTasks = state.tasks.any((task) => task.clientId == clientId);
    final hasLinkedFinance =
        state.finance.any((entry) => entry.clientId == clientId);
    if (hasLinkedTasks || hasLinkedFinance) return false;

    final nextClients =
        state.clients.where((item) => item.id != clientId).toList();
    state = state.copyWith(
      clients: nextClients,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.deleteClient,
        clientId,
      ),
    );
    return true;
  }

  void addEmployee(Employee employee) {
    final next = [...state.employees, employee]
      ..sort((a, b) => a.name.compareTo(b.name));
    final nextTeams = _normalizeTeams(
      currentTeams: state.teams,
      employees: next,
    );
    state = state.copyWith(
      employees: next,
      teams: nextTeams,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.addEmployee,
        employee.id,
      ),
    );
  }

  void updateEmployee(Employee employee) {
    final index = state.employees.indexWhere((item) => item.id == employee.id);
    if (index < 0) return;
    final next = [...state.employees];
    next[index] = employee;
    final nextTeams = _normalizeTeams(
      currentTeams: state.teams,
      employees: next,
    );
    state = state.copyWith(
      employees: next,
      teams: nextTeams,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.updateEmployee,
        employee.id,
      ),
    );
  }

  bool deleteEmployee(String employeeId) {
    final hasLinkedTasks =
        state.tasks.any((task) => task.assignedEmployeeId == employeeId);
    final hasLinkedFinance =
        state.finance.any((entry) => entry.employeeId == employeeId);
    if (hasLinkedTasks || hasLinkedFinance) return false;

    final next =
        state.employees.where((item) => item.id != employeeId).toList();
    state = state.copyWith(
      employees: next,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.deleteEmployee,
        employeeId,
      ),
    );
    return true;
  }

  bool createTeam({
    required String teamName,
    List<String> memberIds = const [],
  }) {
    final normalizedName = teamName.trim();
    if (normalizedName.isEmpty) return false;

    final teamExists = state.teams.any((team) => _sameTeamName(
          team.name,
          normalizedName,
        ));
    if (teamExists) return false;

    final newTeam = Team(
      id: 'team-${_uuid.v4()}',
      name: normalizedName,
    );
    final nextTeams = [...state.teams, newTeam]
      ..sort((a, b) => a.name.compareTo(b.name));

    final selectedIds = memberIds.toSet();
    final changedEmployeeIds = <String>[];
    final nextEmployees = state.employees.map((employee) {
      if (!selectedIds.contains(employee.id)) return employee;
      changedEmployeeIds.add(employee.id);
      return employee.copyWith(team: normalizedName);
    }).toList();

    var nextPending = _enqueueChange(
      state.pendingChanges,
      PendingOperation.addTeam,
      newTeam.id,
    );
    if (changedEmployeeIds.isNotEmpty) {
      nextPending = _enqueueBatchChanges(
        nextPending,
        PendingOperation.updateEmployee,
        changedEmployeeIds,
      );
    }

    state = state.copyWith(
      teams: nextTeams,
      employees: nextEmployees,
      pendingChanges: nextPending,
    );
    return true;
  }

  bool updateTeam({
    required String oldName,
    required String newName,
    required List<String> memberIds,
  }) {
    final normalizedOld = oldName.trim();
    final normalizedNew = newName.trim();
    if (normalizedOld.isEmpty || normalizedNew.isEmpty) return false;

    final teamIndex = state.teams.indexWhere(
      (team) => _sameTeamName(team.name, normalizedOld),
    );
    if (teamIndex < 0) return false;
    final currentTeam = state.teams[teamIndex];

    final nameTaken =
        !_sameTeamName(normalizedOld, normalizedNew) &&
            state.teams.any((team) => _sameTeamName(team.name, normalizedNew));
    if (nameTaken) return false;

    final nextTeams = [...state.teams];
    nextTeams[teamIndex] = currentTeam.copyWith(name: normalizedNew);
    nextTeams.sort((a, b) => a.name.compareTo(b.name));

    final selectedIds = memberIds.toSet();
    final changedEmployeeIds = <String>[];
    final nextEmployees = state.employees.map((employee) {
      final isSelected = selectedIds.contains(employee.id);
      String nextTeam = employee.team;

      if (isSelected) {
        nextTeam = normalizedNew;
      } else if (_sameTeamName(employee.team, normalizedOld)) {
        nextTeam = '';
      }

      if (nextTeam == employee.team) return employee;
      changedEmployeeIds.add(employee.id);
      return employee.copyWith(team: nextTeam);
    }).toList();

    var nextPending = _enqueueChange(
      state.pendingChanges,
      PendingOperation.updateTeam,
      currentTeam.id,
    );
    if (changedEmployeeIds.isNotEmpty) {
      nextPending = _enqueueBatchChanges(
        nextPending,
        PendingOperation.updateEmployee,
        changedEmployeeIds,
      );
    }

    state = state.copyWith(
      teams: nextTeams,
      employees: nextEmployees,
      pendingChanges: nextPending,
    );
    return true;
  }

  bool deleteTeam(String teamName) {
    final normalizedName = teamName.trim();
    if (normalizedName.isEmpty) return false;

    final teamIndex = state.teams.indexWhere(
      (team) => _sameTeamName(team.name, normalizedName),
    );
    if (teamIndex < 0) return false;
    final targetTeam = state.teams[teamIndex];
    final nextTeams = [...state.teams]..removeAt(teamIndex);

    final changedEmployeeIds = <String>[];
    final nextEmployees = state.employees.map((employee) {
      if (!_sameTeamName(employee.team, normalizedName)) {
        return employee;
      }
      changedEmployeeIds.add(employee.id);
      return employee.copyWith(team: '');
    }).toList();

    var nextPending = _enqueueChange(
      state.pendingChanges,
      PendingOperation.deleteTeam,
      targetTeam.id,
    );
    if (changedEmployeeIds.isNotEmpty) {
      nextPending = _enqueueBatchChanges(
        nextPending,
        PendingOperation.updateEmployee,
        changedEmployeeIds,
      );
    }

    state = state.copyWith(
      teams: nextTeams,
      employees: nextEmployees,
      pendingChanges: nextPending,
    );
    return true;
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

  void addFinanceEntry(FinanceEntry entry) {
    final nextEntries = [...state.finance, entry]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    state = state.copyWith(
      finance: nextEntries,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.addFinanceEntry,
        entry.id,
      ),
    );
  }

  void markFinanceEntry(String entryId, FinanceStatus status) {
    final index = state.finance.indexWhere((entry) => entry.id == entryId);
    if (index < 0) return;
    final next = [...state.finance];
    next[index] = next[index].copyWith(status: status);
    state = state.copyWith(
      finance: next,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.markFinanceEntry,
        entryId,
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

  void addServiceType(ServiceType serviceType) {
    final next = [...state.serviceTypes, serviceType]
      ..sort((a, b) => a.name.compareTo(b.name));
    state = state.copyWith(
      serviceTypes: next,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.addServiceType,
        serviceType.id,
      ),
    );
  }

  void updateServiceType(ServiceType serviceType) {
    final index =
        state.serviceTypes.indexWhere((item) => item.id == serviceType.id);
    if (index < 0) return;
    final next = [...state.serviceTypes];
    next[index] = serviceType;
    state = state.copyWith(
      serviceTypes: next,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.updateServiceType,
        serviceType.id,
      ),
    );
  }

  bool deleteServiceType(String serviceTypeId) {
    final hasLinkedTasks =
        state.tasks.any((task) => task.serviceTypeId == serviceTypeId);
    if (hasLinkedTasks) return false;

    final next =
        state.serviceTypes.where((item) => item.id != serviceTypeId).toList();
    state = state.copyWith(
      serviceTypes: next,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.deleteServiceType,
        serviceTypeId,
      ),
    );
    return true;
  }

  void advanceTaskStatus(String taskId) {
    final index = state.tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return;

    final current = state.tasks[index].status;
    final next = switch (current) {
      TaskStatus.scheduled => TaskStatus.inProgress,
      TaskStatus.inProgress => TaskStatus.completed,
      TaskStatus.completed => TaskStatus.completed,
      TaskStatus.canceled => TaskStatus.canceled,
    };
    updateTaskStatus(taskId: taskId, status: next);
  }

  void markTaskCheckIn(String taskId, DateTime timestamp) {
    final index = state.tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return;
    final nextTasks = [...state.tasks];
    nextTasks[index] = nextTasks[index].copyWith(checkInTime: timestamp);
    state = state.copyWith(
      tasks: nextTasks,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.updateTask,
        taskId,
      ),
    );
  }

  void markTaskCheckOut(String taskId, DateTime timestamp) {
    final index = state.tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return;
    final nextTasks = [...state.tasks];
    nextTasks[index] = nextTasks[index].copyWith(checkOutTime: timestamp);
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

  List<Team> _normalizeTeams({
    required List<Team> currentTeams,
    required List<Employee> employees,
  }) {
    final map = <String, Team>{};

    for (final team in currentTeams) {
      final name = team.name.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      map.putIfAbsent(key, () => team.copyWith(name: name));
    }

    for (final employee in employees) {
      final name = employee.team.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      map.putIfAbsent(
        key,
        () => Team(
          id: 'team-${_uuid.v4()}',
          name: name,
        ),
      );
    }

    final next = map.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    return next;
  }

  bool _sameTeamName(String left, String right) {
    return left.trim().toLowerCase() == right.trim().toLowerCase();
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

  List<PendingChange> _enqueueBatchChanges(
    List<PendingChange> queue,
    PendingOperation operation,
    List<String> entityIds,
  ) {
    if (entityIds.isEmpty) return queue;
    final now = DateTime.now();
    return [
      ...queue,
      ...entityIds.map(
        (id) => PendingChange(
          operation: operation,
          entityId: id,
          timestamp: now,
        ),
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
    final teams = [
      const Team(id: 'team-a', name: 'Team A'),
      const Team(id: 'team-b', name: 'Team B'),
    ];
    final serviceTypes = [
      const ServiceType(
        id: 'service-cleaning',
        name: 'General Cleaning',
        description: 'Routine residential cleaning service.',
        basePrice: 120,
        currency: FinanceCurrency.usd,
        pricingModel: ServicePricingModel.perTask,
      ),
      const ServiceType(
        id: 'service-grocery',
        name: 'Grocery Assistance',
        description: 'Shopping and delivery support.',
        basePrice: 40,
        currency: FinanceCurrency.usd,
        pricingModel: ServicePricingModel.perHour,
      ),
    ];

    final tasks = [
      ServiceTask(
        id: 'task-1',
        title: 'Weekly cleaning',
        date: now,
        status: TaskStatus.scheduled,
        assignedEmployeeId: 'maria',
        clientId: clients.first.id,
        serviceTypeId: 'service-cleaning',
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
        serviceTypeId: 'service-grocery',
        clientName: clients.last.name,
        address: clients.last.address,
        startTime: DateTime(now.year, now.month, now.day + 1, 14, 0),
        endTime: DateTime(now.year, now.month, now.day + 1, 15, 0),
      ),
    ];

    final finance = [
      FinanceEntry(
        id: 'fin-1',
        title: 'Invoice - Smith Family',
        amount: 320,
        currency: FinanceCurrency.usd,
        type: FinanceEntryType.receivable,
        dueDate: now.add(const Duration(days: 5)),
        status: FinanceStatus.pending,
        kind: FinanceKind.invoiceClient,
        clientId: clients.first.id,
        clientName: clients.first.name,
      ),
      FinanceEntry(
        id: 'fin-2',
        title: 'Payroll - Maria',
        amount: 180,
        currency: FinanceCurrency.usd,
        type: FinanceEntryType.payable,
        dueDate: now.add(const Duration(days: 3)),
        status: FinanceStatus.pending,
        kind: FinanceKind.payrollEmployee,
        employeeId: employees.first.id,
        employeeName: employees.first.name,
      ),
    ];

    return OfflineState(
      clients: clients,
      employees: employees,
      teams: teams,
      tasks: tasks,
      serviceTypes: serviceTypes,
      finance: finance,
    );
  }
}
