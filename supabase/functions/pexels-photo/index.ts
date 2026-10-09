import { guard, json, relay } from "../_shared/guard.ts";

Deno.serve(async (req) => {
  const denied = await guard(req, "photo", 300);
  if (denied) return denied;

  const { query } = await req.json().catch(() => ({}));
  if (typeof query !== "string" || query.length === 0 || query.length > 80) {
    return json({ error: "bad_request" }, 400);
  }

  const url = new URL("https://api.pexels.com/v1/search");
  url.search = new URLSearchParams({
    query: `${query} food`,
    per_page: "1",
    orientation: "landscape",
  }).toString();
  return relay(
    await fetch(url, { headers: { Authorization: Deno.env.get("PEXELS_API_KEY")! } }),
  );
});
