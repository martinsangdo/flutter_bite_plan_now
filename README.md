# BitePlanNow

Pick up to 3 pantry ingredients (or scan them), get swipeable AI recipe cards, then cook step by step.

## Setup
1. `cp env.example.json env.json` and fill in `SUPABASE_URL` / `SUPABASE_ANON_KEY` (public values, safe to ship). Supabase is required for AI recipes, scans and dish photos.
2. Supabase: enable Anonymous sign-ins, run `supabase/schema.sql` (meal history + per-user daily quota).
3. Vendor keys live only in Supabase secrets, never in the app:
   ```
   supabase secrets set GROQ_API_KEY=... GEMINI_API_KEY=... PEXELS_API_KEY=...
   supabase functions deploy groq-recipes gemini-vision pexels-photo
   ```
   Also turn on CAPTCHA / sign-in rate limits under Authentication, since anonymous accounts are free to create.
4. Replace the Google test AdMob app IDs in `AndroidManifest.xml` / `Info.plist` and the unit IDs in `lib/core/config.dart` before release.
5. `flutter run --dart-define-from-file=env.json`

## Release
`flutter build appbundle --release --dart-define-from-file=env.json --obfuscate --split-debug-info=build/symbols` (and `flutter build ipa ...`). Keep `key.properties` and the keystore out of git.

## Notes
- ML Kit's default object detector returns coarse labels ("Food", "Plant"); most scans will fall through to Gemini. For better offline accuracy, supply a custom TFLite model via `LocalObjectDetectorOptions`.
