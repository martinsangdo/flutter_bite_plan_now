import 'dart:io';

/// Build-time configuration. Supply with `--dart-define-from-file=env.json`.
/// Client-side keys can be extracted from the app binary: for production,
/// route Groq/Gemini/Pexels calls through a Supabase Edge Function instead.
class Config {
  static const groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const pexelsApiKey = String.fromEnvironment('PEXELS_API_KEY');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const groqModel = 'llama-3.3-70b-versatile';
  static const geminiModel = 'gemini-2.5-flash';

  static bool get supabaseEnabled =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // Google's public test ad units. Replace with real units before release.
  static String get bannerAdUnit => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/9214589741'
      : 'ca-app-pub-3940256099942544/2435281174';
  static String get interstitialAdUnit => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';
}

const kMaxIngredients = 3;
const kMaxScansPerSession = 3;
const kLocalConfidence = 0.7;
const kAdEverySwipes = 4;
const kPointsPerMeal = 50;
