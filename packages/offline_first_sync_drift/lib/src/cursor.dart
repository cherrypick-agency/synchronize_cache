/// Cursor for stable pagination: `(updatedAt, lastId)`.
class Cursor {
  const Cursor({required this.ts, required this.lastId});

  /// Timestamp of the last item.
  final DateTime ts;

  /// ID of the last item to resolve timestamp collisions.
  final String lastId;
}
