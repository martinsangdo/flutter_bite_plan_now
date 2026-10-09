import 'package:bite_plan_now/core/config.dart';
import 'package:bite_plan_now/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container([
  Map<String, Object> stored = const {},
]) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
}

void main() {
  test('session cap unlocks one scan per rewarded ad', () async {
    final c = await _container();
    final n = c.read(scanQuotaProvider.notifier);
    for (var i = 0; i < kMaxScansPerSession; i++) {
      n.record();
    }
    expect(c.read(scanQuotaProvider).canScan, isFalse);
    expect(c.read(scanQuotaProvider).canEarn, isTrue);

    n.grantBonus();
    expect(c.read(scanQuotaProvider).scansLeft, 1);
    n.record();
    expect(c.read(scanQuotaProvider).canEarn, isTrue);
  });

  test('daily cap stops ads and survives a restart', () async {
    final c = await _container();
    final n = c.read(scanQuotaProvider.notifier);
    for (var i = 0; i < kMaxScansPerDay; i++) {
      if (!c.read(scanQuotaProvider).canScan) n.grantBonus();
      n.record();
    }
    final q = c.read(scanQuotaProvider);
    expect(q.dailyLeft, 0);
    expect(q.canEarn, isFalse);
    n.grantBonus();
    expect(c.read(scanQuotaProvider).canScan, isFalse);

    final prefs = await SharedPreferences.getInstance();
    final restarted = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    expect(restarted.read(scanQuotaProvider).dailyLeft, 0);
  });

  test('a previous day does not count', () async {
    final c = await _container({
      'scan_day': '2000-01-01',
      'scan_day_count': 20,
    });
    expect(c.read(scanQuotaProvider).dailyLeft, kMaxScansPerDay);
  });

  test('questions: 30 free, ads unlock up to 50, persisted', () async {
    final c = await _container();
    final n = c.read(questionQuotaProvider.notifier);
    for (var i = 0; i < kFreeQuestionsPerDay; i++) {
      expect(c.read(questionQuotaProvider).canAsk, isTrue);
      n.record();
    }
    expect(c.read(questionQuotaProvider).canAsk, isFalse);
    expect(c.read(questionQuotaProvider).canEarn, isTrue);

    for (var i = kFreeQuestionsPerDay; i < kMaxQuestionsPerDay; i++) {
      expect(c.read(questionQuotaProvider).canEarn, isTrue);
      n.grantBonus();
      expect(c.read(questionQuotaProvider).canAsk, isTrue);
      n.record();
    }
    final q = c.read(questionQuotaProvider);
    expect(q.canAsk, isFalse);
    expect(q.canEarn, isFalse);

    final prefs = await SharedPreferences.getInstance();
    final restarted = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    expect(restarted.read(questionQuotaProvider).canEarn, isFalse);
  });

  test('questions: a previous day resets count and bonus', () async {
    final c = await _container({
      'q_day': '2000-01-01',
      'q_used': 50,
      'q_bonus': 20,
    });
    final q = c.read(questionQuotaProvider);
    expect(q.used, 0);
    expect(q.canAsk, isTrue);
  });
}
