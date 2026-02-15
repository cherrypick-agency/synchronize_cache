/// Helper to track changed fields for conflict-aware updates.
///
/// `changedFields` is used by conflict resolution (e.g. autoPreserve) to avoid
/// overwriting server-side changes for fields the user did not edit.
class ChangedFieldsTracker {
  final Set<String> _fields = <String>{};

  /// Mark a field as changed if [from] differs from [to].
  ///
  /// Returns [to], so it can be used inline in copyWith:
  /// `title: tracker.changed('title', from: old.title, to: newTitle)`.
  T changed<T>(String field, {required T from, required T to}) {
    if (from != to) _fields.add(field);
    return to;
  }

  /// Mark a field as changed if [condition] is true.
  void markIf(String field, bool condition) {
    if (condition) _fields.add(field);
  }

  /// Explicitly mark a field as changed.
  void mark(String field) => _fields.add(field);

  /// All tracked fields.
  Set<String> get fields => Set<String>.unmodifiable(_fields);

  /// Returns null when there are no tracked changes (recommended for ops).
  Set<String>? get fieldsOrNull => _fields.isEmpty ? null : fields;
}

/// Utilities for automatic changed-fields diffing.
abstract final class ChangedFieldsDiff {
  /// System fields that should not participate in business diff logic.
  static const defaultIgnoredFields = {
    'id',
    'ID',
    'uuid',
    'updatedAt',
    'updated_at',
    'createdAt',
    'created_at',
    'deletedAt',
    'deleted_at',
    'deletedAtLocal',
    'deleted_at_local',
  };

  /// Returns changed top-level fields between [before] and [after].
  static Set<String> diffMaps(
    Map<String, Object?> before,
    Map<String, Object?> after, {
    Set<String> ignoredFields = defaultIgnoredFields,
  }) {
    final keys = {...before.keys, ...after.keys};
    final changed = <String>{};

    for (final key in keys) {
      if (ignoredFields.contains(key)) continue;
      if (!_deepEquals(before[key], after[key])) {
        changed.add(key);
      }
    }
    return changed;
  }

  /// Returns null when there are no changed fields.
  static Set<String>? diffOrNullMaps(
    Map<String, Object?> before,
    Map<String, Object?> after, {
    Set<String> ignoredFields = defaultIgnoredFields,
  }) {
    final changed = diffMaps(before, after, ignoredFields: ignoredFields);
    return changed.isEmpty ? null : changed;
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;

    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }

    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }

    return a == b;
  }
}
