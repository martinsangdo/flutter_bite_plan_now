class Recipe {
  final String id;
  final String title;
  final String prepTime;
  final String calories;
  final String protein;
  final List<String> ingredientsUsed;
  final List<String> missingStaples;
  final String chefTip;
  final String imageQuery;
  final List<String> steps;

  const Recipe({
    required this.id,
    required this.title,
    required this.prepTime,
    required this.calories,
    required this.protein,
    required this.ingredientsUsed,
    required this.missingStaples,
    required this.chefTip,
    required this.imageQuery,
    required this.steps,
  });

  /// Returns null when the payload lacks a title or steps, so one bad
  /// LLM recipe does not discard the whole deck.
  static Recipe? tryParse(Object? raw, String fallbackId) {
    if (raw is! Map) return null;
    List<String> strings(Object? v) =>
        v is List ? v.whereType<String>().toList() : const [];
    String str(Object? v, String d) => v is String && v.isNotEmpty ? v : d;

    final title = raw['title'];
    final steps = strings(raw['steps']);
    if (title is! String || title.isEmpty || steps.isEmpty) return null;
    return Recipe(
      id: fallbackId,
      title: title,
      prepTime: str(raw['prep_time'], '10 Mins'),
      calories: str(raw['calories'], '—'),
      protein: str(raw['protein'], '—'),
      ingredientsUsed: strings(raw['ingredients_used']),
      missingStaples: strings(raw['missing_staples']),
      chefTip: str(raw['chef_tip'], ''),
      imageQuery: str(raw['image_query'], title),
      steps: steps,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'prep_time': prepTime,
    'calories': calories,
    'protein': protein,
    'ingredients_used': ingredientsUsed,
    'missing_staples': missingStaples,
    'chef_tip': chefTip,
    'image_query': imageQuery,
    'steps': steps,
  };
}
