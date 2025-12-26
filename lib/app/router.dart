import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/flocks/flock_list_screen.dart';
import '../screens/flocks/flock_form_screen.dart';
import '../screens/birds/bird_list_screen.dart';
import '../screens/settings/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/flocks',
      name: 'flocks',
      builder: (context, state) => const FlockListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'flock-new',
          builder: (context, state) => const FlockFormScreen(),
        ),
        GoRoute(
          path: ':id',
          name: 'flock-detail',
          builder: (context, state) {
            final flockId = state.pathParameters['id']!;
            return FlockFormScreen(flockId: flockId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/birds',
      name: 'birds',
      builder: (context, state) => const BirdListScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Text('Page not found: ${state.uri.path}'),
    ),
  ),
);
