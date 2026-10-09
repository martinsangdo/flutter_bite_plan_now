import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/recipe.dart';

/// Meal history in Supabase (anonymous auth + RLS). When Supabase is not
/// configured, history lives in memory for the session.
class HistoryService {
  int _local = 0;

  static Future<void> init() async {
    if (!Config.supabaseEnabled) return;
    await Supabase.initialize(
      url: Config.supabaseUrl,
      publishableKey: Config.supabaseAnonKey,
    );
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) {
      try {
        await auth.signInAnonymously();
      } catch (_) {
        // Offline at first launch: history falls back to session memory.
      }
    }
  }

  SupabaseClient? get _client {
    if (!Config.supabaseEnabled) return null;
    final c = Supabase.instance.client;
    return c.auth.currentUser == null ? null : c;
  }

  Future<int> mealCount() async {
    final c = _client;
    if (c == null) return _local;
    try {
      return await c.from('meal_history').count();
    } catch (_) {
      return _local;
    }
  }

  /// Returns true when persisted remotely (or no backend is configured).
  Future<bool> save(Recipe r) async {
    _local++;
    final c = _client;
    if (c == null) return !Config.supabaseEnabled;
    try {
      await c.from('meal_history').insert({
        'recipe_id': r.id,
        'title': r.title,
        'recipe': r.toJson(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
