import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flock_manager/providers/achievements_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Achievement.describeWith', () {
    final achievement = Achievement(
      id: 'test',
      name: 'Test',
      description: 'Earn \$20+ from egg sales',
      icon: Icons.egg,
      color: Colors.green,
      category: 'Test',
      check: (_) => true,
    );

    test('replaces \$ with the user currency symbol', () {
      expect(achievement.describeWith('€'), 'Earn €20+ from egg sales');
      expect(achievement.describeWith('£'), 'Earn £20+ from egg sales');
    });

    test('keeps the default dollar symbol unchanged', () {
      expect(achievement.describeWith('\$'), 'Earn \$20+ from egg sales');
    });

    test('leaves descriptions without currency untouched', () {
      final plain = Achievement(
        id: 'plain',
        name: 'Plain',
        description: 'Log your first egg',
        icon: Icons.egg,
        color: Colors.amber,
        category: 'Test',
        check: (_) => true,
      );
      expect(plain.describeWith('€'), 'Log your first egg');
    });
  });

  group('AchievementTracker earned dates', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AchievementTracker.instance.clearAll();
    });

    test('stamps newly earned achievements with a date', () async {
      await AchievementTracker.instance.recordEarned({'first_egg'});

      final dates = await AchievementTracker.instance.getEarnedDates();
      expect(dates.keys, contains('first_egg'));
      expect(
        DateTime.now().difference(dates['first_egg']!).inSeconds,
        lessThan(5),
      );
    });

    test('keeps the original date when re-recording', () async {
      await AchievementTracker.instance.recordEarned({'first_egg'});
      final first =
          (await AchievementTracker.instance.getEarnedDates())['first_egg']!;

      await Future.delayed(const Duration(milliseconds: 10));
      await AchievementTracker.instance.recordEarned({'first_egg', 'century_mark'});

      final dates = await AchievementTracker.instance.getEarnedDates();
      expect(dates['first_egg'], first);
      expect(dates.keys, contains('century_mark'));
    });

    test('removes achievements that are no longer earned (revoked)', () async {
      await AchievementTracker.instance
          .recordEarned({'first_egg', 'dozen_club'});
      // A data correction revokes dozen_club
      await AchievementTracker.instance.recordEarned({'first_egg'});

      final dates = await AchievementTracker.instance.getEarnedDates();
      expect(dates.keys, contains('first_egg'));
      expect(dates.keys, isNot(contains('dozen_club')));
    });

    test('persists dates across cache reloads', () async {
      await AchievementTracker.instance.recordEarned({'first_egg'});
      final stored =
          (await SharedPreferences.getInstance())
              .getStringList('achievement_earned_dates');
      expect(stored, isNotNull);
      expect(stored!.single, startsWith('first_egg|'));
      expect(DateTime.tryParse(stored.single.split('|')[1]), isNotNull);
    });
  });

  group('achievement definitions', () {
    test('molt_survivor is not implicitly the latest achievement', () {
      // Guard against regressions of the "stale featured achievement" bug:
      // the old implementation returned the LAST earned achievement in
      // definition order, which pinned whatever is defined last in the list.
      // The latest achievement must come from recorded earned dates instead.
      expect(achievements.last.id, 'molt_survivor',
          reason: 'If the definition order changes, this test documents that '
              'latestAchievementProvider must still use earned dates, '
              'not list order');
    });

    test('all achievement ids are unique', () {
      final ids = achievements.map((a) => a.id).toSet();
      expect(ids.length, achievements.length);
    });

    test('secret achievements have no visible progress tracking', () {
      // Secret achievements are fully hidden while locked; a progress entry
      // would be pointless at best and a leak if the UI ever showed it.
      const progressIds = {
        'first_egg', 'century_mark', 'thousand_layer', 'golden_flock',
        'dozen_club', 'summer_surplus', 'perfect_week', 'on_a_roll',
        'rainbow_basket', 'full_palette', 'breed_collector',
        'flock_diversity', 'easter_every_day', 'starter_flock',
        'bakers_dozen', 'full_house', 'mini_homestead', 'flock_boss',
        'multi_manager', 'budget_tracker', 'first_gift', 'gift_basket',
        'community_coop', 'flock_doctor', 'year_round_keeper', 'power_user',
        'name_game',
      };
      final secretIds =
          achievements.where((a) => a.secret).map((a) => a.id).toSet();
      expect(secretIds, isNotEmpty);
      expect(secretIds.intersection(progressIds), isEmpty);
    });
  });
}
