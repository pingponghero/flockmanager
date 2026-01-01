import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/flock.dart';
import '../../models/bird.dart';
import '../../models/enums.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/flock_provider.dart';
import '../../providers/bird_provider.dart';
import '../../providers/achievements_provider.dart';
import '../../widgets/achievement_celebration_dialog.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  /// If true, only shows the tour portion (for "Show app tour" in settings).
  final bool tourOnly;

  const OnboardingScreen({super.key, this.tourOnly = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  final _featurePageController = PageController();

  // Form controllers
  final _flockNameController = TextEditingController(text: 'My Flock');
  final _birdNameController = TextEditingController();

  int _currentFeaturePage = 0;
  String _selectedFlockIcon = 'cute_hen';
  String _selectedFlockColor = '4CAF50';
  String? _selectedBreed;
  bool _isCreatingFlock = false;
  bool _isCreatingBird = false;

  @override
  void initState() {
    super.initState();
    // Initialize page controller based on provider's current step
    final onboarding = ref.read(onboardingProvider);
    final initialPage = widget.tourOnly ? 4 : _stepToPage(onboarding.currentStep);
    _pageController = PageController(initialPage: initialPage);
  }

  int _stepToPage(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return 0;
      case OnboardingStep.features:
        return 1;
      case OnboardingStep.createFlock:
        return 2;
      case OnboardingStep.addBird:
        return 3;
      case OnboardingStep.tour:
      case OnboardingStep.completed:
        return 4;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _featurePageController.dispose();
    _flockNameController.dispose();
    _birdNameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage < 4) {
      // Update provider state
      ref.read(onboardingProvider.notifier).nextStep();
      // Animate to next page
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createFlock() async {
    if (_flockNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a flock name')),
      );
      return;
    }

    setState(() => _isCreatingFlock = true);

    try {
      final flock = Flock.create(
        name: _flockNameController.text.trim(),
        icon: _selectedFlockIcon,
        color: _selectedFlockColor,
      );

      await ref.read(flocksProvider.notifier).addFlock(flock);
      await ref.read(onboardingProvider.notifier).setCreatedFlockId(flock.id);

      setState(() => _isCreatingFlock = false);

      HapticFeedback.mediumImpact();
      _nextPage();
    } catch (e) {
      setState(() => _isCreatingFlock = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating flock: $e')),
        );
      }
    }
  }

  Future<void> _createBird() async {
    if (_birdNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bird name')),
      );
      return;
    }

    final createdFlockId = ref.read(onboardingProvider).createdFlockId;
    if (createdFlockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No flock created yet')),
      );
      return;
    }

    setState(() => _isCreatingBird = true);

    try {
      final bird = Bird.create(
        flockId: createdFlockId,
        name: _birdNameController.text.trim(),
        breed: _selectedBreed,
        sex: BirdSex.female,
        species: BirdSpecies.chicken,
      );

      await ref.read(birdsProvider.notifier).addBird(bird);

      setState(() => _isCreatingBird = false);

      HapticFeedback.mediumImpact();
      _nextPage();
    } catch (e) {
      setState(() => _isCreatingBird = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding bird: $e')),
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();

    // Check for achievements
    if (mounted) {
      final newAchievements = await checkAndCelebrateAchievements(ref, context);
      if (mounted && newAchievements.isNotEmpty) {
        await AchievementCelebrationDialog.showMultiple(context, newAchievements);
      }
    }

    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _skipOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip setup?'),
        content: const Text(
          'You can always create flocks and birds later from the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(onboardingProvider.notifier).skipOnboarding();
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProvider);
    final currentPage = _stepToPage(onboarding.currentStep);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top right, except on tour page)
            if (currentPage < 4)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text('Skip'),
                  ),
                ),
              )
            else
              const SizedBox(height: 48),

            // Main content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(onGetStarted: _nextPage),
                  _FeaturesPage(
                    pageController: _featurePageController,
                    currentPage: _currentFeaturePage,
                    onPageChanged: (page) => setState(() => _currentFeaturePage = page),
                    onNext: _nextPage,
                  ),
                  _CreateFlockPage(
                    nameController: _flockNameController,
                    selectedIcon: _selectedFlockIcon,
                    selectedColor: _selectedFlockColor,
                    onIconChanged: (icon) => setState(() => _selectedFlockIcon = icon),
                    onColorChanged: (color) => setState(() => _selectedFlockColor = color),
                    isLoading: _isCreatingFlock,
                    onCreateFlock: _createFlock,
                  ),
                  _AddBirdPage(
                    nameController: _birdNameController,
                    selectedBreed: _selectedBreed,
                    onBreedChanged: (breed) => setState(() => _selectedBreed = breed),
                    isLoading: _isCreatingBird,
                    onAddBird: _createBird,
                    onSkip: _nextPage,
                  ),
                  _TourPage(onComplete: _completeOnboarding),
                ],
              ),
            ),

            // Page indicator
            if (currentPage < 4)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WELCOME PAGE
// ============================================================================

class _WelcomePage extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _WelcomePage({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero illustration
          Image.asset(
            'assets/icons/cute_hen.png',
            width: 120,
            height: 120,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),

          Text(
            'Welcome to\nFlock Manager',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Track your flock the simple way',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          FilledButton.icon(
            onPressed: onGetStarted,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Get Started'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FEATURES PAGE
// ============================================================================

class _FeaturesPage extends StatelessWidget {
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onNext;

  const _FeaturesPage({
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureCard(
        icon: Icons.egg,
        title: 'Log eggs in 2 taps',
        description: 'Quick-log from the home screen. Track by flock, bird, size, and quality.',
        color: Colors.amber,
      ),
      _FeatureCard(
        icon: Icons.pets,
        title: 'Track every bird',
        description: 'Bird profiles with photos, breeds, health notes, and egg production stats.',
        color: Colors.green,
      ),
      _FeatureCard(
        icon: Icons.attach_money,
        title: 'Know your costs',
        description: 'Track expenses and income. See your cost per egg and profit/loss.',
        color: Colors.blue,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),

          SizedBox(
            height: 320,
            child: PageView.builder(
              controller: pageController,
              onPageChanged: onPageChanged,
              itemCount: features.length,
              itemBuilder: (context, index) => features[index],
            ),
          ),

          const SizedBox(height: 24),

          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(features.length, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == currentPage
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              );
            }),
          ),

          const Spacer(),

          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(currentPage == features.length - 1 ? 'Continue' : 'Next'),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CREATE FLOCK PAGE
// ============================================================================

class _CreateFlockPage extends StatelessWidget {
  final TextEditingController nameController;
  final String selectedIcon;
  final String selectedColor;
  final ValueChanged<String> onIconChanged;
  final ValueChanged<String> onColorChanged;
  final bool isLoading;
  final VoidCallback onCreateFlock;

  const _CreateFlockPage({
    required this.nameController,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconChanged,
    required this.onColorChanged,
    required this.isLoading,
    required this.onCreateFlock,
  });

  static const _icons = ['cute_hen', 'egg', 'home', 'grass', 'park', 'eco'];
  static const _colors = [
    '4CAF50', // Green
    '2196F3', // Blue
    'FF9800', // Orange
    'E91E63', // Pink
    '9C27B0', // Purple
    '795548', // Brown
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          Text(
            "Let's set up your first flock",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'You can always add more flocks later',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Name field
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Flock Name',
              hintText: 'e.g., Backyard Flock',
              prefixIcon: Icon(Icons.edit),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: 24),

          // Icon picker
          Text(
            'Choose an icon',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _icons.map((iconName) {
              final isSelected = iconName == selectedIcon;
              return GestureDetector(
                onTap: () => onIconChanged(iconName),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(child: _buildIcon(context, iconName)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Color picker
          Text(
            'Choose a color',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colors.map((colorHex) {
              final isSelected = colorHex == selectedColor;
              final color = Color(int.parse('FF$colorHex', radix: 16));
              return GestureDetector(
                onTap: () => onColorChanged(colorHex),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),

          FilledButton(
            onPressed: isLoading ? null : onCreateFlock,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Flock'),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context, String iconName) {
    if (iconName == 'cute_hen') {
      return Image.asset(
        'assets/icons/cute_hen.png',
        width: 24,
        height: 24,
        color: Theme.of(context).colorScheme.onSurface,
      );
    }

    final iconMap = {
      'egg': Icons.egg,
      'home': Icons.home,
      'grass': Icons.grass,
      'park': Icons.park,
      'eco': Icons.eco,
    };

    return Icon(
      iconMap[iconName] ?? Icons.egg,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}

// ============================================================================
// ADD BIRD PAGE
// ============================================================================

class _AddBirdPage extends StatelessWidget {
  final TextEditingController nameController;
  final String? selectedBreed;
  final ValueChanged<String?> onBreedChanged;
  final bool isLoading;
  final VoidCallback onAddBird;
  final VoidCallback onSkip;

  const _AddBirdPage({
    required this.nameController,
    required this.selectedBreed,
    required this.onBreedChanged,
    required this.isLoading,
    required this.onAddBird,
    required this.onSkip,
  });

  static const _popularBreeds = [
    'Rhode Island Red',
    'Leghorn',
    'Plymouth Rock',
    'Orpington',
    'Australorp',
    'Wyandotte',
    'Sussex',
    'Easter Egger',
    'Silkie',
    'Brahma',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          Text(
            'Want to add your first bird?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'You can add more birds anytime from the Birds tab',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Name field
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Bird Name',
              hintText: 'e.g., Henrietta',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Breed dropdown
          DropdownButtonFormField<String?>(
            initialValue: selectedBreed,
            decoration: const InputDecoration(
              labelText: 'Breed (optional)',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Not specified'),
              ),
              ..._popularBreeds.map((breed) => DropdownMenuItem(
                value: breed,
                child: Text(breed),
              )),
            ],
            onChanged: onBreedChanged,
          ),
          const SizedBox(height: 48),

          FilledButton(
            onPressed: isLoading ? null : onAddBird,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add Bird'),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: onSkip,
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TOUR PAGE
// ============================================================================

class _TourPage extends StatelessWidget {
  final VoidCallback onComplete;

  const _TourPage({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),

          Text(
            "You're all set!",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Here are a few tips to get started',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Tips
          _TipCard(
            icon: Icons.add_circle,
            tip: 'Tap the + button on the home screen to quickly log eggs',
          ),
          const SizedBox(height: 12),
          _TipCard(
            icon: Icons.medical_services,
            tip: 'Track medications and get notified when withdrawal periods end',
          ),
          const SizedBox(height: 12),
          _TipCard(
            icon: Icons.emoji_events,
            tip: 'Earn achievements as you track your flock!',
          ),
          const SizedBox(height: 48),

          FilledButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.check),
            label: const Text('Start Using App'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String tip;

  const _TipCard({required this.icon, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
