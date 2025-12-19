import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/database.dart';
import 'repositories/todo_repository.dart';
import 'services/conflict_handler.dart';
import 'services/sync_service.dart';
import 'ui/screens/todo_list_screen.dart';

/// Backend server URL.
///
/// Change this to your actual backend URL.
/// Default: localhost:8080 for dart_frog dev server.
const kBackendUrl = 'http://localhost:8080';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open database
  final db = AppDatabase.open();

  // Create services
  final todoRepo = TodoRepository(db);
  final conflictHandler = ConflictHandler();
  final syncService = SyncService(
    db: db,
    baseUrl: kBackendUrl,
    conflictHandler: conflictHandler,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<TodoRepository>.value(value: todoRepo),
        ChangeNotifierProvider<ConflictHandler>.value(value: conflictHandler),
        ChangeNotifierProvider<SyncService>.value(value: syncService),
      ],
      child: const TodoAdvancedApp(),
    ),
  );
}

/// Todo Advanced application with conflict resolution.
class TodoAdvancedApp extends StatelessWidget {
  const TodoAdvancedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo Advanced',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const TodoListScreen(),
    );
  }
}
