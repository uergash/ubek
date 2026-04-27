// generate-bond-line: writes one warm sentence reminding the user of their
// bond with a specific person. Used on the People page "Today's spotlight" card.
// Input:  { personName: string, keyFacts: string[], recentNotes: Array<{ type, body, date }> }
// Output: { line: string }

import { corsHeaders } from "../_shared/cors.ts";
import { callClaude } from "../_shared/claude.ts";
import { requireUser } from "../_shared/auth.ts";

interface RequestBody {
  personName: string;
  keyFacts: string[];
  recentNotes: Array<{ type: string; body: string; date: string }>;
}

const SYSTEM = `You write a single warm, reflective sentence reminding a user of
their bond with a specific person. The output is shown on a "person of the day"
card, designed to ground the user in why this relationship matters.

Rules:
- EXACTLY one sentence. Plain prose. No quotes, no preface, no emoji.
- Refer to the person by their first name only.
- Lean on what's known: shared interests, what they care about, recent context.
- Frame the relationship, not just recent events. Past notes are a window into
  the bond, not a summary of activity.
- Stay grounded and specific — avoid generic platitudes ("you have a wonderful
  friendship") and avoid flowery language.
- If there's almost nothing to work with, return: "Take a moment to think about [Name] today."`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    await requireUser(req);
    const body = (await req.json()) as RequestBody;

    if (body.keyFacts.length === 0 && body.recentNotes.length === 0) {
      return new Response(
        JSON.stringify({ line: `Take a moment to think about ${body.personName} today.` }),
        { headers: { ...corsHeaders, "content-type": "application/json" } },
      );
    }

    const facts = body.keyFacts.length
      ? `Known facts:\n${body.keyFacts.map((f) => `- ${f}`).join("\n")}`
      : "";
    const noteList = body.recentNotes.length
      ? `Recent notes (newest first):\n${body.recentNotes.map((n) => `- (${n.date}, ${n.type}) ${n.body}`).join("\n")}`
      : "";

    const userMessage = [
      `Person: ${body.personName}`,
      facts,
      noteList,
      "",
      "Write the one-sentence reminder.",
    ].filter(Boolean).join("\n\n");

    const line = (await callClaude({
      system: SYSTEM,
      messages: [{ role: "user", content: userMessage }],
      maxTokens: 120,
      temperature: 0.6,
    })).trim();

    return new Response(JSON.stringify({ line }), {
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  }
});
