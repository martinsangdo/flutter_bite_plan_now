import { guard, json, relay } from "../_shared/guard.ts";

const MODEL = "llama-3.3-70b-versatile";

const SYSTEM_PROMPT = `
You are a culinary engine for a 3-ingredient pantry app. Respond with ONLY a JSON object:
{"recipes":[{"id":"1","title":"","prep_time":"8 Mins","calories":"320 kcal","protein":"18g",
"ingredients_used":[],"missing_staples":[],"chef_tip":"","image_query":"","steps":[]}]}
Rules: return exactly 5 recipes; every recipe uses ONLY the given ingredients plus basic staples
(salt, pepper, cooking oil, water); list any staples it needs in "missing_staples"; each recipe
takes 15 minutes or less; "image_query" is 2-3 words describing the finished dish for a photo search;
"steps" has 3-6 short imperative steps and states durations like "cook 2 minutes" where timing matters;
"ingredients_used" must use the exact ingredient names provided.`;

Deno.serve(async (req) => {
  const denied = await guard(req, "recipes", 50);
  if (denied) return denied;

  const { ingredients } = await req.json().catch(() => ({}));
  const valid = Array.isArray(ingredients) &&
    ingredients.length >= 1 && ingredients.length <= 3 &&
    ingredients.every((i) => typeof i === "string" && i.length > 0 && i.length <= 40);
  if (!valid) return json({ error: "bad_request" }, 400);

  return relay(
    await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${Deno.env.get("GROQ_API_KEY")}`,
      },
      body: JSON.stringify({
        model: MODEL,
        temperature: 0.7,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: `Ingredients: ${ingredients.join(", ")}` },
        ],
      }),
    }),
  );
});
