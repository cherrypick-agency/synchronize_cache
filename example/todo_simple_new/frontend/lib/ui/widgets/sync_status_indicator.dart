import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/sync_service.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        return StreamBuilder<int>(
          stream: syncService.pendingCountStream,
          initialData: 0,
          builder: (context, pendingSnapshot) {
            final pending = pendingSnapshot.data ?? 0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusBadge(status: syncService.status, pending: pending),
                const SizedBox(width: 8),
                if (syncService.isSyncing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: () => _sync(context, syncService),
                    tooltip: pending > 0 ? 'Sync now ($pending pending)' : 'Sync now',
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sync(BuildContext context, SyncService syncService) async {
    try {
      final stats = await syncService.sync();
      final stuck = syncService.lastRun?.stuckOpsCount ?? 0;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced: ${stats.pushed} pushed, ${stats.pulled} pulled, stuck: $stuck',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.pending});

  final SyncStatus status;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      SyncStatus.idle => (Colors.green, 'Online', Icons.cloud_done),
      SyncStatus.syncing => (Colors.blue, 'Syncing', Icons.sync),
      SyncStatus.error => (Colors.red, 'Error', Icons.cloud_off),
    };

    final text = pending > 0 ? '$label ($pending)' : label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
