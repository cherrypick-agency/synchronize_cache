import 'package:json_annotation/json_annotation.dart';

part 'todo.g.dart';

/// Todo model for the backend.
///
/// Uses snake_case for JSON serialization.
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
  });

  final String id;
  final String title;
  final String? description;
  final bool completed;
  final int priority;
  final DateTime? dueDate;
  final DateTime updatedAt;
  final DateTime? deletedAt;

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
    );
  }
}
