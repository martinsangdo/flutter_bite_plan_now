import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';

/// Pexels search for dish photography, via the `pexels-photo` Edge Function.
/// Returns null on any failure so the UI can show a placeholder.
class ImageService {
  Future<String?> search(String query) async {
    if (!Config.supabaseEnabled) return null;
    try {
      final res = await Supabase.instance.client.functions
          .invoke('pexels-photo', body: {'query': query})
          .timeout(const Duration(seconds: 10));
      final photos = (res.data as Map)['photos'];
      return photos is List && photos.isNotEmpty
          ? photos[0]['src']['large'] as String?
          : null;
    } catch (_) {
      return null;
    }
  }
}
