import 'package:json_annotation/json_annotation.dart';

part 'todo.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Todo {
  Todo({
    required this.id,
    required this.title,
    this.description,
    this.completed = false,
    this.priority = 3,
    this.dueDate,
    required this.updatedAt,
    this.deletedAt,
    this.deletedAtLocal,
  });

  final String id;
  final String title;
  final String? description;
  final bool completed;
  final int priority;
  final DateTime? dueDate;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? deletedAtLocal;

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
  Map<String, dynamic> toJson() => _$TodoToJson(this);

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    int? priority,
    DateTime? dueDate,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? deletedAtLocal,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedAtLocal: deletedAtLocal ?? this.deletedAtLocal,
    );
  }

  @override
  String toString() => 'Todo(id: $id, title: $title, completed: $completed)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          completed == other.completed &&
          priority == other.priority &&
          dueDate == other.dueDate &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt &&
          deletedAtLocal == other.deletedAtLocal;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        completed,
        priority,
        dueDate,
        updatedAt,
        deletedAt,
        deletedAtLocal,
      );
}
