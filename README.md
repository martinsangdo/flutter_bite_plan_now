# BitePlanNow

Pick up to 3 pantry ingredients (or scan them), get swipeable AI recipe cards, then cook step by step.

## Setup
1. `cp env.example.json env.json` and fill in keys (Groq, Gemini, Pexels, Supabase — all optional except Groq).
2. Supabase: enable Anonymous sign-ins, run `supabase/schema.sql`.
3. Replace the Google test AdMob app IDs in `AndroidManifest.xml` / `Info.plist` and the unit IDs in `lib/core/config.dart` before release.
4. `flutter run --dart-define-from-file=env.json`

## Notes
- Client-side API keys are extractable from the binary. Before shipping, proxy Groq/Gemini/Pexels via Supabase Edge Functions.
- ML Kit's default object detector returns coarse labels ("Food", "Plant"); most scans will fall through to Gemini. For better offline accuracy, supply a custom TFLite model via `LocalObjectDetectorOptions`.
