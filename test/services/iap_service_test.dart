import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/services/iap_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Prevent InAppPurchase.instance from registering the Android billing
  // client, which requires platform channels unavailable in unit tests.
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;

  group('IAPService singleton', () {
    test('returns the same instance', () {
      final a = IAPService();
      final b = IAPService();
      expect(identical(a, b), isTrue);
    });

    test('shares state across instances', () {
      final a = IAPService();
      final b = IAPService();

      bool called = false;
      a.onPurchaseStatusChanged = (_) => called = true;

      // Calling through b should use the same callback
      b.onPurchaseStatusChanged?.call(true);
      expect(called, isTrue);
    });

    test('last callback setter wins', () {
      final service = IAPService();
      final calls = <String>[];

      service.onPurchaseStatusChanged = (_) => calls.add('first');
      service.onPurchaseStatusChanged = (_) => calls.add('second');

      service.onPurchaseStatusChanged?.call(true);
      expect(calls, ['second']);
    });
  });
}
