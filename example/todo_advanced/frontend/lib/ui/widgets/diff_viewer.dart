import 'package:flutter/material.dart';

import '../../models/todo.dart';

/// Widget showing differences between local and server todos.
class DiffViewer extends StatelessWidget {
  const DiffViewer({
    super.key,
    required this.localTodo,
    required this.serverTodo,
  });

  final Todo localTodo;
  final Todo serverTodo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone_android, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Local Version',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.cloud, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Server Version',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Fields comparison
          _DiffRow(
            fieldName: 'Title',
            localValue: localTodo.title,
            serverValue: serverTodo.title,
          ),
          _DiffRow(
            fieldName: 'Description',
            localValue: localTodo.description ?? '(empty)',
            serverValue: serverTodo.description ?? '(empty)',
          ),
          _DiffRow(
            fieldName: 'Completed',
            localValue: localTodo.completed ? 'Yes' : 'No',
            serverValue: serverTodo.completed ? 'Yes' : 'No',
          ),
          _DiffRow(
            fieldName: 'Priority',
            localValue: _priorityLabel(localTodo.priority),
            serverValue: _priorityLabel(serverTodo.priority),
          ),
          _DiffRow(
            fieldName: 'Due Date',
            localValue: _formatDate(localTodo.dueDate),
            serverValue: _formatDate(serverTodo.dueDate),
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _priorityLabel(int priority) {
    return switch (priority) {
      1 => '1 (Highest)',
      2 => '2 (High)',
      3 => '3 (Medium)',
      4 => '4 (Low)',
      5 => '5 (Lowest)',
      _ => priority.toString(),
    };
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '(none)';
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.fieldName,
    required this.localValue,
    required this.serverValue,
    this.isLast = false,
  });

  final String fieldName;
  final String localValue;
  final String serverValue;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDifferent = localValue != serverValue;

    return Container(
      decoration: BoxDecoration(
        color: isDifferent ? Colors.orange.withValues(alpha: 0.05) : null,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
              ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(7))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field name
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Text(
                  fieldName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDifferent ? Colors.orange : Colors.grey,
                  ),
                ),
                if (isDifferent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CHANGED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Values
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Text(
                    localValue,
                    style: TextStyle(
                      color: isDifferent ? Colors.blue : null,
                      fontWeight: isDifferent ? FontWeight.w500 : null,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    serverValue,
                    style: TextStyle(
                      color: isDifferent ? Colors.green : null,
                      fontWeight: isDifferent ? FontWeight.w500 : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
