import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/flocks/flock_list_screen.dart';
import '../screens/flocks/flock_form_screen.dart';
import '../screens/birds/bird_list_screen.dart';
import '../screens/birds/bird_form_screen.dart';
import '../screens/birds/bird_detail_screen.dart';
import '../screens/eggs/egg_history_screen.dart';
import '../screens/eggs/egg_log_screen.dart';
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
      routes: [
        GoRoute(
          path: 'new',
          name: 'bird-new',
          builder: (context, state) => const BirdFormScreen(),
        ),
        GoRoute(
          path: ':id',
          name: 'bird-detail',
          builder: (context, state) {
            final birdId = state.pathParameters['id']!;
            return BirdDetailScreen(birdId: birdId);
          },
          routes: [
            GoRoute(
              path: 'edit',
              name: 'bird-edit',
              builder: (context, state) {
                final birdId = state.pathParameters['id']!;
                return BirdFormScreen(birdId: birdId);
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/eggs',
      name: 'eggs',
      builder: (context, state) => const EggHistoryScreen(),
      routes: [
        GoRoute(
          path: 'log',
          name: 'egg-log',
          builder: (context, state) {
            // Can receive DateTime or EggLog via extra
            return EggLogScreen(initialData: state.extra);
          },
        ),
      ],
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
