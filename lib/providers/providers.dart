import 'package:flutter_riverpod/flutter_riverpod.dart';

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
final adsProvider = Provider((_) => AdsService()..preload());

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

/// Scan photos analysed since app start. In-memory by design: the limit is per session.
class ScansUsedNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void record() => state++;
}

final scansUsedProvider = NotifierProvider<ScansUsedNotifier, int>(
  ScansUsedNotifier.new,
);

class DeckNotifier extends AsyncNotifier<List<Recipe>> {
  @override
  List<Recipe> build() => const [];

  /// Sets [state] to loading, then to recipes or an error.
  Future<void> generate(List<String> ingredients) async {
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
