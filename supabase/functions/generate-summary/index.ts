// generate-summary: produces a 2–4 sentence recent-interactions summary for a person.
// Input:  { personName: string, notes: Array<{ type: string, body: string, date: string }> }
// Output: { summary: string }

import { corsHeaders } from "../_shared/cors.ts";
import { callClaude } from "../_shared/claude.ts";
import { requireUser } from "../_shared/auth.ts";

interface RequestBody {
  personName: string;
  notes: Array<{ type: string; body: string; date: string }>;
}

const SYSTEM = `You write short, warm summaries of someone's recent interactions
with a specific person, designed to be shown at the top of that person's profile
to help the user quickly remember what's been going on.

Rules:
- 2 to 4 sentences. Natural prose, no bullets, no headers.
- Refer to the person by their first name.
- Cover what's most current and what the user is most likely to want to recall
  before reaching out (recent events, ongoing situations, notable mentions).
- Past tense for things that happened, present for ongoing.
- If no notes are provided, return: "You haven't logged any interactions yet."`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    await requireUser(req);
    const body = (await req.json()) as RequestBody;

    if (body.notes.length === 0) {
      return new Response(
        JSON.stringify({ summary: "You haven't logged any interactions yet." }),
        { headers: { ...corsHeaders, "content-type": "application/json" } },
      );
    }

    const noteList = body.notes
      .map((n) => `- (${n.date}, ${n.type}) ${n.body}`)
      .join("\n");

    const userMessage = `Person: ${body.personName}
Recent notes (newest first):
${noteList}

Write the summary.`;

    const summary = (await callClaude({
      system: SYSTEM,
      messages: [{ role: "user", content: userMessage }],
      maxTokens: 256,
      temperature: 0.5,
    })).trim();

    return new Response(JSON.stringify({ summary }), {
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  }
});
