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
- Only return facts likely to remain true for weeks or months
  (e.g. "has a dog named Milo", "trains for triathlons", "works at Stripe").
- Do NOT include one-off events, plans for a specific date, or things the user did.
- Do NOT include facts already in the existing list (semantic match counts as duplicate).
- LENGTH IS A HARD LIMIT: each fact must be **6 words or fewer AND 45 characters or fewer**.
  These caps are absolute — never exceed them. Cut details, don't truncate them.
  - Good: "has a dog named Milo", "trains for triathlons", "works at Stripe",
    "engaged to Dani", "wedding April 2027 in Sintra"
  - Bad (too long, never produce these): "Wedding April 2027 in Sintra, Portugal — Dani's
    family is from Lisbon", "Recovering from knee replacement, walks the lake again"
- Style: present tense, no period at the end, no quotes, no lists of proper nouns.
- If a fact is interesting but won't fit in 45 chars, split it into two short facts
  or drop the secondary detail. NEVER write a long fact.
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
