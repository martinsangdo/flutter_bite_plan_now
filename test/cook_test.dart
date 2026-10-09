import 'package:bite_plan_now/core/ingredients.dart';
import 'package:bite_plan_now/models/recipe.dart';
import 'package:bite_plan_now/screens/cook_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stepSeconds parses durations', () {
    expect(stepSeconds('Cook 2 minutes'), 120);
    expect(stepSeconds('Simmer 2-3 mins until thick'), 180);
    expect(stepSeconds('Rest for 30 seconds'), 30);
    expect(stepSeconds('Dice the tomato'), isNull);
  });

  test('matchCatalog maps labels to catalog names', () {
    expect(matchCatalog('Fried egg'), 'Eggs');
    expect(matchCatalog('cherry tomatoes'), 'Tomato');
    expect(matchCatalog('Home good'), isNull);
  });

  test('Recipe.tryParse skips invalid recipes', () {
    expect(Recipe.tryParse({'title': 'x', 'steps': []}, 'a'), isNull);
    final r = Recipe.tryParse({
      'title': 'Omelette',
      'steps': ['Cook 1 minute'],
    }, 'a');
    expect(r?.prepTime, '10 Mins');
  });
}
