import 'package:flutter_test/flutter_test.dart';
import 'package:todo_simple_new_frontend/models/todo.dart';

void main() {
  group('Todo', () {
    final now = DateTime.utc(2025, 1, 15, 10, 30);

    test('serializes and deserializes', () {
      final todo = Todo(
        id: 'id-1',
        title: 'Test',
        description: 'Desc',
        completed: true,
        priority: 2,
        updatedAt: now,
      );

      final json = todo.toJson();
      final parsed = Todo.fromJson(json);
      expect(parsed.id, todo.id);
      expect(parsed.title, todo.title);
      expect(parsed.description, todo.description);
      expect(parsed.completed, todo.completed);
      expect(parsed.priority, todo.priority);
      expect(parsed.updatedAt, todo.updatedAt);
    });
  });
}
