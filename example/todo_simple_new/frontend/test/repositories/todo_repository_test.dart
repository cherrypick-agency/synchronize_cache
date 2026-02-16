@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_simple_new_frontend/database/database.dart';
import 'package:todo_simple_new_frontend/repositories/todo_repository.dart';
import 'package:todo_simple_new_frontend/sync/todo_sync.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repository;

  setUp(() {
    db = createTestDatabase();
    repository = TodoRepository(db, todoSyncTable(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('create adds row and outbox entry', () async {
    final todo = await repository.create(title: 'New Todo');
    expect(todo.id, isNotEmpty);

    final rows = await repository.getAll();
    expect(rows.length, 1);
    expect(rows.first.title, 'New Todo');

    final outbox = await db.takeOutbox();
    expect(outbox.length, 1);
    expect(outbox.first.kind, 'todos');
  });

  test('update uses diff enqueue and preserves one op', () async {
    final todo = await repository.create(title: 'Before');
    final initial = await db.takeOutbox();
    await db.ackOutbox(initial.map((e) => e.opId));

    final updated = await repository.update(todo, title: 'After', completed: true);
    expect(updated.title, 'After');
    expect(updated.completed, isTrue);

    final outbox = await db.takeOutbox();
    expect(outbox.length, 1);
  });
}
