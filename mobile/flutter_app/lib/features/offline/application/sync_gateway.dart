import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/log_entries.dart';

class SyncPushChange {
  const SyncPushChange({
    required this.entity,
    required this.entityId,
    required this.operation,
    required this.clientUpdatedAt,
    this.payload = const <String, dynamic>{},
  });

  final String entity;
  final String entityId;
  final String operation;
  final DateTime clientUpdatedAt;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() {
    return {
      'op': operation,
      'entity': entity,
      'entityId': entityId,
      'clientUpdatedAt': clientUpdatedAt.toUtc().toIso8601String(),
      'payload': payload,
    };
  }
}

class SyncPushResult {
  const SyncPushResult({
    required this.serverTime,
    this.applied = const [],
    this.rejected = const [],
    this.conflicts = const [],
  });

  final DateTime serverTime;
  final List<SyncAppliedChange> applied;
  final List<SyncRejectedChange> rejected;
  final List<ConflictLogEntry> conflicts;
}

class SyncAppliedChange {
  const SyncAppliedChange({
    required this.entity,
    required this.entityId,
    required this.operation,
  });

  final String entity;
  final String entityId;
  final String operation;
}

class SyncRejectedChange {
  const SyncRejectedChange({
    required this.entity,
    required this.entityId,
    required this.operation,
    required this.reason,
    required this.summary,
    this.fields = const [],
  });

  final String entity;
  final String entityId;
  final String operation;
  final String reason;
  final String summary;
  final List<String> fields;
}

class SyncRemoteChange {
  const SyncRemoteChange({
    required this.entity,
    required this.entityId,
    required this.operation,
    required this.serverUpdatedAt,
    this.payload = const <String, dynamic>{},
  });

  final String entity;
  final String entityId;
  final String operation;
  final DateTime serverUpdatedAt;
  final Map<String, dynamic> payload;
}

class SyncPullResult {
  const SyncPullResult({
    required this.serverTime,
    this.nextCursor,
    this.changes = const [],
    this.conflicts = const [],
    this.auditEntries = const [],
  });

  final DateTime serverTime;
  final DateTime? nextCursor;
  final List<SyncRemoteChange> changes;
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

  Future<List<ConflictLogEntry>> fetchConflicts({required DateTime? since});
  Future<List<AuditLogEntry>> fetchAudit({required DateTime? since});
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

  @override
  Future<List<ConflictLogEntry>> fetchConflicts({required DateTime? since}) async {
    return const [];
  }

  @override
  Future<List<AuditLogEntry>> fetchAudit({required DateTime? since}) async {
    return const [];
  }
}

class HttpSyncGateway implements SyncGateway {
  HttpSyncGateway({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    final sanitizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final sanitizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$sanitizedBase$sanitizedPath').replace(queryParameters: query);
  }

  @override
  Future<SyncPushResult> pushChanges({
    required String deviceId,
    required DateTime clientTime,
    required List<SyncPushChange> changes,
  }) async {
    final response = await _client.post(
      _uri('/v1/sync/push'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'deviceId': deviceId,
        'clientTime': clientTime.toUtc().toIso8601String(),
        'changes': changes.map((change) => change.toJson()).toList(),
      }),
    );
    _ensureSuccess(response);
    final data = _asMap(jsonDecode(response.body));
    return SyncPushResult(
      serverTime: _parseDate(data['serverTime']) ?? DateTime.now().toUtc(),
      applied: _parseAppliedChanges(data['applied']),
      rejected: _parseRejectedChanges(data['rejected']),
      conflicts: _parseConflicts(data['conflicts']),
    );
  }

  @override
  Future<SyncPullResult> pullChanges({
    required DateTime? since,
    int limit = 500,
  }) async {
    final response = await _client.get(
      _uri('/v1/sync/pull', {
        if (since != null) 'since': since.toUtc().toIso8601String(),
        'limit': '$limit',
      }),
      headers: {'accept': 'application/json'},
    );
    _ensureSuccess(response);
    final data = _asMap(jsonDecode(response.body));
    return SyncPullResult(
      serverTime: _parseDate(data['serverTime']) ?? DateTime.now().toUtc(),
      nextCursor: _parseDate(data['nextCursor']),
      changes: _parseChanges(data['changes']),
      conflicts: _parseConflicts(data['conflicts']),
      auditEntries: _parseAuditEntries(data['audit']),
    );
  }

  @override
  Future<List<ConflictLogEntry>> fetchConflicts({required DateTime? since}) async {
    final response = await _client.get(
      _uri('/v1/conflicts', {
        if (since != null) 'since': since.toUtc().toIso8601String(),
      }),
      headers: {'accept': 'application/json'},
    );
    _ensureSuccess(response);
    final data = _asMap(jsonDecode(response.body));
    return _parseConflicts(data['conflicts']);
  }

  @override
  Future<List<AuditLogEntry>> fetchAudit({required DateTime? since}) async {
    final response = await _client.get(
      _uri('/v1/audit', {
        if (since != null) 'since': since.toUtc().toIso8601String(),
      }),
      headers: {'accept': 'application/json'},
    );
    _ensureSuccess(response);
    final data = _asMap(jsonDecode(response.body));
    return _parseAuditEntries(data['audit']);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw StateError('Sync API failed (${response.statusCode}): ${response.body}');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, val) => MapEntry('$key', val));
    throw StateError('Invalid JSON payload from sync API');
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  List<ConflictLogEntry> _parseConflicts(dynamic value) {
    if (value is! List) return const [];
    return value.map((raw) {
      final item = _asMap(raw);
      final fields = item['fields'];
      final field = fields is List && fields.isNotEmpty ? '${fields.first}' : '';
      return ConflictLogEntry(
        id: '${item['id'] ?? item['entityId'] ?? ''}',
        entity: '${item['entity'] ?? ''}',
        field: field,
        summary: '${item['summary'] ?? ''}',
        timestamp: _parseDate(item['createdAt'] ?? item['serverUpdatedAt']) ??
            DateTime.now().toUtc(),
      );
    }).toList(growable: false);
  }

  List<AuditLogEntry> _parseAuditEntries(dynamic value) {
    if (value is! List) return const [];
    return value.map((raw) {
      final item = _asMap(raw);
      return AuditLogEntry(
        id: '${item['id'] ?? item['entityId'] ?? ''}',
        entity: '${item['entity'] ?? ''}',
        action: '${item['action'] ?? ''}',
        summary: '${item['summary'] ?? ''}',
        actor: '${item['actor'] ?? ''}',
        timestamp: _parseDate(item['createdAt']) ?? DateTime.now().toUtc(),
      );
    }).toList(growable: false);
  }

  List<SyncRemoteChange> _parseChanges(dynamic value) {
    if (value is! List) return const [];
    return value.map((raw) {
      final item = _asMap(raw);
      final payload = item['payload'];
      return SyncRemoteChange(
        entity: '${item['entity'] ?? ''}',
        entityId: '${item['entityId'] ?? ''}',
        operation: '${item['op'] ?? item['operation'] ?? 'upsert'}',
        serverUpdatedAt: _parseDate(item['serverUpdatedAt'] ?? item['updatedAt']) ??
            DateTime.now().toUtc(),
        payload: payload is Map<String, dynamic>
            ? payload
            : payload is Map
                ? payload.map((key, val) => MapEntry('$key', val))
                : const <String, dynamic>{},
      );
    }).toList(growable: false);
  }

  List<SyncAppliedChange> _parseAppliedChanges(dynamic value) {
    if (value is! List) return const [];
    final parsed = <SyncAppliedChange>[];
    for (final raw in value) {
      if (raw is String && raw.trim().isNotEmpty) {
        // Backward compatibility with old backend shape: ["entityId"].
        parsed.add(
          SyncAppliedChange(
            entity: '',
            entityId: raw,
            operation: 'upsert',
          ),
        );
        continue;
      }
      final item = _asMap(raw);
      final entityId = '${item['entityId'] ?? item['id'] ?? ''}'.trim();
      if (entityId.isEmpty) continue;
      parsed.add(
        SyncAppliedChange(
          entity: '${item['entity'] ?? ''}',
          entityId: entityId,
          operation: '${item['op'] ?? item['operation'] ?? 'upsert'}',
        ),
      );
    }
    return parsed;
  }

  List<SyncRejectedChange> _parseRejectedChanges(dynamic value) {
    if (value is! List) return const [];
    final parsed = <SyncRejectedChange>[];
    for (final raw in value) {
      final item = _asMap(raw);
      final entity = '${item['entity'] ?? ''}'.trim();
      final entityId = '${item['entityId'] ?? ''}'.trim();
      if (entity.isEmpty || entityId.isEmpty) continue;
      final fieldsRaw = item['fields'];
      final fields = fieldsRaw is List
          ? fieldsRaw
              .map((field) => '$field'.trim())
              .where((field) => field.isNotEmpty)
              .toList(growable: false)
          : const <String>[];
      parsed.add(
        SyncRejectedChange(
          entity: entity,
          entityId: entityId,
          operation: '${item['op'] ?? item['operation'] ?? 'upsert'}',
          reason: '${item['reason'] ?? 'validation_error'}',
          summary: '${item['summary'] ?? 'Change rejected by sync backend'}',
          fields: fields,
        ),
      );
    }
    return parsed;
  }
}
