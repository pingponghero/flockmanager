import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'services/iap_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge mode for modern Android
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Initialize services
  await NotificationService().initialize();
  await IAPService().initialize();

  runApp(
    const ProviderScope(
      child: FlockManagerApp(),
    ),
  );
}

class FlockManagerApp extends ConsumerStatefulWidget {
  const FlockManagerApp({super.key});

  @override
  ConsumerState<FlockManagerApp> createState() => _FlockManagerAppState();
}

class _FlockManagerAppState extends ConsumerState<FlockManagerApp> {
  bool _hasCheckedOnboarding = false;

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(themeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final onboarding = ref.watch(onboardingProvider);

    // Check if we need to redirect to onboarding on first app load
    if (!_hasCheckedOnboarding && !onboarding.isLoading) {
      _hasCheckedOnboarding = true;
      if (!onboarding.isCompleted) {
        // Schedule navigation after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          router.go('/onboarding');
        });
      }
    }

    return MaterialApp.router(
      title: 'Flock Manager',
      theme: AppTheme.buildTheme(palette, brightness: Brightness.light),
      darkTheme: AppTheme.buildTheme(palette, brightness: Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Show loading while checking onboarding state on first load
        if (onboarding.isLoading && !_hasCheckedOnboarding) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
