import { createClient } from "npm:@supabase/supabase-js@2";

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/// Maps a vendor response to what the app sees. Vendor error bodies are
/// never forwarded.
export async function relay(res: Response): Promise<Response> {
  if (res.ok) return json(await res.json());
  return json({ error: "upstream" }, res.status === 429 ? 429 : 502);
}

/// Requires a signed-in (anonymous sessions included) user and charges one
/// unit against their daily quota for [kind]. Returns an error response to
/// send back, or null when the call may proceed.
export async function guard(
  req: Request,
  kind: string,
  dailyLimit: number,
): Promise<Response | null> {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
  );
  const { data: { user } } = await db.auth.getUser();
  if (!user) return json({ error: "unauthorized" }, 401);
  const { data: allowed, error } = await db.rpc("consume_quota", {
    p_kind: kind,
    p_limit: dailyLimit,
  });
  if (error) return json({ error: "quota" }, 500);
  return allowed ? null : json({ error: "rate_limited" }, 429);
}
