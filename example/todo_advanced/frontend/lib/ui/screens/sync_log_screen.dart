import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/conflict_handler.dart';
import '../../services/sync_service.dart';

/// Screen showing sync event log.
class SyncLogScreen extends StatelessWidget {
  const SyncLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _clearLog(context),
            tooltip: 'Clear log',
          ),
        ],
      ),
      body: Consumer<ConflictHandler>(
        builder: (context, handler, _) {
          final log = handler.log;

          if (log.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: log.length,
            itemBuilder: (context, index) {
              // Reverse order to show newest first
              final entry = log[log.length - 1 - index];
              return _LogEntryCard(entry: entry);
            },
          );
        },
      ),
      floatingActionButton: Consumer<SyncService>(
        builder: (context, syncService, _) {
          return FloatingActionButton.extended(
            onPressed: syncService.isSyncing ? null : () => _sync(context, syncService),
            icon: syncService.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
            label: Text(syncService.isSyncing ? 'Syncing...' : 'Sync Now'),
          );
        },
      ),
    );
  }

  void _clearLog(BuildContext context) {
    final handler = context.read<ConflictHandler>();
    handler.clearLog();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log cleared')),
    );
  }

  Future<void> _sync(BuildContext context, SyncService syncService) async {
    try {
      final stats = await syncService.sync();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced: ${stats.pushed} pushed, ${stats.pulled} pulled',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            Icons.history,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No sync events yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Sync events will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  const _LogEntryCard({required this.entry});

  final SyncLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (entry.level) {
      SyncLogLevel.info => (Icons.info_outline, Colors.blue),
      SyncLogLevel.warning => (Icons.warning_amber, Colors.orange),
      SyncLogLevel.error => (Icons.error_outline, Colors.red),
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(entry.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
