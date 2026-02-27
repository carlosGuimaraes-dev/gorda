class ConflictLogEntry {
  const ConflictLogEntry({
    required this.id,
    required this.entity,
    required this.field,
    required this.summary,
    required this.timestamp,
  });

  final String id;
  final String entity;
  final String field;
  final String summary;
  final DateTime timestamp;
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.entity,
    required this.action,
    required this.summary,
    required this.actor,
    required this.timestamp,
  });

  final String id;
  final String entity;
  final String action;
  final String summary;
  final String actor;
  final DateTime timestamp;
}
