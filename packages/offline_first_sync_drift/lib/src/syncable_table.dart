import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/src/constants.dart';

/// Конфигурация синхронизируемой таблицы.
/// Регистрируется в SyncEngine для автоматической синхронизации.
class SyncableTable<T> {
  const SyncableTable({
    required this.kind,
    required this.table,
    required this.fromJson,
    required this.toJson,
    this.toInsertable,
    this.getId,
    this.getUpdatedAt,
  });

  /// Имя сущности на сервере (например, 'daily_feeling').
  final String kind;

  /// Drift таблица.
  final TableInfo<Table, T> table;

  /// Фабрика для создания объекта из JSON сервера.
  final T Function(Map<String, dynamic> json) fromJson;

  /// Сериализация объекта в JSON для отправки на сервер.
  final Map<String, dynamic> Function(T entity) toJson;

  /// Конвертация entity в Insertable для записи в БД.
  /// Если используете @UseRowClass(T, generateInsertable: true),
  /// передайте: toInsertable: (e) => e.toInsertable()
  /// Если T реализует `Insertable<T>`, можно не указывать.
  final Insertable<T> Function(T entity)? toInsertable;

  /// Получить ID сущности. По умолчанию ищет поле 'id'.
  final String Function(T entity)? getId;

  /// Получить updatedAt сущности. По умолчанию ищет поле 'updatedAt'.
  final DateTime Function(T entity)? getUpdatedAt;

  /// Получить Insertable из entity.
  Insertable<T> getInsertable(T entity) {
    if (toInsertable != null) {
      return toInsertable!(entity);
    }
    // Fallback: assume entity implements Insertable<T>
    return entity as Insertable<T>;
  }

  /// Получить ID сущности.
  ///
  /// Prefer providing [getId] for best performance and correctness.
  /// Fallback: derives id from [toJson] using [SyncFields.idFields].
  String idOf(T entity) {
    if (getId != null) return getId!(entity);
    final json = toJson(entity);
    for (final key in SyncFields.idFields) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    throw StateError(
      'Cannot determine entity id for kind "$kind". '
      'Provide getId: (e) => e.id (recommended).',
    );
  }

  /// Получить updatedAt сущности.
  ///
  /// Prefer providing [getUpdatedAt] for best performance and correctness.
  /// Fallback: derives timestamp from [toJson] using [SyncFields.updatedAtFields].
  DateTime updatedAtOf(T entity) {
    if (getUpdatedAt != null) return getUpdatedAt!(entity);
    final json = toJson(entity);
    for (final key in SyncFields.updatedAtFields) {
      final value = json[key];
      if (value is DateTime) return value.toUtc();
      if (value != null) {
        final parsed = DateTime.tryParse(value.toString());
        if (parsed != null) return parsed.toUtc();
      }
    }
    throw StateError(
      'Cannot determine entity updatedAt for kind "$kind". '
      'Provide getUpdatedAt: (e) => e.updatedAt (recommended).',
    );
  }
}
