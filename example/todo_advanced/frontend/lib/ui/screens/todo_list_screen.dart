import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/todo.dart';
import '../../repositories/todo_repository.dart';
import '../../services/conflict_handler.dart';
import '../../services/sync_service.dart';
import '../widgets/conflict_dialog.dart';
import '../widgets/sync_status_indicator.dart';
import '../widgets/todo_card.dart';
import 'todo_edit_screen.dart';

/// Main screen showing list of todos.
class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TodoRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo Advanced'),
        actions: const [
          SyncStatusIndicator(),
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Todo list
          StreamBuilder<List<Todo>>(
            stream: repo.watchAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final todos = snapshot.data ?? [];

              if (todos.isEmpty) {
                return const _EmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return TodoCard(
                    todo: todo,
                    onToggle: () => _toggleTodo(context, repo, todo),
                    onTap: () => _editTodo(context, todo),
                    onDelete: () => _deleteTodo(context, repo, todo),
                  );
                },
              );
            },
          ),

          // Conflict listener
          Consumer<ConflictHandler>(
            builder: (context, handler, _) {
              if (handler.currentConflict != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showConflictDialog(context, handler.currentConflict!);
                });
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Simulation button
          FloatingActionButton.small(
            heroTag: 'simulate',
            onPressed: () => _showSimulationMenu(context),
            tooltip: 'Server simulation',
            child: const Icon(Icons.science),
          ),
          const SizedBox(height: 8),
          // Add button
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => _createTodo(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Todo'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTodo(
    BuildContext context,
    TodoRepository repo,
    Todo todo,
  ) async {
    await repo.toggleCompleted(todo);
  }

  Future<void> _createTodo(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const TodoEditScreen(),
      ),
    );
  }

  Future<void> _editTodo(BuildContext context, Todo todo) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TodoEditScreen(todo: todo),
      ),
    );
  }

  Future<void> _deleteTodo(
    BuildContext context,
    TodoRepository repo,
    Todo todo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await repo.delete(todo);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo deleted')),
        );
      }
    }
  }

  void _showConflictDialog(BuildContext context, ConflictInfo conflict) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConflictDialog(conflict: conflict),
    );
  }

  void _showSimulationMenu(BuildContext context) {
    final syncService = context.read<SyncService>();
    final repo = context.read<TodoRepository>();

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _SimulationMenu(
        syncService: syncService,
        repo: repo,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No todos yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first todo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _SimulationMenu extends StatelessWidget {
  const _SimulationMenu({
    required this.syncService,
    required this.repo,
  });

  final SyncService syncService;
  final TodoRepository repo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Server Simulation',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Trigger server-side changes to test conflict resolution:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Add Reminder'),
            subtitle: const Text('Server adds reminder text to a todo'),
            onTap: () => _addReminder(context),
          ),

          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Auto-Complete Overdue'),
            subtitle: const Text('Server marks overdue todos as completed'),
            onTap: () => _autoComplete(context),
          ),

          ListTile(
            leading: const Icon(Icons.priority_high),
            title: const Text('Change Priority'),
            subtitle: const Text('Server changes priority of a todo'),
            onTap: () => _changePriority(context),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _addReminder(BuildContext context) async {
    Navigator.pop(context);

    final todos = await repo.getAll();
    if (todos.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No todos to add reminder to')),
        );
      }
      return;
    }

    // Pick first non-completed todo
    final todo = todos.firstWhere(
      (t) => !t.completed,
      orElse: () => todos.first,
    );

    try {
      await syncService.triggerServerSimulation(
        '/simulate/reminder',
        {'id': todo.id, 'text': 'Server reminder: Please review this task!'},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder added to "${todo.title}". Sync to see conflict.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _autoComplete(BuildContext context) async {
    Navigator.pop(context);

    try {
      await syncService.triggerServerSimulation('/simulate/complete', {});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto-complete triggered. Sync to see changes.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changePriority(BuildContext context) async {
    Navigator.pop(context);

    final todos = await repo.getAll();
    if (todos.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No todos to change priority')),
        );
      }
      return;
    }

    // Pick first todo with priority > 1
    final todo = todos.firstWhere(
      (t) => t.priority > 1,
      orElse: () => todos.first,
    );

    final newPriority = todo.priority > 1 ? 1 : 5;

    try {
      await syncService.triggerServerSimulation(
        '/simulate/prioritize',
        {'id': todo.id, 'priority': newPriority},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Priority changed for "${todo.title}". Sync to see conflict.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
