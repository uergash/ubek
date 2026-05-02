// generate-nudge: drafts a short text message the user can send to a friend
// they haven't talked to recently — ready to copy or send from Messages.
// Input:  { personName: string, keyFacts: string[],
//           lastNotes: Array<{ type, body, date }>, daysSince: number }
// Output: { suggestion: string }  ← the drafted message body

import { corsHeaders } from "../_shared/cors.ts";
import { callClaude } from "../_shared/claude.ts";
import { requireUser } from "../_shared/auth.ts";

interface RequestBody {
  personName: string;
  keyFacts: string[];
  lastNotes: Array<{ type: string; body: string; date: string }>;
  daysSince: number;
}

const SYSTEM = `You draft a short text message the user is about to send to a
friend they haven't talked to recently. The output goes straight into the
Messages app — write it the way the user would actually text.

Rules:
- Write in the user's voice, addressed to the friend. First person ("I", "we"),
  second person to the friend ("you", "your"). Never refer to the user as "you".
- Reference something concrete and specific from the friend's key facts or
  recent notes (an ongoing project, a person in their life, a recent event).
  No generic "thinking of you" filler.
- 1 to 3 short sentences. Casual, warm, like a real text — contractions, no
  formal sign-off, no "Hi [Name]," opener required (a quick "hey" is fine).
- It's okay to ask a question; that often makes the text easier to reply to.
- Output the message body only — no quotes, no prefix, no commentary.`;

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

Draft the text message.`;

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
