import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';

/// Pexels search for dish photography. Returns null on any failure so the
/// UI can show a placeholder.
class ImageService {
  ImageService({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  Future<String?> search(String query) async {
    if (Config.pexelsApiKey.isEmpty) return null;
    try {
      final res = await _http
          .get(
            Uri.https('api.pexels.com', '/v1/search', {
              'query': '$query food',
              'per_page': '1',
              'orientation': 'landscape',
            }),
            headers: {'Authorization': Config.pexelsApiKey},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final photos = jsonDecode(utf8.decode(res.bodyBytes))['photos'];
      return photos is List && photos.isNotEmpty
          ? photos[0]['src']['large'] as String?
          : null;
    } catch (_) {
      return null;
    }
  }
}
