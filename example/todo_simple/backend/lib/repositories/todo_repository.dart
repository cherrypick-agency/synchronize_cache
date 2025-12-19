import '../models/todo.dart';

/// Result of a paginated list query.
class ListResult {
  ListResult({
    required this.items,
    this.nextPageToken,
  });

  final List<Todo> items;
  final String? nextPageToken;
}

/// In-memory repository for todos.
///
/// This is a simple implementation suitable for demos.
/// In production, use a real database.
class TodoRepository {
  TodoRepository();

  /// In-memory storage: id -> Todo.
  final Map<String, Todo> _storage = {};

  DateTime _now() {
    final now = DateTime.now().toUtc();
    // Truncate to seconds for consistent comparison
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
  }

  /// Lists todos with pagination support.
  ///
  /// - [updatedSince]: Only return todos updated after this timestamp.
  /// - [limit]: Maximum number of items to return.
  /// - [pageToken]: Offset for pagination (as string).
  /// - [includeDeleted]: Whether to include soft-deleted items.
  ListResult list({
    DateTime? updatedSince,
    int limit = 500,
    String? pageToken,
    bool includeDeleted = true,
  }) {
    var items = _storage.values.toList();

    // Filter by updatedSince
    if (updatedSince != null) {
      items = items.where((todo) {
        return todo.updatedAt.isAfter(updatedSince) ||
            todo.updatedAt.isAtSameMomentAs(updatedSince);
      }).toList();
    }

    // Filter deleted if needed
    if (!includeDeleted) {
      items = items.where((todo) => todo.deletedAt == null).toList();
    }

    // Sort by (updatedAt, id) for stable pagination
    items.sort((a, b) {
      final cmp = a.updatedAt.compareTo(b.updatedAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    // Apply pagination
    final offset = int.tryParse(pageToken ?? '') ?? 0;
    final endIndex = (offset + limit).clamp(0, items.length);
    final pageItems = items.sublist(offset, endIndex);

    // Calculate next page token
    String? nextPageToken;
    if (endIndex < items.length) {
      nextPageToken = endIndex.toString();
    }

    return ListResult(items: pageItems, nextPageToken: nextPageToken);
  }

  /// Gets a todo by ID.
  Todo? getById(String id) => _storage[id];

  /// Creates a new todo.
  Todo create(Map<String, dynamic> data) {
    final now = _now();
    final id = data['id'] as String? ?? _generateId();

    // Remove system fields from payload
    final cleanData = _stripSystemFields(data);

    final todo = Todo(
      id: id,
      title: cleanData['title'] as String? ?? '',
      description: cleanData['description'] as String?,
      completed: cleanData['completed'] as bool? ?? false,
      priority: cleanData['priority'] as int? ?? 3,
      dueDate: _parseDateTime(cleanData['due_date']),
      updatedAt: now,
      createdAt: now,
    );

    _storage[id] = todo;
    return todo;
  }

  /// Updates an existing todo or creates if not exists (upsert).
  ///
  /// In simplified flow, `_baseUpdatedAt` is ignored (no conflict check).
  Todo update(String id, Map<String, dynamic> data) {
    final now = _now();
    final existing = _storage[id];

    // Remove system fields from payload
    final cleanData = _stripSystemFields(data);

    if (existing == null) {
      // Upsert: create new todo
      final todo = Todo(
        id: id,
        title: cleanData['title'] as String? ?? '',
        description: cleanData['description'] as String?,
        completed: cleanData['completed'] as bool? ?? false,
        priority: cleanData['priority'] as int? ?? 3,
        dueDate: _parseDateTime(cleanData['due_date']),
        updatedAt: now,
        createdAt: now,
      );
      _storage[id] = todo;
      return todo;
    }

    // Update existing todo
    final updated = existing.copyWith(
      title: cleanData['title'] as String? ?? existing.title,
      description: cleanData.containsKey('description')
          ? cleanData['description'] as String?
          : existing.description,
      completed: cleanData['completed'] as bool? ?? existing.completed,
      priority: cleanData['priority'] as int? ?? existing.priority,
      dueDate: cleanData.containsKey('due_date')
          ? _parseDateTime(cleanData['due_date'])
          : existing.dueDate,
      updatedAt: now,
    );

    _storage[id] = updated;
    return updated;
  }

  /// Deletes a todo by ID.
  ///
  /// Returns true if deleted, false if not found.
  bool delete(String id) {
    return _storage.remove(id) != null;
  }

  /// Clears all todos (for testing).
  void clear() => _storage.clear();

  /// Seeds initial data (for testing/demo).
  void seed(List<Todo> todos) {
    for (final todo in todos) {
      _storage[todo.id] = todo;
    }
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// System fields that should be stripped from client payload.
  static const _systemFields = [
    'id',
    'ID',
    'uuid',
    'updated_at',
    'updatedAt',
    'created_at',
    'createdAt',
    'deleted_at',
    'deletedAt',
    '_baseUpdatedAt',
  ];

  Map<String, dynamic> _stripSystemFields(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    for (final field in _systemFields) {
      result.remove(field);
    }
    return result;
  }
}
