// extract-self-facts: pulls 0–5 new "about me" facts from a freshly-saved story.
// Input:  { storyBody: string, existingFacts: string[] }
// Output: { facts: string[] }

import { corsHeaders } from "../_shared/cors.ts";
import { callClaude, extractJSON } from "../_shared/claude.ts";
import { requireUser } from "../_shared/auth.ts";

interface RequestBody {
  storyBody: string;
  existingFacts: string[];
}

const SYSTEM = `You are an assistant that extracts durable personal facts about
THE USER THEMSELVES from a short story or anecdote they jotted down about
something happening in their life.

Rules:
- Only return facts about the USER (the author) that are likely to remain true
  for weeks or months (e.g. "training for marathon", "just got cat Henrietta",
  "started new job at Stripe", "back from Lisbon trip", "engaged to Dani").
- Do NOT include facts about other people. Do NOT include one-off events,
  feelings, plans for a specific date, or single conversations.
- Do NOT include facts already in the existing list (semantic match counts as duplicate).
- LENGTH IS A HARD LIMIT: each fact must be **6 words or fewer AND 45 characters or fewer**.
  These caps are absolute — never exceed them. Cut details, don't truncate them.
  - Good: "training for marathon", "just got cat Henrietta", "engaged to Dani",
    "back from Lisbon trip", "started job at Stripe"
  - Bad (too long, never produce these): "Just got back from a week in Lisbon —
    first time in Europe in five years", "Started training for the Oakland marathon"
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

    const userMessage = `Existing facts about the user:
${body.existingFacts.map((f) => `- ${f}`).join("\n") || "(none)"}

New story:
"""
${body.storyBody}
"""

Return JSON array of new facts about the user (or [] if none).`;

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
