import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FlockManagerApp(),
    ),
  );
}

class FlockManagerApp extends ConsumerWidget {
  const FlockManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Flock Manager',
      theme: AppTheme.buildTheme(palette),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
