import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/todo.dart';
import '../../services/conflict_handler.dart';
import 'diff_viewer.dart';

/// Dialog for resolving sync conflicts.
///
/// Shows local and server versions side by side,
/// allows user to choose local, server, or merge.
class ConflictDialog extends StatefulWidget {
  const ConflictDialog({
    super.key,
    required this.conflict,
  });

  final ConflictInfo conflict;

  @override
  State<ConflictDialog> createState() => _ConflictDialogState();
}

class _ConflictDialogState extends State<ConflictDialog> {
  late Todo _mergedTodo;
  bool _showMergeEditor = false;

  @override
  void initState() {
    super.initState();
    // Start with local version for merge
    _mergedTodo = widget.conflict.localTodo;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('Sync Conflict'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The todo "${widget.conflict.localTodo.title}" was modified both locally and on the server.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Diff viewer
              DiffViewer(
                localTodo: widget.conflict.localTodo,
                serverTodo: widget.conflict.serverTodo,
              ),

              if (_showMergeEditor) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _MergeEditor(
                  localTodo: widget.conflict.localTodo,
                  serverTodo: widget.conflict.serverTodo,
                  mergedTodo: _mergedTodo,
                  onChanged: (todo) => setState(() => _mergedTodo = todo),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        // Server button
        OutlinedButton.icon(
          onPressed: () => _resolveWithServer(context),
          icon: const Icon(Icons.cloud_download),
          label: const Text('Use Server'),
        ),

        // Merge button
        if (!_showMergeEditor)
          OutlinedButton.icon(
            onPressed: () => setState(() => _showMergeEditor = true),
            icon: const Icon(Icons.merge),
            label: const Text('Merge'),
          )
        else
          FilledButton.icon(
            onPressed: () => _resolveWithMerge(context),
            icon: const Icon(Icons.check),
            label: const Text('Apply Merge'),
          ),

        // Local button
        FilledButton.icon(
          onPressed: () => _resolveWithLocal(context),
          icon: const Icon(Icons.phone_android),
          label: const Text('Use Local'),
        ),
      ],
    );
  }

  void _resolveWithLocal(BuildContext context) {
    final handler = context.read<ConflictHandler>();
    handler.resolveWithLocal();
    Navigator.pop(context);
  }

  void _resolveWithServer(BuildContext context) {
    final handler = context.read<ConflictHandler>();
    handler.resolveWithServer();
    Navigator.pop(context);
  }

  void _resolveWithMerge(BuildContext context) {
    final handler = context.read<ConflictHandler>();
    handler.resolveWithMerged(_mergedTodo);
    Navigator.pop(context);
  }
}

class _MergeEditor extends StatelessWidget {
  const _MergeEditor({
    required this.localTodo,
    required this.serverTodo,
    required this.mergedTodo,
    required this.onChanged,
  });

  final Todo localTodo;
  final Todo serverTodo;
  final Todo mergedTodo;
  final ValueChanged<Todo> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Merge Editor',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which value to use for each field:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),

        // Title
        if (localTodo.title != serverTodo.title)
          _FieldMerger(
            fieldName: 'Title',
            localValue: localTodo.title,
            serverValue: serverTodo.title,
            currentValue: mergedTodo.title,
            onLocalSelected: () => onChanged(mergedTodo.copyWith(title: localTodo.title)),
            onServerSelected: () => onChanged(mergedTodo.copyWith(title: serverTodo.title)),
          ),

        // Description
        if (localTodo.description != serverTodo.description)
          _FieldMerger(
            fieldName: 'Description',
            localValue: localTodo.description ?? '(empty)',
            serverValue: serverTodo.description ?? '(empty)',
            currentValue: mergedTodo.description ?? '(empty)',
            onLocalSelected: () => onChanged(mergedTodo.copyWith(description: localTodo.description)),
            onServerSelected: () => onChanged(mergedTodo.copyWith(description: serverTodo.description)),
          ),

        // Completed
        if (localTodo.completed != serverTodo.completed)
          _FieldMerger(
            fieldName: 'Completed',
            localValue: localTodo.completed.toString(),
            serverValue: serverTodo.completed.toString(),
            currentValue: mergedTodo.completed.toString(),
            onLocalSelected: () => onChanged(mergedTodo.copyWith(completed: localTodo.completed)),
            onServerSelected: () => onChanged(mergedTodo.copyWith(completed: serverTodo.completed)),
          ),

        // Priority
        if (localTodo.priority != serverTodo.priority)
          _FieldMerger(
            fieldName: 'Priority',
            localValue: localTodo.priority.toString(),
            serverValue: serverTodo.priority.toString(),
            currentValue: mergedTodo.priority.toString(),
            onLocalSelected: () => onChanged(mergedTodo.copyWith(priority: localTodo.priority)),
            onServerSelected: () => onChanged(mergedTodo.copyWith(priority: serverTodo.priority)),
          ),

        // Due date
        if (localTodo.dueDate != serverTodo.dueDate)
          _FieldMerger(
            fieldName: 'Due Date',
            localValue: localTodo.dueDate?.toIso8601String() ?? '(none)',
            serverValue: serverTodo.dueDate?.toIso8601String() ?? '(none)',
            currentValue: mergedTodo.dueDate?.toIso8601String() ?? '(none)',
            onLocalSelected: () => onChanged(mergedTodo.copyWith(dueDate: localTodo.dueDate)),
            onServerSelected: () => onChanged(mergedTodo.copyWith(dueDate: serverTodo.dueDate)),
          ),
      ],
    );
  }
}

class _FieldMerger extends StatelessWidget {
  const _FieldMerger({
    required this.fieldName,
    required this.localValue,
    required this.serverValue,
    required this.currentValue,
    required this.onLocalSelected,
    required this.onServerSelected,
  });

  final String fieldName;
  final String localValue;
  final String serverValue;
  final String currentValue;
  final VoidCallback onLocalSelected;
  final VoidCallback onServerSelected;

  @override
  Widget build(BuildContext context) {
    final isLocalSelected = currentValue == localValue;
    final isServerSelected = currentValue == serverValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _SelectableValue(
                  label: 'Local',
                  value: localValue,
                  isSelected: isLocalSelected,
                  color: Colors.blue,
                  onTap: onLocalSelected,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SelectableValue(
                  label: 'Server',
                  value: serverValue,
                  isSelected: isServerSelected,
                  color: Colors.green,
                  onTap: onServerSelected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectableValue extends StatelessWidget {
  const _SelectableValue({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 16,
                  color: isSelected ? color : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? color : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
