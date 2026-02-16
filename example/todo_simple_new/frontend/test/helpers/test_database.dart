import 'package:drift/native.dart';
import 'package:todo_simple_new_frontend/database/database.dart';

AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
