import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

import '../../models/todo.dart';

@UseRowClass(Todo, generateInsertable: true)
class Todos extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(3))();
  DateTimeColumn get dueDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
