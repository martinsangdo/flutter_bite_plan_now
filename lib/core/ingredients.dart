class Ingredient {
  final String name;
  final String emoji;
  const Ingredient(this.name, this.emoji);
}

const catalog = [
  Ingredient('Eggs', '🥚'),
  Ingredient('Cheese', '🧀'),
  Ingredient('Tomato', '🍅'),
  Ingredient('Milk', '🥛'),
  Ingredient('Bread', '🍞'),
  Ingredient('Rice', '🍚'),
  Ingredient('Garlic', '🧄'),
  Ingredient('Butter', '🧈'),
];

String emojiFor(String name) {
  for (final i in catalog) {
    if (i.name == name) return i.emoji;
  }
  return '🍽️';
}

String titleCase(String s) => s
    .trim()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
    .join(' ');

/// Maps free text (a detector label or model output) to a catalog name,
/// or null when it is not a catalog item.
String? matchCatalog(String text) {
  final t = text.toLowerCase();
  for (final i in catalog) {
    final stem = i.name.toLowerCase().replaceAll(RegExp(r's$'), '');
    if (t.contains(stem)) return i.name;
  }
  return null;
}
