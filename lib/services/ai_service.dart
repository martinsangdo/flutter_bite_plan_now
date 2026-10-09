import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/recipe.dart';

class AiException implements Exception {
  final String message;
  AiException(this.message);
  @override
  String toString() => message;
}

/// Recipes (Groq) and vision fallback (Gemini), reached through Supabase Edge
/// Functions so vendor API keys never ship in the app.
class AiService {
  static const _timeout = Duration(seconds: 25);

  Future<List<Recipe>> generateRecipes(List<String> ingredients) async {
    final body = await _invoke('groq-recipes', {'ingredients': ingredients});
    final content = body['choices']?[0]?['message']?['content'];
    final parsed = _decodeJson(content);
    final list = parsed['recipes'];
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final recipes = <Recipe>[];
    if (list is List) {
      for (var i = 0; i < list.length; i++) {
        final r = Recipe.tryParse(list[i], '$stamp-$i');
        if (r != null) recipes.add(r);
      }
    }
    if (recipes.isEmpty) {
      throw AiException('The chef returned no usable recipes. Try again.');
    }
    return recipes;
  }

  /// Names the food items visible in a JPEG. Used when on-device detection
  /// is below [kLocalConfidence].
  Future<List<String>> detectIngredients(Uint8List jpeg) async {
    final body = await _invoke('gemini-vision', {'image': base64Encode(jpeg)});
    final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'];
    final list = _decodeJson(text)['ingredients'];
    return list is List ? list.whereType<String>().toList() : const [];
  }

  Future<Map<String, dynamic>> _invoke(
    String function,
    Map<String, dynamic> payload,
  ) async {
    if (!Config.supabaseEnabled) {
      throw AiException('Backend not configured. See README for setup.');
    }
    try {
      final res = await Supabase.instance.client.functions
          .invoke(function, body: payload)
          .timeout(_timeout);
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      throw AiException('Unexpected AI response.');
    } on AiException {
      rethrow;
    } on FunctionException catch (e) {
      if (e.status == 429) {
        throw AiException(
          'Daily AI limit reached or rate-limited. Try again later.',
        );
      }
      throw AiException('AI service error (${e.status}).');
    } catch (_) {
      throw AiException('Network problem. Check your connection and retry.');
    }
  }

  Map<String, dynamic> _decodeJson(Object? text) {
    try {
      final decoded = jsonDecode(text as String);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    throw AiException('The AI returned malformed data. Try again.');
  }
}
