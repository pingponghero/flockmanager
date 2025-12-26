import 'package:flutter/material.dart';

class FlockListScreen extends StatelessWidget {
  const FlockListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flocks'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.groups,
              size: 64,
              color: Color(0xFF8B4513),
            ),
            const SizedBox(height: 16),
            Text(
              'Flock List Screen',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Route: /flocks',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
