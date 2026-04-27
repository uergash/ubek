import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/// Verifies the JWT in the request and returns the authenticated user id,
/// or throws.
export async function requireUser(req: Request): Promise<string> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) throw new Error("Missing Authorization header");

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) throw new Error("Invalid auth token");
  return data.user.id;
}
