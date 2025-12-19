import 'package:todo_advanced_backend/models/todo.dart';
import 'package:todo_advanced_backend/repositories/todo_repository.dart';

/// Service for simulating server-side modifications to todos.
///
/// This demonstrates scenarios where the server modifies data independently,
/// which can cause conflicts with client changes.
class SimulationService {
  SimulationService(this._repository);

  final TodoRepository _repository;

  /// Adds a reminder to a todo's description.
  ///
  /// Simulates a server-side process that adds a reminder notice.
  /// Returns the updated todo or null if not found.
  Todo? addReminder(String id, String reminderText) {
    final current = _repository.get(id);
    if (current == null || current.deletedAt != null) return null;

    final now = DateTime.now().toUtc();
    final newDescription = current.description != null
        ? '${current.description}\n\n📋 Reminder: $reminderText'
        : '📋 Reminder: $reminderText';

    final updated = current.copyWith(
      description: newDescription,
      updatedAt: now,
    );

    final result = _repository.update(id, updated, forceUpdate: true);
    if (result is OperationSuccess) {
      return result.todo;
    }
    return null;
  }

  /// Auto-completes overdue todos.
  ///
  /// Simulates a server-side cron job that marks overdue incomplete todos.
  /// Returns list of todos that were auto-completed.
  List<Todo> autoCompleteOverdue() {
    final now = DateTime.now().toUtc();
    final completed = <Todo>[];

    final allTodos = _repository.list(limit: 1000);
    for (final todo in allTodos) {
      if (!todo.completed &&
          todo.dueDate != null &&
          todo.dueDate!.isBefore(now)) {
        final updated = todo.copyWith(
          completed: true,
          description: todo.description != null
              ? '${todo.description}\n\n⏰ Auto-completed (overdue)'
              : '⏰ Auto-completed (overdue)',
          updatedAt: now,
        );

        final result = _repository.update(todo.id, updated, forceUpdate: true);
        if (result is OperationSuccess && result.todo != null) {
          completed.add(result.todo!);
        }
      }
    }

    return completed;
  }

  /// Changes a todo's priority.
  ///
  /// Simulates a server-side priority adjustment.
  /// Returns the updated todo or null if not found.
  Todo? changePriority(String id, int newPriority) {
    final current = _repository.get(id);
    if (current == null || current.deletedAt != null) return null;

    final now = DateTime.now().toUtc();
    final updated = current.copyWith(
      priority: newPriority,
      updatedAt: now,
    );

    final result = _repository.update(id, updated, forceUpdate: true);
    if (result is OperationSuccess) {
      return result.todo;
    }
    return null;
  }
}
