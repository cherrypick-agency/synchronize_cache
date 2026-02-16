import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/todo.dart';
import '../../repositories/todo_repository.dart';

class TodoEditScreen extends StatefulWidget {
  const TodoEditScreen({super.key, this.todo});

  final Todo? todo;

  @override
  State<TodoEditScreen> createState() => _TodoEditScreenState();
}

class _TodoEditScreenState extends State<TodoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late int _priority;
  late bool _completed;
  DateTime? _dueDate;
  bool _isSaving = false;

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _descriptionController = TextEditingController(text: widget.todo?.description ?? '');
    _priority = widget.todo?.priority ?? 3;
    _completed = widget.todo?.completed ?? false;
    _dueDate = widget.todo?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Todo' : 'New Todo'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter todo title',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.length > 500) {
                  return 'Title must be 500 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter description',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              maxLength: 2000,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            _PrioritySelector(
              value: _priority,
              onChanged: (value) => setState(() => _priority = value),
            ),
            const SizedBox(height: 16),
            _DueDatePicker(
              value: _dueDate,
              onChanged: (value) => setState(() => _dueDate = value),
            ),
            const SizedBox(height: 16),
            if (_isEditing)
              SwitchListTile(
                title: const Text('Completed'),
                value: _completed,
                onChanged: (value) => setState(() => _completed = value),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = context.read<TodoRepository>();
      if (_isEditing) {
        await repo.update(
          widget.todo!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
          completed: _completed,
        );
      } else {
        await repo.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1'), icon: Icon(Icons.flag)),
            ButtonSegment(value: 2, label: Text('2')),
            ButtonSegment(value: 3, label: Text('3')),
            ButtonSegment(value: 4, label: Text('4')),
            ButtonSegment(value: 5, label: Text('5')),
          ],
          selected: {value},
          onSelectionChanged: (selected) => onChanged(selected.first),
        ),
        const SizedBox(height: 4),
        Text(
          '1 = Highest priority, 5 = Lowest priority',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _DueDatePicker extends StatelessWidget {
  const _DueDatePicker({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Due Date (optional)', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(context),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  value != null ? '${value!.month}/${value!.day}/${value!.year}' : 'Select date',
                ),
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => onChanged(null),
                tooltip: 'Clear date',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? now,
        firstDate: now.subtract(const Duration(days: 365)),
        lastDate: now.add(const Duration(days: 365 * 5)),
      );
      if (picked != null && context.mounted) {
        onChanged(picked);
      }
    } catch (_) {}
  }
}
