import 'package:offline_first_sync_drift/src/conflict_resolution.dart';
import 'package:test/test.dart';

void main() {
  group('ConflictStrategy', () {
    test('has all expected values', () {
      expect(ConflictStrategy.values, hasLength(6));
      expect(ConflictStrategy.values, contains(ConflictStrategy.serverWins));
      expect(ConflictStrategy.values, contains(ConflictStrategy.clientWins));
      expect(ConflictStrategy.values, contains(ConflictStrategy.lastWriteWins));
      expect(ConflictStrategy.values, contains(ConflictStrategy.merge));
      expect(ConflictStrategy.values, contains(ConflictStrategy.manual));
      expect(ConflictStrategy.values, contains(ConflictStrategy.autoPreserve));
    });
  });

  group('ConflictResolution classes', () {
    test('AcceptServer creates instance', () {
      const resolution = AcceptServer();
      expect(resolution, isA<ConflictResolution>());
    });

    test('AcceptClient creates instance', () {
      const resolution = AcceptClient();
      expect(resolution, isA<ConflictResolution>());
    });

    test('AcceptMerged creates with merged data', () {
      const resolution = AcceptMerged({'name': 'Merged', 'value': 42});

      expect(resolution, isA<ConflictResolution>());
      expect(resolution.mergedData, equals({'name': 'Merged', 'value': 42}));
      expect(resolution.mergeInfo, isNull);
    });

    test('AcceptMerged creates with merge info', () {
      const mergeInfo = MergeInfo(
        localFields: {'name'},
        serverFields: {'updatedAt'},
      );
      const resolution = AcceptMerged({
        'name': 'Local',
        'updatedAt': '2024-01-01',
      }, mergeInfo: mergeInfo);

      expect(resolution.mergeInfo, isNotNull);
      expect(resolution.mergeInfo!.localFields, contains('name'));
      expect(resolution.mergeInfo!.serverFields, contains('updatedAt'));
    });

    test('DeferResolution creates instance', () {
      const resolution = DeferResolution();
      expect(resolution, isA<ConflictResolution>());
    });

    test('DiscardOperation creates instance', () {
      const resolution = DiscardOperation();
      expect(resolution, isA<ConflictResolution>());
    });
  });

  group('MergeInfo', () {
    test('creates with local and server fields', () {
      const info = MergeInfo(
        localFields: {'title', 'description'},
        serverFields: {'createdAt', 'updatedAt'},
      );

      expect(info.localFields, equals({'title', 'description'}));
      expect(info.serverFields, equals({'createdAt', 'updatedAt'}));
    });

    test('creates with empty sets', () {
      const info = MergeInfo(localFields: {}, serverFields: {});

      expect(info.localFields, isEmpty);
      expect(info.serverFields, isEmpty);
    });
  });

  group('Conflict', () {
    test('creates with required parameters', () {
      final conflict = Conflict(
        kind: 'users',
        entityId: 'user-123',
        opId: 'op-456',
        localData: {'name': 'Local Name'},
        serverData: {'name': 'Server Name'},
        localTimestamp: DateTime.utc(2024, 1, 15, 10, 0),
        serverTimestamp: DateTime.utc(2024, 1, 15, 11, 0),
      );

      expect(conflict.kind, equals('users'));
      expect(conflict.entityId, equals('user-123'));
      expect(conflict.opId, equals('op-456'));
      expect(conflict.localData, equals({'name': 'Local Name'}));
      expect(conflict.serverData, equals({'name': 'Server Name'}));
      expect(conflict.localTimestamp, equals(DateTime.utc(2024, 1, 15, 10, 0)));
      expect(
        conflict.serverTimestamp,
        equals(DateTime.utc(2024, 1, 15, 11, 0)),
      );
      expect(conflict.serverVersion, isNull);
      expect(conflict.changedFields, isNull);
    });

    test('creates with optional parameters', () {
      final conflict = Conflict(
        kind: 'tasks',
        entityId: 'task-1',
        opId: 'op-1',
        localData: {},
        serverData: {},
        localTimestamp: DateTime.utc(2024, 1, 1),
        serverTimestamp: DateTime.utc(2024, 1, 2),
        serverVersion: 'v5',
        changedFields: {'title', 'status'},
      );

      expect(conflict.serverVersion, equals('v5'));
      expect(conflict.changedFields, equals({'title', 'status'}));
    });

    test('toString includes kind, entityId and timestamps', () {
      final conflict = Conflict(
        kind: 'items',
        entityId: 'item-99',
        opId: 'op-1',
        localData: {},
        serverData: {},
        localTimestamp: DateTime.utc(2024, 1, 15, 10, 30),
        serverTimestamp: DateTime.utc(2024, 1, 15, 11, 45),
      );

      final str = conflict.toString();
      expect(str, contains('Conflict'));
      expect(str, contains('items'));
      expect(str, contains('item-99'));
      expect(str, contains('2024-01-15'));
    });
  });

  group('ConflictUtils.systemFields', () {
    test('contains all expected system fields', () {
      expect(ConflictUtils.systemFields, contains('id'));
      expect(ConflictUtils.systemFields, contains('ID'));
      expect(ConflictUtils.systemFields, contains('uuid'));
      expect(ConflictUtils.systemFields, contains('updatedAt'));
      expect(ConflictUtils.systemFields, contains('updated_at'));
      expect(ConflictUtils.systemFields, contains('createdAt'));
      expect(ConflictUtils.systemFields, contains('created_at'));
      expect(ConflictUtils.systemFields, contains('deletedAt'));
      expect(ConflictUtils.systemFields, contains('deleted_at'));
    });
  });

  group('ConflictUtils.defaultMerge', () {
    test('server values used as base', () {
      final local = {'name': 'Local'};
      final server = {'name': 'Server', 'extra': 'field'};

      final result = ConflictUtils.defaultMerge(local, server);

      expect(result['name'], equals('Local'));
      expect(result['extra'], equals('field'));
    });

    test('local non-null values override server', () {
      final local = {'a': 1, 'b': 2};
      final server = {'a': 10, 'b': 20, 'c': 30};

      final result = ConflictUtils.defaultMerge(local, server);

      expect(result['a'], equals(1));
      expect(result['b'], equals(2));
      expect(result['c'], equals(30));
    });

    test('local null values do not override server', () {
      final local = <String, Object?>{'name': null, 'value': 42};
      final server = <String, Object?>{'name': 'Server', 'value': 0};

      final result = ConflictUtils.defaultMerge(local, server);

      expect(result['name'], equals('Server'));
      expect(result['value'], equals(42));
    });

    test('handles empty maps', () {
      final local = <String, Object?>{};
      final server = <String, Object?>{'key': 'value'};

      final result = ConflictUtils.defaultMerge(local, server);

      expect(result, equals({'key': 'value'}));
    });
  });

  group('ConflictUtils.deepMerge', () {
    test('merges flat objects', () {
      final local = {'a': 1, 'b': 2};
      final server = {'b': 20, 'c': 30};

      final result = ConflictUtils.deepMerge(local, server);

      expect(result['a'], equals(1));
      expect(result['b'], equals(2));
      expect(result['c'], equals(30));
    });

    test('merges nested objects recursively', () {
      final local = <String, Object?>{
        'user': {'name': 'Local', 'age': 25},
      };
      final server = <String, Object?>{
        'user': {'name': 'Server', 'email': 'server@test.com'},
      };

      final result = ConflictUtils.deepMerge(local, server);
      final user = result['user'] as Map<String, Object?>;

      expect(user['name'], equals('Local'));
      expect(user['age'], equals(25));
      expect(user['email'], equals('server@test.com'));
    });

    test('handles deeply nested objects', () {
      final local = <String, Object?>{
        'level1': {
          'level2': {
            'level3': {'value': 'local'},
          },
        },
      };
      final server = <String, Object?>{
        'level1': {
          'level2': {
            'level3': {'other': 'server'},
          },
        },
      };

      final result = ConflictUtils.deepMerge(local, server);
      final level3 =
          ((result['level1']! as Map)['level2']! as Map)['level3']! as Map;

      expect(level3['value'], equals('local'));
      expect(level3['other'], equals('server'));
    });

    test('local value wins for non-map types', () {
      final local = <String, Object?>{'key': 'local'};
      final server = <String, Object?>{'key': 'server'};

      final result = ConflictUtils.deepMerge(local, server);

      expect(result['key'], equals('local'));
    });

    test('server-only keys are preserved', () {
      final local = <String, Object?>{'a': 1};
      final server = <String, Object?>{'b': 2};

      final result = ConflictUtils.deepMerge(local, server);

      expect(result['a'], equals(1));
      expect(result['b'], equals(2));
    });
  });

  group('ConflictUtils.preservingMerge', () {
    test('system fields come from server', () {
      final local = <String, Object?>{
        'id': 'local-id',
        'updatedAt': '2024-01-01',
        'name': 'Local',
      };
      final server = <String, Object?>{
        'id': 'server-id',
        'updatedAt': '2024-01-02',
        'name': 'Server',
      };

      final result = ConflictUtils.preservingMerge(local, server);

      expect(result.data['id'], equals('server-id'));
      expect(result.data['updatedAt'], equals('2024-01-02'));
    });

    test('respects changedFields filter', () {
      final local = <String, Object?>{
        'title': 'Local Title',
        'description': 'Local Desc',
        'status': 'local',
      };
      final server = <String, Object?>{
        'title': 'Server Title',
        'description': 'Server Desc',
        'status': 'server',
      };

      final result = ConflictUtils.preservingMerge(
        local,
        server,
        changedFields: {'title'},
      );

      expect(result.data['title'], equals('Local Title'));
      expect(result.data['description'], equals('Server Desc'));
      expect(result.data['status'], equals('server'));
      expect(result.localFields, contains('title'));
    });

    test('local non-null wins over server null', () {
      final local = <String, Object?>{'value': 42};
      final server = <String, Object?>{'value': null};

      final result = ConflictUtils.preservingMerge(local, server);

      expect(result.data['value'], equals(42));
      expect(result.localFields, contains('value'));
    });

    test('server non-null preserved when local is null', () {
      final local = <String, Object?>{'value': null};
      final server = <String, Object?>{'value': 100};

      final result = ConflictUtils.preservingMerge(local, server);

      expect(result.data['value'], equals(100));
      expect(result.serverFields, contains('value'));
    });

    test('both null values are skipped', () {
      final local = <String, Object?>{'nullField': null};
      final server = <String, Object?>{'nullField': null};

      final result = ConflictUtils.preservingMerge(local, server);

      expect(result.data.containsKey('nullField'), isTrue);
      expect(result.data['nullField'], isNull);
    });

    test('lists are merged with union', () {
      final local = <String, Object?>{
        'tags': ['a', 'b'],
      };
      final server = <String, Object?>{
        'tags': ['b', 'c'],
      };

      final result = ConflictUtils.preservingMerge(local, server);
      final tags = result.data['tags'] as List;

      expect(tags, contains('a'));
      expect(tags, contains('b'));
      expect(tags, contains('c'));
    });

    test('list items with id are merged uniquely', () {
      final local = <String, Object?>{
        'items': [
          {'id': '1', 'value': 'local1'},
          {'id': '3', 'value': 'local3'},
        ],
      };
      final server = <String, Object?>{
        'items': [
          {'id': '1', 'value': 'server1'},
          {'id': '2', 'value': 'server2'},
        ],
      };

      final result = ConflictUtils.preservingMerge(local, server);
      final items = result.data['items'] as List;

      expect(items, hasLength(3));
      final ids = items.map((i) => (i as Map)['id']).toSet();
      expect(ids, equals({'1', '2', '3'}));
    });

    test('nested maps are merged recursively', () {
      final local = <String, Object?>{
        'metadata': {'local': 'value'},
      };
      final server = <String, Object?>{
        'metadata': {'server': 'data'},
      };

      final result = ConflictUtils.preservingMerge(local, server);
      final metadata = result.data['metadata'] as Map;

      expect(metadata.containsKey('local'), isTrue);
      expect(metadata.containsKey('server'), isTrue);
    });

    test('returns correct localFields tracking', () {
      final local = <String, Object?>{'name': 'Local', 'count': 10};
      final server = <String, Object?>{
        'name': 'Server',
        'count': 5,
        'extra': 'field',
      };

      final result = ConflictUtils.preservingMerge(local, server);

      expect(result.localFields, contains('name'));
      expect(result.localFields, contains('count'));
    });

    test('returns correct serverFields tracking', () {
      final local = <String, Object?>{'name': 'Local'};
      final server = <String, Object?>{'name': 'Server', 'serverOnly': 'value'};

      final result = ConflictUtils.preservingMerge(local, server);

      expect(result.serverFields, contains('serverOnly'));
    });

    test('empty changedFields means no local fields applied', () {
      final local = <String, Object?>{'title': 'Local', 'desc': 'Local Desc'};
      final server = <String, Object?>{
        'title': 'Server',
        'desc': 'Server Desc',
      };

      final result = ConflictUtils.preservingMerge(
        local,
        server,
        changedFields: {},
      );

      expect(result.data['title'], equals('Server'));
      expect(result.data['desc'], equals('Server Desc'));
    });

    test('null changedFields means all local fields applied', () {
      final local = <String, Object?>{'title': 'Local', 'desc': 'Local Desc'};
      final server = <String, Object?>{
        'title': 'Server',
        'desc': 'Server Desc',
      };

      final result = ConflictUtils.preservingMerge(local, server);

      expect(result.data['title'], equals('Local'));
      expect(result.data['desc'], equals('Local Desc'));
    });
  });

  group('ConflictUtils.extractTimestamp', () {
    test('extracts DateTime from updatedAt', () {
      final data = <String, Object?>{
        'updatedAt': DateTime.utc(2024, 1, 15, 10, 30),
      };

      final result = ConflictUtils.extractTimestamp(data);

      expect(result, equals(DateTime.utc(2024, 1, 15, 10, 30)));
    });

    test('extracts DateTime from updated_at', () {
      final data = <String, Object?>{'updated_at': DateTime.utc(2024, 2, 20)};

      final result = ConflictUtils.extractTimestamp(data);

      expect(result, equals(DateTime.utc(2024, 2, 20)));
    });

    test('parses string timestamp', () {
      final data = <String, Object?>{'updatedAt': '2024-03-15T14:30:00.000Z'};

      final result = ConflictUtils.extractTimestamp(data);

      expect(result, isNotNull);
      expect(result!.year, equals(2024));
      expect(result.month, equals(3));
      expect(result.day, equals(15));
    });

    test('returns null for missing timestamp', () {
      final data = <String, Object?>{'name': 'test'};

      final result = ConflictUtils.extractTimestamp(data);

      expect(result, isNull);
    });

    test('returns null for invalid timestamp string', () {
      final data = <String, Object?>{'updatedAt': 'not a date'};

      final result = ConflictUtils.extractTimestamp(data);

      expect(result, isNull);
    });

    test('prefers updatedAt over updated_at', () {
      final data = <String, Object?>{
        'updatedAt': DateTime.utc(2024, 1, 1),
        'updated_at': DateTime.utc(2024, 2, 2),
      };

      final result = ConflictUtils.extractTimestamp(data);

      expect(result, equals(DateTime.utc(2024, 1, 1)));
    });
  });

  group('PreservingMergeResult', () {
    test('creates with all parameters', () {
      const result = PreservingMergeResult(
        data: {'merged': 'data'},
        localFields: {'field1'},
        serverFields: {'field2'},
      );

      expect(result.data, equals({'merged': 'data'}));
      expect(result.localFields, equals({'field1'}));
      expect(result.serverFields, equals({'field2'}));
    });

    test('can have empty sets', () {
      const result = PreservingMergeResult(
        data: {},
        localFields: {},
        serverFields: {},
      );

      expect(result.data, isEmpty);
      expect(result.localFields, isEmpty);
      expect(result.serverFields, isEmpty);
    });
  });
}
