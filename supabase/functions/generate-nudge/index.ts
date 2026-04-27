// generate-nudge: writes a short reach-out suggestion for the user, grounded
// in what they know about a friend.
// Input:  { personName: string, keyFacts: string[],
//           lastNotes: Array<{ type, body, date }>, daysSince: number }
// Output: { suggestion: string }

import { corsHeaders } from "../_shared/cors.ts";
import { callClaude } from "../_shared/claude.ts";
import { requireUser } from "../_shared/auth.ts";

interface RequestBody {
  personName: string;
  keyFacts: string[];
  lastNotes: Array<{ type: string; body: string; date: string }>;
  daysSince: number;
}

const SYSTEM = `You write short, specific reach-out suggestions to help someone
get back in touch with a friend they haven't talked to recently.

Rules:
- 1 to 2 sentences. Conversational, warm, never preachy.
- Always reference something concrete from the friend's key facts or recent notes
  (an ongoing project, an event they mentioned, a person in their life). Don't
  generate generic "you should reach out" copy.
- Address the user directly with "You". Refer to the friend by first name.
- Don't write the message itself — write the suggestion *to the user* about what
  to bring up.
- Output the suggestion text only, no quotes, no prefix.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    await requireUser(req);
    const body = (await req.json()) as RequestBody;

    const noteList = body.lastNotes.length
      ? body.lastNotes.map((n) => `- (${n.date}, ${n.type}) ${n.body}`).join("\n")
      : "(no recent notes)";

    const userMessage = `Friend: ${body.personName}
Days since last interaction: ${body.daysSince}
Key facts:
${body.keyFacts.map((f) => `- ${f}`).join("\n") || "(none)"}

Recent notes (newest first):
${noteList}

Write the suggestion.`;

    const suggestion = (await callClaude({
      system: SYSTEM,
      messages: [{ role: "user", content: userMessage }],
      maxTokens: 200,
      temperature: 0.6,
    })).trim();

    return new Response(JSON.stringify({ suggestion }), {
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  }
});
