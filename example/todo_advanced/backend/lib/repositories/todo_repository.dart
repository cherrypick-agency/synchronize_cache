import 'package:todo_advanced_backend/models/todo.dart';

/// Represents the result of an update/delete operation.
sealed class OperationResult {}

/// Operation succeeded.
class OperationSuccess extends OperationResult {
  OperationSuccess(this.todo);
  final Todo? todo;
}

/// Operation failed due to conflict.
class OperationConflict extends OperationResult {
  OperationConflict(this.current);
  final Todo current;
}

/// Operation failed because entity not found.
class OperationNotFound extends OperationResult {}

/// In-memory repository for todos with conflict detection.
class TodoRepository {
  final Map<String, Todo> _todos = {};
  final Set<String> _processedIdempotencyKeys = {};

  /// Lists all non-deleted todos, with optional pagination.
  List<Todo> list({
    DateTime? updatedSince,
    int limit = 500,
    String? pageToken,
  }) {
    var todos = _todos.values.where((t) => t.deletedAt == null);

    if (updatedSince != null) {
      todos = todos.where((t) => t.updatedAt.isAfter(updatedSince));
    }

    var sorted = todos.toList()
      ..sort((a, b) {
        final cmp = a.updatedAt.compareTo(b.updatedAt);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });

    if (pageToken != null) {
      final idx = sorted.indexWhere((t) => t.id == pageToken);
      if (idx != -1) {
        sorted = sorted.sublist(idx + 1);
      }
    }

    if (sorted.length > limit) {
      return sorted.sublist(0, limit);
    }
    return sorted;
  }

  /// Gets a todo by id.
  Todo? get(String id) => _todos[id];

  /// Creates a new todo.
  Todo create(Todo todo) {
    _todos[todo.id] = todo;
    return todo;
  }

  /// Updates a todo with conflict detection.
  ///
  /// If [baseUpdatedAt] is provided, checks that current.updatedAt matches.
  /// Returns [OperationConflict] if there's a mismatch.
  /// If [forceUpdate] is true, skips conflict check.
  OperationResult update(
    String id,
    Todo updated, {
    DateTime? baseUpdatedAt,
    bool forceUpdate = false,
    String? idempotencyKey,
  }) {
    if (idempotencyKey != null &&
        _processedIdempotencyKeys.contains(idempotencyKey)) {
      final current = _todos[id];
      return current != null ? OperationSuccess(current) : OperationNotFound();
    }

    final current = _todos[id];
    if (current == null) {
      _todos[id] = updated;
      if (idempotencyKey != null) {
        _processedIdempotencyKeys.add(idempotencyKey);
      }
      return OperationSuccess(updated);
    }

    if (!forceUpdate && baseUpdatedAt != null) {
      if (current.updatedAt != baseUpdatedAt) {
        return OperationConflict(current);
      }
    }

    _todos[id] = updated;
    if (idempotencyKey != null) {
      _processedIdempotencyKeys.add(idempotencyKey);
    }
    return OperationSuccess(updated);
  }

  /// Deletes a todo with conflict detection.
  ///
  /// If [baseUpdatedAt] is provided, checks that current.updatedAt matches.
  /// Returns [OperationConflict] if there's a mismatch.
  /// If [forceDelete] is true, skips conflict check.
  OperationResult delete(
    String id, {
    DateTime? baseUpdatedAt,
    bool forceDelete = false,
    String? idempotencyKey,
  }) {
    if (idempotencyKey != null &&
        _processedIdempotencyKeys.contains(idempotencyKey)) {
      return OperationSuccess(null);
    }

    final current = _todos[id];
    if (current == null) {
      return OperationNotFound();
    }

    if (!forceDelete && baseUpdatedAt != null) {
      if (current.updatedAt != baseUpdatedAt) {
        return OperationConflict(current);
      }
    }

    final now = DateTime.now().toUtc();
    _todos[id] = current.copyWith(
      updatedAt: now,
      deletedAt: now,
    );
    if (idempotencyKey != null) {
      _processedIdempotencyKeys.add(idempotencyKey);
    }
    return OperationSuccess(_todos[id]);
  }

  /// Checks if an idempotency key was already processed.
  bool isIdempotencyKeyProcessed(String key) {
    return _processedIdempotencyKeys.contains(key);
  }

  /// Clears all data (for testing).
  void clear() {
    _todos.clear();
    _processedIdempotencyKeys.clear();
  }
}
