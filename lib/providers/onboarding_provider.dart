import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State for onboarding flow.
enum OnboardingStep {
  welcome,
  features,
  createFlock,
  addBird,
  tour,
  completed,
}

/// State class for onboarding.
class OnboardingState {
  final bool isCompleted;
  final bool isLoading;
  final OnboardingStep currentStep;
  final String? createdFlockId;

  const OnboardingState({
    this.isCompleted = false,
    this.isLoading = true,
    this.currentStep = OnboardingStep.welcome,
    this.createdFlockId,
  });

  OnboardingState copyWith({
    bool? isCompleted,
    bool? isLoading,
    OnboardingStep? currentStep,
    String? createdFlockId,
  }) {
    return OnboardingState(
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      currentStep: currentStep ?? this.currentStep,
      createdFlockId: createdFlockId ?? this.createdFlockId,
    );
  }
}

/// Notifier for managing onboarding state.
class OnboardingNotifier extends Notifier<OnboardingState> {
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyOnboardingCompletedAt = 'onboarding_completed_at';
  static const String _keyOnboardingStep = 'onboarding_current_step';
  static const String _keyOnboardingFlockId = 'onboarding_flock_id';

  @override
  OnboardingState build() {
    _initialize();
    return const OnboardingState();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final isCompleted = prefs.getBool(_keyOnboardingCompleted) ?? false;

    if (isCompleted) {
      state = state.copyWith(
        isCompleted: true,
        isLoading: false,
        currentStep: OnboardingStep.completed,
      );
      return;
    }

    // Resume from saved step if app was closed mid-onboarding
    final savedStepIndex = prefs.getInt(_keyOnboardingStep);
    final savedFlockId = prefs.getString(_keyOnboardingFlockId);

    OnboardingStep step = OnboardingStep.welcome;
    if (savedStepIndex != null && savedStepIndex < OnboardingStep.values.length) {
      step = OnboardingStep.values[savedStepIndex];
    }

    state = state.copyWith(
      isCompleted: false,
      isLoading: false,
      currentStep: step,
      createdFlockId: savedFlockId,
    );
  }

  /// Move to the next step.
  Future<void> nextStep() async {
    final currentIndex = state.currentStep.index;
    if (currentIndex < OnboardingStep.completed.index) {
      final nextStep = OnboardingStep.values[currentIndex + 1];
      await _saveStep(nextStep);
      state = state.copyWith(currentStep: nextStep);
    }
  }

  /// Go to a specific step.
  Future<void> goToStep(OnboardingStep step) async {
    await _saveStep(step);
    state = state.copyWith(currentStep: step);
  }

  /// Save the flock ID created during onboarding.
  Future<void> setCreatedFlockId(String flockId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOnboardingFlockId, flockId);
    state = state.copyWith(createdFlockId: flockId);
  }

  /// Save current step for resume capability.
  Future<void> _saveStep(OnboardingStep step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyOnboardingStep, step.index);
  }

  /// Mark onboarding as complete.
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);
    await prefs.setString(_keyOnboardingCompletedAt, DateTime.now().toIso8601String());
    // Clean up temp keys
    await prefs.remove(_keyOnboardingStep);
    await prefs.remove(_keyOnboardingFlockId);

    state = state.copyWith(
      isCompleted: true,
      currentStep: OnboardingStep.completed,
    );
  }

  /// Skip onboarding entirely (for users who want to explore).
  Future<void> skipOnboarding() async {
    await completeOnboarding();
  }

  /// Reset onboarding (for "Show app tour" in settings).
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboardingCompleted);
    await prefs.remove(_keyOnboardingCompletedAt);
    await prefs.remove(_keyOnboardingStep);
    await prefs.remove(_keyOnboardingFlockId);

    state = const OnboardingState(
      isCompleted: false,
      isLoading: false,
      currentStep: OnboardingStep.welcome,
    );
  }

  /// Show just the tour portion (from settings).
  Future<void> showTourOnly() async {
    state = state.copyWith(
      isCompleted: false,
      currentStep: OnboardingStep.tour,
    );
  }
}

/// Provider for onboarding state.
final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(() {
  return OnboardingNotifier();
});

/// Convenience provider for checking if onboarding is needed.
final needsOnboardingProvider = Provider<bool>((ref) {
  final onboarding = ref.watch(onboardingProvider);
  return !onboarding.isLoading && !onboarding.isCompleted;
});
