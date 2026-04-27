// extract-facts: pulls 0–5 new "key facts" from a freshly-saved note.
// Input:  { noteBody: string, personName: string, existingFacts: string[] }
// Output: { facts: string[] }

import { corsHeaders } from "../_shared/cors.ts";
import { callClaude, extractJSON } from "../_shared/claude.ts";
import { requireUser } from "../_shared/auth.ts";

interface RequestBody {
  noteBody: string;
  personName: string;
  existingFacts: string[];
}

const SYSTEM = `You are an assistant that extracts durable personal facts about
someone from a short note the user wrote about a recent interaction.

Rules:
- Only return facts that are likely to remain true for weeks or months
  (e.g. "has a dog named Milo", "trains for triathlons", "works at Stripe").
- Do NOT include one-off events, plans for a specific date, or things the user did.
- Do NOT include facts that are already in the existing list (semantic match — same
  meaning even if worded differently counts as duplicate).
- Each fact must be a single short statement, max ~10 words, present tense, no period.
- If there are no new durable facts, return an empty array.
- Reply with ONLY a JSON array of strings. No prose, no markdown.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    await requireUser(req);
    const body = (await req.json()) as RequestBody;

    const userMessage = `Person: ${body.personName}
Existing facts:
${body.existingFacts.map((f) => `- ${f}`).join("\n") || "(none)"}

New note:
"""
${body.noteBody}
"""

Return JSON array of new facts (or [] if none).`;

    const text = await callClaude({
      system: SYSTEM,
      messages: [{ role: "user", content: userMessage }],
      maxTokens: 256,
      temperature: 0.2,
    });

    const facts = extractJSON<string[]>(text);
    return new Response(JSON.stringify({ facts }), {
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  }
});
