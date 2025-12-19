import 'package:drift/native.dart';
import 'package:todo_simple_frontend/database/database.dart';

/// Creates an in-memory database for testing.
///
/// This uses NativeDatabase which only works on native platforms (not web).
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
