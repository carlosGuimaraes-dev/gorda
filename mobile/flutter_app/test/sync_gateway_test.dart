import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ag_home_organizer_flutter/features/offline/application/sync_gateway.dart';

void main() {
  test('pushChanges sends contract payload and parses conflicts', () async {
    late Map<String, dynamic> captured;

    final gateway = HttpSyncGateway(
      baseUrl: 'https://api.example.com',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/sync/push');
        captured = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'serverTime': '2026-03-05T00:00:00Z',
            'applied': [
              {
                'entity': 'client',
                'entityId': 'client-1',
                'op': 'upsert',
              }
            ],
            'rejected': [
              {
                'entity': 'task',
                'entityId': 'task-1',
                'op': 'upsert',
                'reason': 'missing_required_fields',
                'fields': ['title'],
                'summary': 'Rejected task payload',
              }
            ],
            'conflicts': [
              {
                'id': 'conf-1',
                'entity': 'client',
                'entityId': 'client-1',
                'fields': ['email'],
                'summary': 'Conflict summary',
                'serverUpdatedAt': '2026-03-05T00:00:01Z',
              }
            ],
          }),
          200,
        );
      }),
    );

    final result = await gateway.pushChanges(
      deviceId: 'device-1',
      clientTime: DateTime.parse('2026-03-05T00:00:00Z'),
      changes: [
        SyncPushChange(
          entity: 'client',
          entityId: 'client-1',
          operation: 'upsert',
          clientUpdatedAt: DateTime.parse('2026-03-05T00:00:00Z'),
          payload: const {'name': 'John'},
        ),
      ],
    );

    expect(captured['deviceId'], 'device-1');
    expect((captured['changes'] as List).length, 1);
    final change = (captured['changes'] as List).first as Map<String, dynamic>;
    expect(change['entity'], 'client');
    expect(change['payload']['name'], 'John');

    expect(result.conflicts.length, 1);
    expect(result.conflicts.first.field, 'email');
    expect(result.applied.length, 1);
    expect(result.applied.first.entity, 'client');
    expect(result.applied.first.entityId, 'client-1');
    expect(result.rejected.length, 1);
    expect(result.rejected.first.entity, 'task');
    expect(result.rejected.first.reason, 'missing_required_fields');
  });

  test('pullChanges calls endpoint with since and limit', () async {
    final gateway = HttpSyncGateway(
      baseUrl: 'https://api.example.com',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/v1/sync/pull');
        expect(request.url.queryParameters['since'], '2026-03-01T00:00:00.000Z');
        expect(request.url.queryParameters['limit'], '42');
        return http.Response(
          jsonEncode({
            'serverTime': '2026-03-05T00:00:00Z',
            'changes': [],
            'nextCursor': '2026-03-05T00:00:00Z',
          }),
          200,
        );
      }),
    );

    final result = await gateway.pullChanges(
      since: DateTime.parse('2026-03-01T00:00:00Z'),
      limit: 42,
    );

    expect(result.serverTime.toIso8601String(), '2026-03-05T00:00:00.000Z');
    expect(result.nextCursor?.toIso8601String(), '2026-03-05T00:00:00.000Z');
  });

  test('pullChanges parses remote changes, conflicts and audit', () async {
    final gateway = HttpSyncGateway(
      baseUrl: 'https://api.example.com',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/v1/sync/pull');
        return http.Response(
          jsonEncode({
            'serverTime': '2026-03-05T01:00:00Z',
            'changes': [
              {
                'op': 'upsert',
                'entity': 'task',
                'entityId': 'task-1',
                'serverUpdatedAt': '2026-03-05T01:00:01Z',
                'payload': {
                  'title': 'Remote task',
                  'status': 'scheduled',
                },
              }
            ],
            'conflicts': [
              {
                'id': 'conf-1',
                'entity': 'task',
                'entityId': 'task-1',
                'fields': ['status'],
                'summary': 'Conflict',
                'createdAt': '2026-03-05T01:00:02Z',
              }
            ],
            'audit': [
              {
                'id': 'audit-1',
                'entity': 'Task',
                'action': 'Updated',
                'summary': 'Task updated remotely',
                'actor': 'sync-service',
                'createdAt': '2026-03-05T01:00:03Z',
              }
            ],
          }),
          200,
        );
      }),
    );

    final result = await gateway.pullChanges(since: null);

    expect(result.changes, hasLength(1));
    expect(result.changes.first.entity, 'task');
    expect(result.changes.first.entityId, 'task-1');
    expect(result.changes.first.operation, 'upsert');
    expect(
      result.changes.first.serverUpdatedAt.toIso8601String(),
      '2026-03-05T01:00:01.000Z',
    );
    expect(result.changes.first.payload['title'], 'Remote task');
    expect(result.conflicts, hasLength(1));
    expect(result.conflicts.first.field, 'status');
    expect(result.auditEntries, hasLength(1));
    expect(result.auditEntries.first.actor, 'sync-service');
  });

  test('fetchConflicts and fetchAudit parse list payloads', () async {
    final gateway = HttpSyncGateway(
      baseUrl: 'https://api.example.com',
      client: MockClient((request) async {
        if (request.url.path == '/v1/conflicts') {
          return http.Response(
            jsonEncode({
              'conflicts': [
                {
                  'id': 'c1',
                  'entity': 'finance_entry',
                  'entityId': 'f1',
                  'fields': ['amount'],
                  'summary': 'Amount mismatch',
                  'createdAt': '2026-03-05T00:00:00Z',
                }
              ]
            }),
            200,
          );
        }

        return http.Response(
          jsonEncode({
            'audit': [
              {
                'id': 'a1',
                'entity': 'client',
                'entityId': 'c1',
                'action': 'updated',
                'summary': 'Client updated',
                'actor': 'Manager',
                'createdAt': '2026-03-05T00:00:00Z',
              }
            ]
          }),
          200,
        );
      }),
    );

    final conflicts = await gateway.fetchConflicts(
      since: DateTime.parse('2026-03-01T00:00:00Z'),
    );
    final audit = await gateway.fetchAudit(
      since: DateTime.parse('2026-03-01T00:00:00Z'),
    );

    expect(conflicts.length, 1);
    expect(conflicts.first.field, 'amount');
    expect(audit.length, 1);
    expect(audit.first.action, 'updated');
    expect(audit.first.actor, 'Manager');
  });
}
