import { guard, json, relay } from "../_shared/guard.ts";

const MODEL = "gemini-2.5-flash";
const MAX_BASE64_CHARS = 6_000_000; // ~4.5 MB of JPEG

Deno.serve(async (req) => {
  const denied = await guard(req, "vision", 20);
  if (denied) return denied;

  const { image } = await req.json().catch(() => ({}));
  if (typeof image !== "string" || image.length === 0 || image.length > MAX_BASE64_CHARS) {
    return json({ error: "bad_request" }, 400);
  }

  return relay(
    await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": Deno.env.get("GEMINI_API_KEY")!,
        },
        body: JSON.stringify({
          contents: [{
            parts: [
              {
                text: "List the distinct raw food ingredients visible in this photo. " +
                  'Use short singular-or-plural common names (e.g. "Eggs", "Tomato"). ' +
                  'Respond as JSON: {"ingredients":["..."]}. Empty list if none.',
              },
              { inline_data: { mime_type: "image/jpeg", data: image } },
            ],
          }],
          generationConfig: { responseMimeType: "application/json", temperature: 0.1 },
        }),
      },
    ),
  );
});
