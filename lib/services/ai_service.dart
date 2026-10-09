import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../models/recipe.dart';

class AiException implements Exception {
  final String message;
  AiException(this.message);
  @override
  String toString() => message;
}

/// Groq (recipes) + Gemini (vision fallback) REST client.
class AiService {
  AiService({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  static const _timeout = Duration(seconds: 25);

  static const _recipeSystemPrompt = '''
You are a culinary engine for a 3-ingredient pantry app. Respond with ONLY a JSON object:
{"recipes":[{"id":"1","title":"","prep_time":"8 Mins","calories":"320 kcal","protein":"18g",
"ingredients_used":[],"missing_staples":[],"chef_tip":"","image_query":"","steps":[]}]}
Rules: return exactly 5 recipes; every recipe uses ONLY the given ingredients plus basic staples
(salt, pepper, cooking oil, water); list any staples it needs in "missing_staples"; each recipe
takes 15 minutes or less; "image_query" is 2-3 words describing the finished dish for a photo search;
"steps" has 3-6 short imperative steps and states durations like "cook 2 minutes" where timing matters;
"ingredients_used" must use the exact ingredient names provided.''';

  Future<List<Recipe>> generateRecipes(List<String> ingredients) async {
    if (Config.groqApiKey.isEmpty) {
      throw AiException('Missing GROQ_API_KEY. See README for setup.');
    }
    final body = await _post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      {'Authorization': 'Bearer ${Config.groqApiKey}'},
      {
        'model': Config.groqModel,
        'temperature': 0.7,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': _recipeSystemPrompt},
          {'role': 'user', 'content': 'Ingredients: ${ingredients.join(', ')}'},
        ],
      },
    );
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
    if (Config.geminiApiKey.isEmpty) {
      throw AiException(
        'Could not identify items on-device and GEMINI_API_KEY is not set.',
      );
    }
    final body = await _post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/${Config.geminiModel}:generateContent',
      ),
      {'x-goog-api-key': Config.geminiApiKey},
      {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'List the distinct raw food ingredients visible in this photo. '
                    'Use short singular-or-plural common names (e.g. "Eggs", "Tomato"). '
                    'Respond as JSON: {"ingredients":["..."]}. Empty list if none.',
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(jpeg),
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.1,
        },
      },
    );
    final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'];
    final list = _decodeJson(text)['ingredients'];
    return list is List ? list.whereType<String>().toList() : const [];
  }

  Future<Map<String, dynamic>> _post(
    Uri url,
    Map<String, String> headers,
    Map<String, dynamic> payload,
  ) async {
    final http.Response res;
    try {
      res = await _http
          .post(
            url,
            headers: {'Content-Type': 'application/json', ...headers},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
    } catch (_) {
      throw AiException('Network problem. Check your connection and retry.');
    }
    if (res.statusCode == 429) {
      throw AiException(
        'The free AI tier is rate-limited. Wait a moment and retry.',
      );
    }
    if (res.statusCode != 200) {
      throw AiException('AI service error (${res.statusCode}).');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    return decoded is Map<String, dynamic>
        ? decoded
        : throw AiException('Unexpected AI response.');
  }

  Map<String, dynamic> _decodeJson(Object? text) {
    try {
      final decoded = jsonDecode(text as String);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    throw AiException('The AI returned malformed data. Try again.');
  }
}
