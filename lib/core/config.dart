import 'dart:io';

/// Build-time configuration. Supply with `--dart-define-from-file=env.json`.
/// Only public values belong here: vendor API keys (Groq/Gemini/Pexels) live
/// in Supabase secrets and are used by the Edge Functions in supabase/functions.
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get supabaseEnabled =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // Google's public test ad units. Replace with real units before release.
  static String get bannerAdUnit => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/9214589741'
      : 'ca-app-pub-3940256099942544/2435281174';
  static String get interstitialAdUnit => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';
  static String get rewardedAdUnit => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';
}

const kMaxIngredients = 3;
const kMaxScansPerSession = 3;
const kMaxScansPerDay = 20;
const kLocalConfidence = 0.7;
const kAdEverySwipes = 4;
const kPointsPerMeal = 50;
const kFreeQuestionsPerDay = 30;
const kMaxQuestionsPerDay = 50;
