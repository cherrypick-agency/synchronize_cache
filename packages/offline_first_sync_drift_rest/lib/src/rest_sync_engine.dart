import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:offline_first_sync_drift_rest/src/rest_transport.dart';

/// One-liner helper that creates [RestTransport] and [SyncEngine] together.
SyncEngine<DB> createRestSyncEngine<DB extends GeneratedDatabase>({
  required DB db,
  required Uri base,
  required AuthTokenProvider token,
  required List<SyncableTable<dynamic>> tables,
  SyncConfig config = const SyncConfig(),
  Map<String, TableConflictConfig>? tableConflictConfigs,
  http.Client? client,
  Duration backoffMin = const Duration(seconds: 1),
  Duration backoffMax = const Duration(minutes: 2),
  int maxRetries = 5,
  int pushConcurrency = 1,
  bool enableBatch = false,
  int batchSize = 100,
  String batchPath = 'batch',
}) {
  final transport = RestTransport(
    base: base,
    token: token,
    client: client,
    backoffMin: backoffMin,
    backoffMax: backoffMax,
    maxRetries: maxRetries,
    pushConcurrency: pushConcurrency,
    enableBatch: enableBatch,
    batchSize: batchSize,
    batchPath: batchPath,
  );

  return SyncEngine<DB>(
    db: db,
    transport: transport,
    tables: tables,
    config: config,
    tableConflictConfigs: tableConflictConfigs,
  );
}
