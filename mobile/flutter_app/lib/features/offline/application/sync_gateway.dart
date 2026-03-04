import '../domain/log_entries.dart';

class SyncPushChange {
  const SyncPushChange({
    required this.entity,
    required this.entityId,
    required this.operation,
    required this.clientUpdatedAt,
  });

  final String entity;
  final String entityId;
  final String operation;
  final DateTime clientUpdatedAt;
}

class SyncPushResult {
  const SyncPushResult({
    required this.serverTime,
    this.conflicts = const [],
  });

  final DateTime serverTime;
  final List<ConflictLogEntry> conflicts;
}

class SyncPullResult {
  const SyncPullResult({
    required this.serverTime,
    this.conflicts = const [],
    this.auditEntries = const [],
  });

  final DateTime serverTime;
  final List<ConflictLogEntry> conflicts;
  final List<AuditLogEntry> auditEntries;
}

abstract class SyncGateway {
  Future<SyncPushResult> pushChanges({
    required String deviceId,
    required DateTime clientTime,
    required List<SyncPushChange> changes,
  });

  Future<SyncPullResult> pullChanges({
    required DateTime? since,
    int limit = 500,
  });
}

class StubSyncGateway implements SyncGateway {
  @override
  Future<SyncPushResult> pushChanges({
    required String deviceId,
    required DateTime clientTime,
    required List<SyncPushChange> changes,
  }) async {
    return SyncPushResult(serverTime: DateTime.now());
  }

  @override
  Future<SyncPullResult> pullChanges({
    required DateTime? since,
    int limit = 500,
  }) async {
    return SyncPullResult(serverTime: DateTime.now());
  }
}
