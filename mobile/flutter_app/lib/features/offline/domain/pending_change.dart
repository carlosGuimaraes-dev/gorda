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
