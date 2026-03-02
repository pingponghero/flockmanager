import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/flock.dart';
import '../../models/bird.dart';
import '../../models/enums.dart';
import '../../data/breeds.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/flock_provider.dart';
import '../../providers/bird_provider.dart';
import '../../providers/achievements_provider.dart';
import '../../utils/snackbar_utils.dart';
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
  final _flockNameController = TextEditingController(text: 'The Girls');
  final _birdNameController = TextEditingController();
  final _breedController = TextEditingController();

  String _selectedFlockIcon = 'cute_hen';
  String _selectedFlockColor = '4CAF50';
  String? _selectedBreedId;
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
    _breedController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage < 4) {
      // Update provider state first (await to ensure state is saved)
      await ref.read(onboardingProvider.notifier).nextStep();
      // Then animate to next page
      if (mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _createFlock() async {
    if (_flockNameController.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please enter a flock name');
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
      await _nextPage();
    } catch (e) {
      setState(() => _isCreatingFlock = false);
      if (mounted) {
        showAppSnackBar(context, 'Error creating flock: $e');
      }
    }
  }

  Future<void> _createBird() async {
    if (_birdNameController.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please enter a bird name');
      return;
    }

    final createdFlockId = ref.read(onboardingProvider).createdFlockId;
    if (createdFlockId == null) {
      showAppSnackBar(context, 'No flock created yet');
      return;
    }

    setState(() => _isCreatingBird = true);

    try {
      final bird = Bird.create(
        flockId: createdFlockId,
        name: _birdNameController.text.trim(),
        breed: _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
        breedId: _selectedBreedId,
        sex: BirdSex.female,
        species: BirdSpecies.chicken,
      );

      await ref.read(birdsProvider.notifier).addBird(bird);

      setState(() => _isCreatingBird = false);

      HapticFeedback.mediumImpact();
      await _nextPage();
    } catch (e) {
      setState(() => _isCreatingBird = false);
      if (mounted) {
        showAppSnackBar(context, 'Error adding bird: $e');
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
        await markAchievementsAsShown(newAchievements);
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

    // Sync PageController with provider state if they're out of sync
    // This handles cases where the widget is recreated or state is restored
    if (_pageController.hasClients && !onboarding.isLoading) {
      final actualPage = _pageController.page?.round() ?? 0;
      if (actualPage != currentPage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(currentPage);
          }
        });
      }
    }

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
                    breedController: _breedController,
                    onBreedSelected: (breed) => setState(() => _selectedBreedId = breed?.id),
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

class _WelcomePage extends StatefulWidget {
  final VoidCallback onGetStarted;

  const _WelcomePage({required this.onGetStarted});

  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Gentle floating animation for the hen
    _floatAnimation = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    // Start floating animation (loops)
    _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hero illustration with float animation
              Transform.translate(
                offset: Offset(0, -_floatAnimation.value),
                child: Image.asset(
                  'assets/icons/cute_hen.png',
                  width: 120,
                  height: 120,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                onPressed: widget.onGetStarted,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Get Started'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// FEATURES PAGE
// ============================================================================

class _FeaturesPage extends StatelessWidget {
  final PageController pageController;
  final VoidCallback onNext;

  const _FeaturesPage({
    required this.pageController,
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
              itemCount: features.length,
              itemBuilder: (context, index) => features[index],
            ),
          ),

          const Spacer(),

          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Continue'),
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

  static const _icons = ['cute_hen', 'egg', 'home', 'grass', 'eco'];
  static const _colors = [
    '4CAF50', // Green
    '2196F3', // Blue
    'FF9800', // Orange
    'E91E63', // Pink
    '9C27B0', // Purple
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
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
          const SizedBox(height: 32),

          // Preview
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(int.parse('FF$selectedColor', radix: 16)).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(int.parse('FF$selectedColor', radix: 16)),
                  width: 2,
                ),
              ),
              child: Center(
                child: _buildPreviewIcon(context, selectedIcon, selectedColor),
              ),
            ),
          ),
          const SizedBox(height: 32),

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

  Widget _buildPreviewIcon(BuildContext context, String iconName, String colorHex) {
    final color = Color(int.parse('FF$colorHex', radix: 16));
    if (iconName == 'cute_hen') {
      return Image.asset(
        'assets/icons/cute_hen.png',
        width: 40,
        height: 40,
        color: color,
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
      color: color,
      size: 40,
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
  final TextEditingController breedController;
  final ValueChanged<Breed?> onBreedSelected;
  final bool isLoading;
  final VoidCallback onAddBird;
  final VoidCallback onSkip;

  const _AddBirdPage({
    required this.nameController,
    required this.breedController,
    required this.onBreedSelected,
    required this.isLoading,
    required this.onAddBird,
    required this.onSkip,
  });

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

          // Breed autocomplete
          Autocomplete<Breed>(
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Breed>.empty();
              }
              return searchBreeds(textEditingValue.text).take(5);
            },
            displayStringForOption: (breed) => breed.name,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              // Sync with external controller
              if (controller.text != breedController.text) {
                controller.text = breedController.text;
              }
              controller.addListener(() {
                if (breedController.text != controller.text) {
                  breedController.text = controller.text;
                }
              });
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Breed (optional)',
                  hintText: 'Search or type breed name',
                ),
                textCapitalization: TextCapitalization.words,
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final breed = options.elementAt(index);
                        return ListTile(
                          title: Text(breed.name),
                          subtitle: Text(
                            '${breed.eggColorDisplay} eggs • ${breed.eggsPerYearAvg}/yr',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () => onSelected(breed),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (breed) {
              breedController.text = breed.name;
              onBreedSelected(breed);
            },
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
            icon: Icons.egg,
            tip: 'Tap the egg button on the home screen to quickly log eggs',
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
            label: const Text('Let\'s Go!'),
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
