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

