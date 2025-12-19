import 'package:flutter_test/flutter_test.dart';
import 'package:todo_advanced_frontend/models/todo.dart';

void main() {
  group('Todo', () {
    final now = DateTime.utc(2025, 1, 15, 10, 30);

    test('creates instance with required fields', () {
      final todo = Todo(
        id: 'test-id',
        title: 'Test Todo',
        updatedAt: now,
      );

      expect(todo.id, 'test-id');
      expect(todo.title, 'Test Todo');
      expect(todo.description, isNull);
      expect(todo.completed, false);
      expect(todo.priority, 3);
      expect(todo.dueDate, isNull);
      expect(todo.updatedAt, now);
      expect(todo.deletedAt, isNull);
      expect(todo.deletedAtLocal, isNull);
    });

    test('creates instance with all fields', () {
      final dueDate = DateTime.utc(2025, 1, 20);
      final deletedAt = DateTime.utc(2025, 1, 16);

      final todo = Todo(
        id: 'test-id',
        title: 'Test Todo',
        description: 'Test description',
        completed: true,
        priority: 1,
        dueDate: dueDate,
        updatedAt: now,
        deletedAt: deletedAt,
        deletedAtLocal: deletedAt,
      );

      expect(todo.id, 'test-id');
      expect(todo.title, 'Test Todo');
      expect(todo.description, 'Test description');
      expect(todo.completed, true);
      expect(todo.priority, 1);
      expect(todo.dueDate, dueDate);
      expect(todo.updatedAt, now);
      expect(todo.deletedAt, deletedAt);
      expect(todo.deletedAtLocal, deletedAt);
    });

    group('fromJson', () {
      test('parses minimal JSON', () {
        final json = {
          'id': 'test-id',
          'title': 'Test Todo',
          'completed': false,
          'priority': 3,
          'updated_at': now.toIso8601String(),
        };

        final todo = Todo.fromJson(json);

        expect(todo.id, 'test-id');
        expect(todo.title, 'Test Todo');
        expect(todo.completed, false);
        expect(todo.priority, 3);
        expect(todo.updatedAt, now);
        expect(todo.description, isNull);
        expect(todo.dueDate, isNull);
        expect(todo.deletedAt, isNull);
      });

      test('parses full JSON', () {
        final dueDate = DateTime.utc(2025, 1, 20);
        final deletedAt = DateTime.utc(2025, 1, 16);

        final json = {
          'id': 'test-id',
          'title': 'Test Todo',
          'description': 'Test description',
          'completed': true,
          'priority': 1,
          'due_date': dueDate.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'deleted_at': deletedAt.toIso8601String(),
          'deleted_at_local': deletedAt.toIso8601String(),
        };

        final todo = Todo.fromJson(json);

        expect(todo.id, 'test-id');
        expect(todo.title, 'Test Todo');
        expect(todo.description, 'Test description');
        expect(todo.completed, true);
        expect(todo.priority, 1);
        expect(todo.dueDate, dueDate);
        expect(todo.updatedAt, now);
        expect(todo.deletedAt, deletedAt);
        expect(todo.deletedAtLocal, deletedAt);
      });
    });

    group('toJson', () {
      test('serializes minimal todo', () {
        final todo = Todo(
          id: 'test-id',
          title: 'Test Todo',
          updatedAt: now,
        );

        final json = todo.toJson();

        expect(json['id'], 'test-id');
        expect(json['title'], 'Test Todo');
        expect(json['description'], isNull);
        expect(json['completed'], false);
        expect(json['priority'], 3);
        expect(json['due_date'], isNull);
        expect(json['updated_at'], now.toIso8601String());
        expect(json['deleted_at'], isNull);
        expect(json['deleted_at_local'], isNull);
      });

      test('serializes full todo', () {
        final dueDate = DateTime.utc(2025, 1, 20);

        final todo = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Test description',
          completed: true,
          priority: 1,
          dueDate: dueDate,
          updatedAt: now,
        );

        final json = todo.toJson();

        expect(json['id'], 'test-id');
        expect(json['title'], 'Test Todo');
        expect(json['description'], 'Test description');
        expect(json['completed'], true);
        expect(json['priority'], 1);
        expect(json['due_date'], dueDate.toIso8601String());
        expect(json['updated_at'], now.toIso8601String());
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        final todo = Todo(
          id: 'test-id',
          title: 'Test Todo',
          updatedAt: now,
        );

        final copy = todo.copyWith();

        expect(copy.id, todo.id);
        expect(copy.title, todo.title);
        expect(copy.updatedAt, todo.updatedAt);
      });

      test('copies with changes', () {
        final todo = Todo(
          id: 'test-id',
          title: 'Test Todo',
          updatedAt: now,
        );

        final copy = todo.copyWith(
          title: 'Updated Title',
          completed: true,
          priority: 1,
        );

        expect(copy.id, 'test-id');
        expect(copy.title, 'Updated Title');
        expect(copy.completed, true);
        expect(copy.priority, 1);
        expect(copy.updatedAt, now);
      });
    });

    test('toString returns readable format', () {
      final todo = Todo(
        id: 'test-id',
        title: 'Test Todo',
        updatedAt: now,
      );

      expect(
        todo.toString(),
        'Todo(id: test-id, title: Test Todo, completed: false)',
      );
    });

    group('equality', () {
      test('equal todos are equal', () {
        final dueDate = DateTime.utc(2025, 1, 20);

        final todo1 = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Description',
          completed: true,
          priority: 2,
          dueDate: dueDate,
          updatedAt: now,
        );

        final todo2 = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Description',
          completed: true,
          priority: 2,
          dueDate: dueDate,
          updatedAt: now,
        );

        expect(todo1, equals(todo2));
        expect(todo1.hashCode, equals(todo2.hashCode));
      });

      test('different todos are not equal', () {
        final todo1 = Todo(
          id: 'test-id-1',
          title: 'Test Todo 1',
          updatedAt: now,
        );

        final todo2 = Todo(
          id: 'test-id-2',
          title: 'Test Todo 2',
          updatedAt: now,
        );

        expect(todo1, isNot(equals(todo2)));
      });
    });

    group('JSON roundtrip', () {
      test('preserves all data through serialization', () {
        final dueDate = DateTime.utc(2025, 1, 20);
        final deletedAt = DateTime.utc(2025, 1, 16);

        final original = Todo(
          id: 'test-id',
          title: 'Test Todo',
          description: 'Test description',
          completed: true,
          priority: 2,
          dueDate: dueDate,
          updatedAt: now,
          deletedAt: deletedAt,
          deletedAtLocal: deletedAt,
        );

        final json = original.toJson();
        final restored = Todo.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.description, original.description);
        expect(restored.completed, original.completed);
        expect(restored.priority, original.priority);
        expect(restored.dueDate, original.dueDate);
        expect(restored.updatedAt, original.updatedAt);
        expect(restored.deletedAt, original.deletedAt);
        expect(restored.deletedAtLocal, original.deletedAtLocal);
      });
    });
  });
}
