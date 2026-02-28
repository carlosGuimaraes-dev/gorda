import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../auth/domain/user_session.dart';
import '../../clients/domain/client.dart';
import '../../employees/domain/employee.dart';
import '../../finance/domain/finance_entry.dart';
import '../../services/domain/service_type.dart';
import '../../services/domain/service_task.dart';
import '../../teams/domain/team.dart';
import '../domain/app_preferences.dart';
import '../domain/log_entries.dart';
import '../domain/notification_preferences.dart';
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
    this.notificationPreferences = const NotificationPreferences(),
    this.appPreferences = const AppPreferences(),
    this.conflictLog = const [],
    this.auditLog = const [],
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
  final NotificationPreferences notificationPreferences;
  final AppPreferences appPreferences;
  final List<ConflictLogEntry> conflictLog;
  final List<AuditLogEntry> auditLog;
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
    NotificationPreferences? notificationPreferences,
    AppPreferences? appPreferences,
    List<ConflictLogEntry>? conflictLog,
    List<AuditLogEntry>? auditLog,
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
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      appPreferences: appPreferences ?? this.appPreferences,
      conflictLog: conflictLog ?? this.conflictLog,
      auditLog: auditLog ?? this.auditLog,
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
    _appendAudit(
      entity: 'Session',
      action: 'Login',
      summary: 'User logged in: $normalizedUser',
    );
  }

  void logout() {
    final actor = state.session?.name ?? 'System';
    state = state.copyWith(clearSession: true);
    _appendAudit(
      entity: 'Session',
      action: 'Logout',
      summary: 'User logged out: $actor',
    );
  }

  void setLocale({required String languageCode, required String countryCode}) {
    state =
        state.copyWith(languageCode: languageCode, countryCode: countryCode);
  }

  void setNotificationPreferences(NotificationPreferences value) {
    state = state.copyWith(notificationPreferences: value);
  }

  void setAppPreferences(AppPreferences value) {
    state = state.copyWith(appPreferences: value);
  }

  void recordConflict({
    required String entity,
    required String field,
    required String summary,
  }) {
    final next = [
      ...state.conflictLog,
      ConflictLogEntry(
        id: _uuid.v4(),
        entity: entity,
        field: field,
        summary: summary,
        timestamp: DateTime.now(),
      ),
    ];
    state = state.copyWith(conflictLog: next);
  }

  void clearConflictLog() {
    state = state.copyWith(conflictLog: const []);
  }

  void clearAuditLog() {
    state = state.copyWith(auditLog: const []);
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
    _appendAudit(
      entity: 'Client',
      action: 'Created',
      summary: 'Client created: ${client.name}',
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
    _appendAudit(
      entity: 'Client',
      action: 'Updated',
      summary: 'Client updated: ${client.name}',
    );
  }

  bool deleteClient(String clientId) {
    final hasLinkedTasks = state.tasks.any((task) => task.clientId == clientId);
    final hasLinkedFinance =
        state.finance.any((entry) => entry.clientId == clientId);
    if (hasLinkedTasks || hasLinkedFinance) return false;

    final deleted = state.clients.firstWhere(
      (item) => item.id == clientId,
      orElse: () => const Client(id: '', name: ''),
    );

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
    _appendAudit(
      entity: 'Client',
      action: 'Deleted',
      summary: 'Client deleted: ${deleted.name}',
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
    _appendAudit(
      entity: 'Employee',
      action: 'Created',
      summary: 'Employee created: ${employee.name}',
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
    _appendAudit(
      entity: 'Employee',
      action: 'Updated',
      summary: 'Employee updated: ${employee.name}',
    );
  }

  bool deleteEmployee(String employeeId) {
    final hasLinkedTasks =
        state.tasks.any((task) => task.assignedEmployeeId == employeeId);
    final hasLinkedFinance =
        state.finance.any((entry) => entry.employeeId == employeeId);
    if (hasLinkedTasks || hasLinkedFinance) return false;

    final deleted = state.employees.firstWhere(
      (item) => item.id == employeeId,
      orElse: () => const Employee(id: '', name: ''),
    );

    final next = state.employees.where((item) => item.id != employeeId).toList();
    state = state.copyWith(
      employees: next,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.deleteEmployee,
        employeeId,
      ),
    );
    _appendAudit(
      entity: 'Employee',
      action: 'Deleted',
      summary: 'Employee deleted: ${deleted.name}',
    );
    return true;
  }

  bool createTeam({
    required String teamName,
    List<String> memberIds = const [],
  }) {
    final normalizedName = teamName.trim();
    if (normalizedName.isEmpty) return false;

    final teamExists = state.teams.any(
      (team) => _sameTeamName(team.name, normalizedName),
    );
    if (teamExists) return false;

    final newTeam = Team(id: 'team-${_uuid.v4()}', name: normalizedName);
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
    _appendAudit(
      entity: 'Team',
      action: 'Created',
      summary: 'Team created: $normalizedName',
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

    final nameTaken = !_sameTeamName(normalizedOld, normalizedNew) &&
        state.teams.any((team) => _sameTeamName(team.name, normalizedNew));
    if (nameTaken) return false;

    final nextTeams = [...state.teams];
    nextTeams[teamIndex] = currentTeam.copyWith(name: normalizedNew);
    nextTeams.sort((a, b) => a.name.compareTo(b.name));

    final selectedIds = memberIds.toSet();
    final changedEmployeeIds = <String>[];
    final nextEmployees = state.employees.map((employee) {
      final isSelected = selectedIds.contains(employee.id);
      var nextTeam = employee.team;

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
    _appendAudit(
      entity: 'Team',
      action: 'Updated',
      summary: 'Team updated: $normalizedOld -> $normalizedNew',
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
      if (!_sameTeamName(employee.team, normalizedName)) return employee;
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
    _appendAudit(
      entity: 'Team',
      action: 'Deleted',
      summary: 'Team deleted: ${targetTeam.name}',
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
    _appendAudit(
      entity: 'Task',
      action: 'Created',
      summary: 'Task created: ${task.title}',
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
    _appendAudit(
      entity: 'Task',
      action: 'Status updated',
      summary: 'Task ${updated.title} -> ${updated.status.name}',
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

  void addFinanceEntry(FinanceEntry entry) {
    final normalized = entry.copyWith(currency: state.appPreferences.preferredCurrency);
    final nextEntries = [...state.finance, normalized]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    state = state.copyWith(
      finance: nextEntries,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.addFinanceEntry,
        normalized.id,
      ),
    );
    _appendAudit(
      entity: 'Finance',
      action: 'Created',
      summary: 'Finance entry created: ${normalized.title}',
    );
  }

  void updateFinanceEntry(FinanceEntry entry) {
    final index = state.finance.indexWhere((item) => item.id == entry.id);
    if (index < 0) return;
    final next = [...state.finance];
    next[index] = entry.copyWith(currency: state.appPreferences.preferredCurrency);
    state = state.copyWith(
      finance: next,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.updateFinanceEntry,
        entry.id,
      ),
    );
    _appendAudit(
      entity: 'Finance',
      action: 'Updated',
      summary: 'Finance entry updated: ${entry.title}',
    );
  }

  void markFinanceEntry(
    String entryId,
    FinanceStatus status, {
    FinancePaymentMethod? method,
  }) {
    final index = state.finance.indexWhere((entry) => entry.id == entryId);
    if (index < 0) return;
    final next = [...state.finance];
    final current = next[index];
    next[index] = current.copyWith(
      status: status,
      method: method ?? current.method,
    );
    state = state.copyWith(
      finance: next,
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.markFinanceEntry,
        entryId,
      ),
    );
    _appendAudit(
      entity: 'Finance',
      action: 'Status updated',
      summary: 'Finance entry marked ${status.name}: ${current.title}',
    );
  }

  void deleteFinanceEntry(String entryId) {
    final entry = state.finance.firstWhere(
      (item) => item.id == entryId,
      orElse: () => FinanceEntry(
        id: '',
        title: '',
        amount: 0,
        currency: state.appPreferences.preferredCurrency,
        type: FinanceEntryType.payable,
        dueDate: DateTime.now(),
        status: FinanceStatus.pending,
        kind: FinanceKind.general,
      ),
    );
    state = state.copyWith(
      finance: state.finance.where((item) => item.id != entryId).toList(),
      pendingChanges: _enqueueChange(
        state.pendingChanges,
        PendingOperation.deleteFinanceEntry,
        entryId,
      ),
    );
    _appendAudit(
      entity: 'Finance',
      action: 'Deleted',
      summary: 'Finance entry deleted: ${entry.title}',
    );
  }

  void markInvoiceDisputed(
    String entryId, {
    required bool isDisputed,
    String? reason,
  }) {
    final index = state.finance.indexWhere((entry) => entry.id == entryId);
    if (index < 0) return;
    final target = state.finance[index];
    if (target.kind != FinanceKind.invoiceClient) return;

    final dueDay = DateTime(target.dueDate.year, target.dueDate.month, target.dueDate.day);
    final deadline = dueDay.add(Duration(days: state.appPreferences.disputeWindowDays + 1));
    final now = DateTime.now();
    final canChange = isDisputed ? now.isBefore(deadline) : true;
    if (!canChange) return;

    updateFinanceEntry(
      target.copyWith(
        isDisputed: isDisputed,
        disputeReason: isDisputed ? reason : null,
        clearDisputeReason: !isDisputed,
      ),
    );
  }

  void reissueInvoice({
    required String entryId,
    required double amount,
    required DateTime dueDate,
  }) {
    final current = state.finance.firstWhere(
      (entry) => entry.id == entryId,
      orElse: () => FinanceEntry(
        id: '',
        title: '',
        amount: 0,
        currency: state.appPreferences.preferredCurrency,
        type: FinanceEntryType.receivable,
        dueDate: DateTime.now(),
        status: FinanceStatus.pending,
        kind: FinanceKind.invoiceClient,
      ),
    );
    if (current.id.isEmpty || current.kind != FinanceKind.invoiceClient) return;

    final replacementId = 'fin-${_uuid.v4()}';
    final replacement = FinanceEntry(
      id: replacementId,
      title: '${current.title} · Reissued',
      amount: amount,
      currency: state.appPreferences.preferredCurrency,
      type: current.type,
      dueDate: dueDate,
      status: FinanceStatus.pending,
      method: null,
      clientId: current.clientId,
      clientName: current.clientName,
      employeeId: current.employeeId,
      employeeName: current.employeeName,
      kind: FinanceKind.invoiceClient,
      supersedesId: current.id,
      isDisputed: false,
      disputeReason: null,
    );

    addFinanceEntry(replacement);
    updateFinanceEntry(
      current.copyWith(
        supersededById: replacementId,
        supersededAt: DateTime.now(),
      ),
    );
  }

  void generateInvoices({
    required DateTime from,
    required DateTime to,
    required DateTime dueDate,
    String? clientName,
  }) {
    final clientId = clientName == null
        ? null
        : state.clients
            .firstWhere(
              (client) => client.name == clientName,
              orElse: () => const Client(id: '', name: ''),
            )
            .id;
    generateInvoicesForPeriod(
      startDate: from,
      endDate: to,
      dueDate: dueDate,
      clientId: (clientId?.isEmpty ?? true) ? null : clientId,
    );
  }

  void generateInvoicesForPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required DateTime dueDate,
    String? clientId,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final endExclusive = DateTime(endDate.year, endDate.month, endDate.day)
        .add(const Duration(days: 1));

    final visibleTasks = state.tasks.where((task) {
      if (task.status == TaskStatus.canceled) return false;
      if (task.date.isBefore(start) || !task.date.isBefore(endExclusive)) {
        return false;
      }
      if (clientId != null) {
        return task.clientId == clientId;
      }
      return true;
    }).toList();

    final grouped = <String, List<ServiceTask>>{};
    for (final task in visibleTasks) {
      final key = task.clientId ?? task.clientName;
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(task);
    }

    final periodLabel =
        '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}';

    for (final entry in grouped.entries) {
      final tasks = entry.value;
      if (tasks.isEmpty) continue;

      final client = _resolveClient(tasks.first.clientId, tasks.first.clientName);
      final clientName = client?.name ?? tasks.first.clientName;
      final lineTotal = _lineItemsForTasks(tasks).fold<double>(
        0,
        (sum, item) => sum + item.total,
      );
      if (lineTotal <= 0) continue;

      final invoice = FinanceEntry(
        id: 'fin-${_uuid.v4()}',
        title: 'Invoice $clientName ($periodLabel)',
        amount: lineTotal,
        currency: state.appPreferences.preferredCurrency,
        type: FinanceEntryType.receivable,
        dueDate: dueDate,
        status: FinanceStatus.pending,
        kind: FinanceKind.invoiceClient,
        clientId: client?.id,
        clientName: clientName,
      );
      addFinanceEntry(invoice);
    }
  }

  void generatePayrollsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required DateTime dueDate,
    String? employeeId,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final endExclusive = DateTime(endDate.year, endDate.month, endDate.day)
        .add(const Duration(days: 1));

    final employees = employeeId == null
        ? state.employees
        : state.employees.where((e) => e.id == employeeId).toList();

    final periodLabel = DateFormat('MMM yyyy').format(startDate);

    for (final employee in employees) {
      final rate = employee.hourlyRate ?? 0;
      if (rate <= 0) continue;

      final employeeTasks = state.tasks.where((task) {
        final isAssigned = task.assignedEmployeeId == employee.id ||
            task.assignedEmployeeId == employee.name;
        if (!isAssigned) return false;
        if (task.status == TaskStatus.canceled) return false;
        if (task.date.isBefore(start) || !task.date.isBefore(endExclusive)) {
          return false;
        }
        return task.checkInTime != null && task.checkOutTime != null;
      }).toList();

      if (employeeTasks.isEmpty) continue;

      final totalHours = employeeTasks.fold<double>(0, (sum, task) {
        final checkIn = task.checkInTime!;
        final checkOut = task.checkOutTime!;
        final hours = checkOut.difference(checkIn).inMinutes / 60.0;
        return hours > 0 ? sum + hours : sum;
      });
      if (totalHours <= 0) continue;

      final uniqueDays = employeeTasks
          .map((task) => DateTime(task.date.year, task.date.month, task.date.day))
          .toSet()
          .length;
      final basePay = totalHours * rate;
      final netPay = basePay;

      final payroll = FinanceEntry(
        id: 'fin-${_uuid.v4()}',
        title: 'Payroll - ${employee.name} $periodLabel',
        amount: netPay,
        currency: state.appPreferences.preferredCurrency,
        type: FinanceEntryType.payable,
        dueDate: dueDate,
        status: FinanceStatus.pending,
        kind: FinanceKind.payrollEmployee,
        employeeId: employee.id,
        employeeName: employee.name,
        payrollPeriodStart: startDate,
        payrollPeriodEnd: endDate,
        payrollHoursWorked: totalHours,
        payrollDaysWorked: uniqueDays,
        payrollHourlyRate: rate,
        payrollBasePay: basePay,
        payrollBonus: 0,
        payrollDeductions: 0,
        payrollTaxes: 0,
        payrollReimbursements: 0,
        payrollNetPay: netPay,
      );
      addFinanceEntry(payroll);
    }
  }

  void generatePayrolls({
    required DateTime from,
    required DateTime to,
    required DateTime dueDate,
    String? employeeName,
  }) {
    final employeeId = employeeName == null
        ? null
        : state.employees
            .firstWhere(
              (employee) => employee.name == employeeName,
              orElse: () => const Employee(id: '', name: ''),
            )
            .id;
    generatePayrollsForPeriod(
      startDate: from,
      endDate: to,
      dueDate: dueDate,
      employeeId: (employeeId?.isEmpty ?? true) ? null : employeeId,
    );
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

    if (latestByEntity.isNotEmpty) {
      // ignore: avoid_print
      print('Synced ${latestByEntity.length} entities (stub).');
    }
  }

  List<InvoiceLineItemData> lineItemsForInvoice(FinanceEntry invoice) {
    final startEnd = _invoicePeriod(invoice);
    final invoiceTasks = state.tasks.where((task) {
      final matchesClient = invoice.clientId != null
          ? task.clientId == invoice.clientId
          : task.clientName == invoice.clientName;
      if (!matchesClient) return false;
      return !task.date.isBefore(startEnd.start) &&
          !task.date.isAfter(startEnd.end);
    }).toList();

    final lineItems = _lineItemsForTasks(invoiceTasks);
    if (lineItems.isNotEmpty) {
      return lineItems;
    }

    return [
      InvoiceLineItemData(
        serviceTypeName: 'Service',
        description: invoice.title,
        date: invoice.dueDate,
        pricingModel: ServicePricingModel.perTask,
        quantity: 1,
        unitPrice: invoice.amount,
        total: invoice.amount,
      ),
    ];
  }

  ({DateTime start, DateTime end}) _invoicePeriod(FinanceEntry invoice) {
    final pattern = RegExp(r'\(([^)]+)\)');
    final match = pattern.firstMatch(invoice.title);
    if (match != null) {
      final periodText = match.group(1) ?? '';
      final parts = periodText.split('-').map((part) => part.trim()).toList();
      if (parts.length == 2) {
        final parser = DateFormat('MMM d');
        final year = invoice.dueDate.year;
        try {
          final startRaw = parser.parse(parts.first);
          final endRaw = parser.parse(parts.last);
          final start = DateTime(year, startRaw.month, startRaw.day);
          final end = DateTime(year, endRaw.month, endRaw.day);
          return (start: start, end: end);
        } catch (_) {
          // fallback below
        }
      }
    }

    final start = DateTime(invoice.dueDate.year, invoice.dueDate.month, 1);
    final end = DateTime(invoice.dueDate.year, invoice.dueDate.month + 1, 0);
    return (start: start, end: end);
  }

  List<InvoiceLineItemData> _lineItemsForTasks(List<ServiceTask> tasks) {
    final items = <InvoiceLineItemData>[];
    for (final task in tasks) {
      final type = state.serviceTypes.firstWhere(
        (item) => item.id == task.serviceTypeId,
        orElse: () => ServiceType(
          id: '',
          name: 'Service',
          basePrice: task.serviceTypeId == null ? taskCostFallback(task) : 0,
          currency: state.appPreferences.preferredCurrency,
          pricingModel: ServicePricingModel.perTask,
        ),
      );
      final pricingModel = type.pricingModel;
      var quantity = 1.0;
      if (pricingModel == ServicePricingModel.perHour) {
        if (task.checkInTime != null && task.checkOutTime != null) {
          final hours =
              task.checkOutTime!.difference(task.checkInTime!).inMinutes / 60.0;
          quantity = hours < 0 ? 0 : hours;
        } else {
          quantity = 0;
        }
      }

      final rounded = (quantity * 100).roundToDouble() / 100;
      final total = rounded * type.basePrice;

      items.add(
        InvoiceLineItemData(
          serviceTypeName: type.name,
          description: task.title,
          date: task.date,
          pricingModel: pricingModel,
          quantity: rounded,
          unitPrice: type.basePrice,
          total: total,
        ),
      );
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  double taskCostFallback(ServiceTask task) {
    if (task.checkInTime != null && task.checkOutTime != null) {
      final hours = task.checkOutTime!.difference(task.checkInTime!).inMinutes / 60.0;
      if (hours > 0) {
        return hours * 20;
      }
    }
    return 100;
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

  Client? _resolveClient(String? clientId, String clientName) {
    if (clientId != null) {
      final byId = state.clients.where((item) => item.id == clientId);
      if (byId.isNotEmpty) return byId.first;
    }
    final byName = state.clients.where((item) => item.name == clientName);
    if (byName.isNotEmpty) return byName.first;
    return null;
  }

  void _appendAudit({
    required String entity,
    required String action,
    required String summary,
  }) {
    final actor = state.session?.name ?? 'System';
    final next = [
      ...state.auditLog,
      AuditLogEntry(
        id: _uuid.v4(),
        entity: entity,
        action: action,
        summary: summary,
        actor: actor,
        timestamp: DateTime.now(),
      ),
    ];

    if (next.length > 200) {
      state = state.copyWith(auditLog: next.sublist(next.length - 200));
      return;
    }

    state = state.copyWith(auditLog: next);
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
        preferredDeliveryChannels: [
          DeliveryChannel.email,
          DeliveryChannel.whatsapp,
        ],
      ),
      const Client(
        id: 'client-2',
        name: 'Johnson Residence',
        address: '110 Pine Avenue',
        phone: '+1 415 555 0188',
        preferredDeliveryChannels: [
          DeliveryChannel.email,
          DeliveryChannel.sms,
        ],
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
        payrollHoursWorked: 8,
        payrollDaysWorked: 1,
        payrollHourlyRate: 22,
        payrollBasePay: 176,
        payrollBonus: 4,
        payrollNetPay: 180,
      ),
    ];

    return OfflineState(
      clients: clients,
      employees: employees,
      teams: teams,
      tasks: tasks,
      serviceTypes: serviceTypes,
      finance: finance,
      appPreferences: const AppPreferences(
        preferredCurrency: FinanceCurrency.usd,
        disputeWindowDays: 7,
        enableWhatsApp: true,
        enableTextMessages: true,
        enableEmail: true,
      ),
      notificationPreferences: const NotificationPreferences(
        enableClientNotifications: true,
        enableTeamNotifications: true,
        enablePush: true,
        enableSiri: false,
      ),
    );
  }
}

class InvoiceLineItemData {
  const InvoiceLineItemData({
    required this.serviceTypeName,
    required this.description,
    required this.date,
    required this.pricingModel,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final String serviceTypeName;
  final String description;
  final DateTime date;
  final ServicePricingModel pricingModel;
  final double quantity;
  final double unitPrice;
  final double total;
}
