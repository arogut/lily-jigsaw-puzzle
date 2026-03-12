import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocaleNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial locale is the one provided', () {
      final notifier = LocaleNotifier(const Locale('en'));
      expect(notifier.locale, const Locale('en'));
    });

    test('setLocale updates the locale', () {
      final notifier = LocaleNotifier(const Locale('en'))
        ..setLocale(const Locale('pl'));
      expect(notifier.locale, const Locale('pl'));
    });

    test('setLocale notifies listeners', () {
      var notified = false;
      LocaleNotifier(const Locale('en'))
        ..addListener(() => notified = true)
        ..setLocale(const Locale('de'));
      expect(notified, isTrue);
    });

    test('load returns Polish as default when no preference is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = await LocaleNotifier.load();
      expect(notifier.locale, const Locale('pl'));
    });

    test('load returns saved locale from preferences', () async {
      SharedPreferences.setMockInitialValues({'locale': 'de'});
      final notifier = await LocaleNotifier.load();
      expect(notifier.locale, const Locale('de'));
    });

    test('load returns English when en is saved', () async {
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      final notifier = await LocaleNotifier.load();
      expect(notifier.locale, const Locale('en'));
    });

    test('setLocale persists locale to shared preferences', () async {
      SharedPreferences.setMockInitialValues({});
      LocaleNotifier(const Locale('en')).setLocale(const Locale('es'));
      // Allow the async save to complete
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), 'es');
    });

    test('can change locale multiple times', () {
      final notifier = LocaleNotifier(const Locale('en'))
        ..setLocale(const Locale('pl'))
        ..setLocale(const Locale('de'))
        ..setLocale(const Locale('es'));
      expect(notifier.locale, const Locale('es'));
    });
  });
}
