import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/utils/edge_insets.dart';

void main() {
  group('EdgeInsetsX', () {
    testWidgets('withSystemNavigation adds bottom padding from MediaQuery',
        (tester) async {
      late EdgeInsets result;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            viewPadding: EdgeInsets.only(bottom: 34),
          ),
          child: Builder(
            builder: (context) {
              result = const EdgeInsets.all(16).withSystemNavigation(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result.left, 16);
      expect(result.top, 16);
      expect(result.right, 16);
      expect(result.bottom, 50); // 16 + 34
    });

    testWidgets('withSystemNavigation preserves existing bottom padding',
        (tester) async {
      late EdgeInsets result;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            viewPadding: EdgeInsets.only(bottom: 20),
          ),
          child: Builder(
            builder: (context) {
              result = const EdgeInsets.only(bottom: 80)
                  .withSystemNavigation(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result.left, 0);
      expect(result.top, 0);
      expect(result.right, 0);
      expect(result.bottom, 100); // 80 + 20
    });

    testWidgets('withSystemNavigation handles zero system padding',
        (tester) async {
      late EdgeInsets result;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            viewPadding: EdgeInsets.zero,
          ),
          child: Builder(
            builder: (context) {
              result = const EdgeInsets.all(16).withSystemNavigation(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, const EdgeInsets.all(16));
    });

    testWidgets(
        'withSystemNavigation preserves horizontal padding with only bottom nav',
        (tester) async {
      late EdgeInsets result;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            viewPadding: EdgeInsets.only(bottom: 24),
          ),
          child: Builder(
            builder: (context) {
              result = const EdgeInsets.symmetric(horizontal: 16)
                  .withSystemNavigation(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result.left, 16);
      expect(result.top, 0);
      expect(result.right, 16);
      expect(result.bottom, 24);
    });
  });

  group('pagePadding', () {
    testWidgets('returns EdgeInsets.all(16) plus system navigation',
        (tester) async {
      late EdgeInsets result;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            viewPadding: EdgeInsets.only(bottom: 34),
          ),
          child: Builder(
            builder: (context) {
              result = pagePadding(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result.left, 16);
      expect(result.top, 16);
      expect(result.right, 16);
      expect(result.bottom, 50); // 16 + 34
    });

    testWidgets('returns EdgeInsets.all(16) when no system navigation',
        (tester) async {
      late EdgeInsets result;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            viewPadding: EdgeInsets.zero,
          ),
          child: Builder(
            builder: (context) {
              result = pagePadding(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, const EdgeInsets.all(16));
    });
  });
}
