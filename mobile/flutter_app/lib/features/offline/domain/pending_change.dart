enum PendingOperation {
  addTask,
  updateTask,
  addClient,
  updateClient,
  deleteClient,
  addFinanceEntry,
  updateFinanceEntry,
  markFinanceEntry,
  addEmployee,
  updateEmployee,
  deleteEmployee,
  addServiceType,
  updateServiceType,
  deleteServiceType,
  addTeam,
  updateTeam,
  deleteTeam,
}

class PendingChange {
  const PendingChange({
    required this.operation,
    required this.entityId,
    required this.timestamp,
  });

  final PendingOperation operation;
  final String entityId;
  final DateTime timestamp;
}
