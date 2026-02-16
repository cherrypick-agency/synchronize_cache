import 'package:uuid/uuid.dart';

import '../models/todo.dart';

class ListResult {
  ListResult({
    required this.items,
    this.nextPageToken,
  });

  final List<Todo> items;
  final String? nextPageToken;
}

class TodoRepository {
  TodoRepository();

  final Map<String, Todo> _storage = {};
  static const _uuid = Uuid();

  DateTime _now() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
  }

  ListResult list({
    DateTime? updatedSince,
    int limit = 500,
    String? pageToken,
    bool includeDeleted = true,
  }) {
    var items = _storage.values.toList();

    if (updatedSince != null) {
      items = items.where((todo) {
        return todo.updatedAt.isAfter(updatedSince) || todo.updatedAt.isAtSameMomentAs(updatedSince);
      }).toList();
    }

    if (!includeDeleted) {
      items = items.where((todo) => todo.deletedAt == null).toList();
    }

    items.sort((a, b) {
      final cmp = a.updatedAt.compareTo(b.updatedAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    final offset = int.tryParse(pageToken ?? '') ?? 0;
    final endIndex = (offset + limit).clamp(0, items.length);
    final pageItems = items.sublist(offset, endIndex);

    String? nextPageToken;
    if (endIndex < items.length) {
      nextPageToken = endIndex.toString();
    }

    return ListResult(items: pageItems, nextPageToken: nextPageToken);
  }

  Todo? getById(String id) => _storage[id];

  Todo create(Map<String, dynamic> data) {
    final now = _now();
    final id = data['id'] as String? ?? _uuid.v4();
    final cleanData = _stripSystemFields(data);
    final priority = (cleanData['priority'] as int? ?? 3).clamp(1, 5);

    final todo = Todo(
      id: id,
      title: cleanData['title'] as String? ?? '',
      description: cleanData['description'] as String?,
      completed: cleanData['completed'] as bool? ?? false,
      priority: priority,
      dueDate: _parseDateTime(cleanData['due_date']),
      updatedAt: now,
    );

    _storage[id] = todo;
    return todo;
  }

  Todo update(String id, Map<String, dynamic> data) {
    final now = _now();
    final existing = _storage[id];
    final cleanData = _stripSystemFields(data);
    final rawPriority = cleanData['priority'] as int?;
    final priority = rawPriority?.clamp(1, 5);

    if (existing == null) {
      final todo = Todo(
        id: id,
        title: cleanData['title'] as String? ?? '',
        description: cleanData['description'] as String?,
        completed: cleanData['completed'] as bool? ?? false,
        priority: priority ?? 3,
        dueDate: _parseDateTime(cleanData['due_date']),
        updatedAt: now,
      );
      _storage[id] = todo;
      return todo;
    }

    final updated = existing.copyWith(
      title: cleanData['title'] as String? ?? existing.title,
      description: cleanData.containsKey('description') ? cleanData['description'] as String? : existing.description,
      completed: cleanData['completed'] as bool? ?? existing.completed,
      priority: priority ?? existing.priority,
      dueDate: cleanData.containsKey('due_date') ? _parseDateTime(cleanData['due_date']) : existing.dueDate,
      updatedAt: now,
    );

    _storage[id] = updated;
    return updated;
  }

  Todo? delete(String id) {
    final existing = _storage[id];
    if (existing == null) return null;

    final now = _now();
    final deleted = existing.copyWith(deletedAt: now, updatedAt: now);
    _storage[id] = deleted;
    return deleted;
  }

  void clear() => _storage.clear();

  void seed(List<Todo> todos) {
    for (final todo in todos) {
      _storage[todo.id] = todo;
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

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
