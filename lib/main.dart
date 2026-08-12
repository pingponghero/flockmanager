import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'providers/notification_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/review_prompt_provider.dart';
import 'providers/theme_provider.dart';
import 'services/iap_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable edge-to-edge mode for modern Android
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Initialize services - each plugin is a guest, not a gatekeeper
  await _initServices();

  runApp(
    const ProviderScope(
      child: FlockManagerApp(),
    ),
  );
}

/// Initialize all services with graceful error handling.
/// App launches with degraded features if any service fails.
Future<void> _initServices() async {
  try {
    await NotificationService().initialize();
    NotificationService.onEggReminderTapped = () {
      router.go('/');
    };
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  try {
    await IAPService().initialize();
  } catch (e) {
    debugPrint('IAP init failed: $e');
  }
}

class FlockManagerApp extends ConsumerStatefulWidget {
  const FlockManagerApp({super.key});

  @override
  ConsumerState<FlockManagerApp> createState() => _FlockManagerAppState();
}

class _FlockManagerAppState extends ConsumerState<FlockManagerApp> {
  bool _hasCheckedOnboarding = false;
  bool _hasEvaluatedEggReminder = false;
  bool _hasRecordedAppOpen = false;

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

    // Evaluate egg reminder on app open (once per session)
    if (!_hasEvaluatedEggReminder && _hasCheckedOnboarding) {
      _hasEvaluatedEggReminder = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationSettingsProvider.notifier).evaluateEggReminder();
      });
    }

    // Count this open toward review-prompt eligibility (once per session)
    if (!_hasRecordedAppOpen) {
      _hasRecordedAppOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(reviewPromptProvider.notifier).recordAppOpen();
      });
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
