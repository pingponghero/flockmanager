import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../database/database_helper.dart';
import '../../widgets/egg_quick_log.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flock Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.egg_outlined,
              size: 64,
              color: Color(0xFF8B4513),
            ),
            const SizedBox(height: 16),
            Text(
              'Home Screen',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            // Quick log button (prominent)
            FilledButton.icon(
              onPressed: () => showEggQuickLog(context),
              icon: const Icon(Icons.egg),
              label: const Text('Log Eggs'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push('/flocks'),
                  icon: const Icon(Icons.groups),
                  label: const Text('Flocks'),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/birds'),
                  icon: const Icon(Icons.flutter_dash),
                  label: const Text('Birds'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Temporary DB test button - remove after Task 1.3
            OutlinedButton.icon(
              onPressed: () => _testDatabase(context),
              icon: const Icon(Icons.storage),
              label: const Text('Test Database'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showEggQuickLog(context),
        icon: const Icon(Icons.egg),
        label: const Text('Log Eggs'),
      ),
    );
  }

  Future<void> _testDatabase(BuildContext context) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Insert a test flock
      const uuid = Uuid();
      final testId = uuid.v4();
      final now = DateTime.now().toIso8601String();

      await db.insert('flocks', {
        'id': testId,
        'name': 'Test Flock',
        'description': 'A test flock to verify DB works',
        'created_at': now,
      });

      // Read it back
      final result = await db.query(
        'flocks',
        where: 'id = ?',
        whereArgs: [testId],
      );

      // Delete the test data
      await db.delete(
        'flocks',
        where: 'id = ?',
        whereArgs: [testId],
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'DB Test Success! Read back: ${result.first['name']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DB Test Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
