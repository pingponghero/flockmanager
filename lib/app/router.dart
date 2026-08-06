import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../screens/home/home_screen.dart';
import '../screens/flocks/flock_list_screen.dart';
import '../screens/flocks/flock_form_screen.dart';
import '../screens/birds/bird_list_screen.dart';
import '../screens/birds/bird_form_screen.dart';
import '../screens/birds/bird_detail_screen.dart';
import '../screens/birds/bird_events_screen.dart';
import '../screens/birds/health_note_form_screen.dart';
import '../screens/eggs/egg_history_screen.dart';
import '../screens/eggs/egg_log_screen.dart';
import '../screens/value/value_screen.dart';
import '../screens/value/value_form_screen.dart';
import '../screens/medications/medication_screen.dart';
import '../screens/breeds/breed_list_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/achievements_screen.dart';
import '../screens/settings/recipients_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../widgets/scaffold_with_nav_bar.dart';

// Navigation keys for each branch
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _birdsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'birds');
final _analyticsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'analytics');
final _expensesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'expenses');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Onboarding - outside the shell
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final tourOnly = state.uri.queryParameters['tourOnly'] == 'true';
        return OnboardingScreen(tourOnly: tourOnly);
      },
    ),

    // Main app with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home (includes egg history)
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'eggs',
                  name: 'eggs',
                  builder: (context, state) => EggHistoryScreen(
                    initialDate: state.extra as DateTime?,
                  ),
                  routes: [
                    GoRoute(
                      path: 'log',
                      name: 'egg-log',
                      builder: (context, state) {
                        return EggLogScreen(initialData: state.extra);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Branch 1: Birds
        StatefulShellBranch(
          navigatorKey: _birdsNavigatorKey,
          routes: [
            GoRoute(
              path: '/birds',
              name: 'birds',
              builder: (context, state) => const BirdListScreen(),
              routes: [
                GoRoute(
                  path: 'events',
                  name: 'bird-events',
                  builder: (context, state) => const BirdEventsScreen(),
                ),
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
                        final openPhoto = state.uri.queryParameters['openPhoto'] == 'true';
                        return BirdFormScreen(birdId: birdId, openPhoto: openPhoto);
                      },
                    ),
                    GoRoute(
                      path: 'health/new',
                      name: 'health-note-new',
                      builder: (context, state) {
                        final birdId = state.pathParameters['id']!;
                        return HealthNoteFormScreen(birdId: birdId);
                      },
                    ),
                    GoRoute(
                      path: 'health/:noteId',
                      name: 'health-note-edit',
                      builder: (context, state) {
                        final birdId = state.pathParameters['id']!;
                        final noteId = state.pathParameters['noteId']!;
                        return HealthNoteFormScreen(birdId: birdId, noteId: noteId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Branch 2: Analytics
        StatefulShellBranch(
          navigatorKey: _analyticsNavigatorKey,
          routes: [
            GoRoute(
              path: '/analytics',
              name: 'analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),

        // Branch 3: Expenses
        StatefulShellBranch(
          navigatorKey: _expensesNavigatorKey,
          routes: [
            GoRoute(
              path: '/expenses',
              name: 'expenses',
              builder: (context, state) => const ValueScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  name: 'expense-new',
                  builder: (context, state) => const ExpenseFormScreen(),
                ),
                GoRoute(
                  path: 'income/new',
                  name: 'income-new',
                  builder: (context, state) => const IncomeFormScreen(),
                ),
                GoRoute(
                  path: 'gift/new',
                  name: 'gift-new',
                  builder: (context, state) =>
                      const IncomeFormScreen(initialType: IncomeType.gift),
                ),
                GoRoute(
                  path: 'income/:id',
                  name: 'income-edit',
                  builder: (context, state) {
                    final incomeId = state.pathParameters['id']!;
                    return IncomeFormScreen(incomeId: incomeId);
                  },
                ),
                GoRoute(
                  path: ':id',
                  name: 'expense-edit',
                  builder: (context, state) {
                    final expenseId = state.pathParameters['id']!;
                    return ExpenseFormScreen(expenseId: expenseId);
                  },
                ),
              ],
            ),
          ],
        ),

        // Branch 4: Settings
        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'flocks',
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
                  path: 'achievements',
                  name: 'achievements',
                  builder: (context, state) => const AchievementsScreen(),
                ),
                GoRoute(
                  path: 'recipients',
                  name: 'recipients',
                  builder: (context, state) => const RecipientsScreen(),
                ),
                GoRoute(
                  path: 'breeds',
                  name: 'breeds',
                  builder: (context, state) => const BreedListScreen(),
                ),
                GoRoute(
                  path: 'medications',
                  name: 'medications',
                  builder: (context, state) => const MedicationScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Text('Page not found: ${state.uri.path}'),
    ),
  ),
);
