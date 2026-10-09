import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../core/ingredients.dart';
import '../models/recipe.dart';
import '../services/ads_service.dart';
import '../services/ai_service.dart';
import '../services/history_service.dart';
import '../services/image_service.dart';
import '../services/vision_service.dart';

final aiServiceProvider = Provider((_) => AiService());
final imageServiceProvider = Provider((_) => ImageService());
final visionServiceProvider = Provider(
  (ref) => VisionService(ref.watch(aiServiceProvider)),
);
final historyServiceProvider = Provider((_) => HistoryService());
final adsProvider = Provider(
  (_) => AdsService()
    ..preload()
    ..preloadRewarded(),
);

/// Dish photo URL for a search query; cached per query for the app session.
final recipeImageProvider = FutureProvider.family<String?, String>(
  (ref, query) => ref.watch(imageServiceProvider).search(query),
);

class PantryState {
  final List<String> custom;
  final Set<String> selected;
  const PantryState({this.custom = const [], this.selected = const {}});
}

class PantryNotifier extends Notifier<PantryState> {
  @override
  PantryState build() => const PantryState();

  bool get isFull => state.selected.length >= kMaxIngredients;

  /// Returns false when selecting would exceed [kMaxIngredients].
  bool toggle(String name) {
    final next = {...state.selected};
    if (!next.remove(name)) {
      if (isFull) return false;
      next.add(name);
    }
    state = PantryState(custom: state.custom, selected: next);
    return true;
  }

  /// Adds (if new) and selects. Returns false when the cap blocked it.
  bool addCustom(String raw) {
    final name = matchCatalog(raw) ?? titleCase(raw);
    if (name.isEmpty) return false;
    if (state.selected.contains(name)) return true;
    if (isFull) return false;
    final isCatalog = catalog.any((i) => i.name == name);
    state = PantryState(
      custom: isCatalog || state.custom.contains(name)
          ? state.custom
          : [...state.custom, name],
      selected: {...state.selected, name},
    );
    return true;
  }

  /// Selects detected items until the cap; returns how many were dropped.
  int addDetected(List<String> names) {
    var dropped = 0;
    for (final n in names) {
      if (!addCustom(n)) dropped++;
    }
    return dropped;
  }

  void clear() => state = PantryState(custom: state.custom);
}

final pantryProvider = NotifierProvider<PantryNotifier, PantryState>(
  PantryNotifier.new,
);

/// Overridden in main() with the loaded instance.
final prefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('prefsProvider must be overridden'),
);

String _today() => DateTime.now().toIso8601String().substring(0, 10);

/// Scan allowance. Free scans and ad bonuses are per session (in memory);
/// the daily total is persisted so a restart cannot reset it.
class ScanQuota {
  final int sessionUsed;
  final int bonus;
  final String day;
  final int dayCount;
  const ScanQuota({
    this.sessionUsed = 0,
    this.bonus = 0,
    required this.day,
    required this.dayCount,
  });

  int get dailyUsed => day == _today() ? dayCount : 0;
  int get dailyLeft => kMaxScansPerDay - dailyUsed;
  int get freeLeft => kMaxScansPerSession + bonus - sessionUsed;

  /// Capped by the day's remaining total, so it is what the user can really scan.
  int get scansLeft => freeLeft < dailyLeft ? freeLeft : dailyLeft;
  bool get canScan => scansLeft > 0;

  /// Session scans are used up but the day's cap isn't: a rewarded ad may unlock one.
  bool get canEarn => freeLeft <= 0 && dailyLeft > 0;
}

class ScanQuotaNotifier extends Notifier<ScanQuota> {
  static const _dayKey = 'scan_day';
  static const _countKey = 'scan_day_count';

  @override
  ScanQuota build() {
    final prefs = ref.read(prefsProvider);
    return ScanQuota(
      day: prefs.getString(_dayKey) ?? '',
      dayCount: prefs.getInt(_countKey) ?? 0,
    );
  }

  /// Counts a photo against the session and the day.
  void record() {
    final day = _today();
    final count = state.dailyUsed + 1;
    state = ScanQuota(
      sessionUsed: state.sessionUsed + 1,
      bonus: state.bonus,
      day: day,
      dayCount: count,
    );
    final prefs = ref.read(prefsProvider);
    prefs.setString(_dayKey, day);
    prefs.setInt(_countKey, count);
  }

  /// One extra scan this session, earned by watching a rewarded ad.
  void grantBonus() => state = ScanQuota(
    sessionUsed: state.sessionUsed,
    bonus: state.bonus + 1,
    day: state.day,
    dayCount: state.dayCount,
  );
}

final scanQuotaProvider = NotifierProvider<ScanQuotaNotifier, ScanQuota>(
  ScanQuotaNotifier.new,
);

/// Recipe requests ("questions") per day, persisted. [kFreeQuestionsPerDay]
/// are free; each rewarded ad unlocks one more, up to [kMaxQuestionsPerDay].
class QuestionQuota {
  final String day;
  final int _used;
  final int _bonus;
  const QuestionQuota({
    required this.day,
    required int used,
    required int bonus,
  }) : _used = used,
       _bonus = bonus;

  bool get _isToday => day == _today();
  int get used => _isToday ? _used : 0;
  int get bonus => _isToday ? _bonus : 0;

  bool get canAsk => used < kFreeQuestionsPerDay + bonus;

  /// Free questions are used up but the day's cap isn't: an ad may unlock one.
  bool get canEarn => !canAsk && used < kMaxQuestionsPerDay;
}

class QuestionQuotaNotifier extends Notifier<QuestionQuota> {
  static const _dayKey = 'q_day';
  static const _usedKey = 'q_used';
  static const _bonusKey = 'q_bonus';

  @override
  QuestionQuota build() {
    final prefs = ref.read(prefsProvider);
    return QuestionQuota(
      day: prefs.getString(_dayKey) ?? '',
      used: prefs.getInt(_usedKey) ?? 0,
      bonus: prefs.getInt(_bonusKey) ?? 0,
    );
  }

  void record() => _set(used: state.used + 1, bonus: state.bonus);

  void grantBonus() => _set(used: state.used, bonus: state.bonus + 1);

  void _set({required int used, required int bonus}) {
    final day = _today();
    state = QuestionQuota(day: day, used: used, bonus: bonus);
    final prefs = ref.read(prefsProvider);
    prefs.setString(_dayKey, day);
    prefs.setInt(_usedKey, used);
    prefs.setInt(_bonusKey, bonus);
  }
}

final questionQuotaProvider =
    NotifierProvider<QuestionQuotaNotifier, QuestionQuota>(
      QuestionQuotaNotifier.new,
    );

class DeckNotifier extends AsyncNotifier<List<Recipe>> {
  @override
  List<Recipe> build() => const [];

  /// Sets [state] to loading, then to recipes or an error.
  Future<void> generate(List<String> ingredients) async {
    ref.read(questionQuotaProvider.notifier).record();
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(aiServiceProvider).generateRecipes(ingredients),
    );
  }
}

final deckProvider = AsyncNotifierProvider<DeckNotifier, List<Recipe>>(
  DeckNotifier.new,
);

class PointsNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async =>
      await ref.read(historyServiceProvider).mealCount() * kPointsPerMeal;

  /// Saves the meal and bumps the badge. Returns whether it reached the backend.
  Future<bool> saveMeal(Recipe r) async {
    final ok = await ref.read(historyServiceProvider).save(r);
    state = AsyncData((state.value ?? 0) + kPointsPerMeal);
    return ok;
  }
}

final pointsProvider = AsyncNotifierProvider<PointsNotifier, int>(
  PointsNotifier.new,
);
