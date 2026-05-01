// extract-gift-ideas: scans a note for concrete, durable gift signals about
// the person and proposes wishlist additions ("he's been eyeing a Linea Mini
// for over a year" → { name: "Linea Mini espresso machine", note: "..." }).
//
// Input:  { noteBody, personName, existingGifts: string[] }
// Output: { gifts: Array<{ name: string, note: string }> }

import { corsHeaders } from "../_shared/cors.ts";
import { callClaude, extractJSON } from "../_shared/claude.ts";
import { requireUser } from "../_shared/auth.ts";

interface RequestBody {
  noteBody: string;
  personName: string;
  existingGifts: string[];
}

const SYSTEM = `You read short personal notes and extract CONCRETE, DURABLE
gift ideas for the specific person the note is about. The user is logging an
interaction; your job is to surface real wishlist additions — not just things
mentioned in passing.

Output: JSON array of objects with two fields:
- "name": short, buyable item name (max ~10 words). Specific enough that the
  user could actually shop for it. Examples: "Linea Mini espresso machine",
  "TC Pro climbing shoes", "Sibley western birds field guide".
- "note": one short sentence (max ~14 words) explaining why this is a gift
  idea, grounded in what the note says. Examples: "He's been eyeing one for
  over a year", "Hers are blown out — has been resoling for two seasons".

Strict signal rules — only include something if AT LEAST ONE is true:
- The person explicitly said they want / are saving for / have been eyeing it.
- They mentioned a specific item by name and showed real interest in it.
- They have a clear, concrete need that maps to a specific buyable item
  (e.g. their climbing shoes are blown out → new climbing shoes).

Skip:
- Generic categories with no specificity ("something cozy", "a book").
- One-off mentions where interest isn't clear (they had pasta for dinner).
- Things they already own and are happy with.
- Experiences / trips / restaurants — only physical items or gift cards
  for a clearly named place tied to a stated need.
- Anything already in the existing-gifts list (semantic match — same idea
  even if worded differently counts as a duplicate; do NOT re-suggest).
- Items that would be gifts for someone OTHER than the person the note is
  about (their kid, their partner, etc.). Only gifts for ${"{person}"}.

Return [] when there's no concrete durable signal. Output JUST the JSON
array, no prose, no markdown fences.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    await requireUser(req);
    const body = (await req.json()) as RequestBody;

    const userMessage = `Person: ${body.personName}
Existing gifts (wishlist + already given — do NOT re-suggest):
${body.existingGifts.map((g) => `- ${g}`).join("\n") || "(none)"}

Note:
"""
${body.noteBody}
"""

Return JSON array of gift ideas (or [] if none).`;

    const text = await callClaude({
      system: SYSTEM.replace("${person}", body.personName),
      messages: [{ role: "user", content: userMessage }],
      maxTokens: 400,
      temperature: 0.3,
    });

    const parsed = extractJSON<Array<{ name?: unknown; note?: unknown }>>(text);
    const gifts = Array.isArray(parsed)
      ? parsed
          .map((g) => ({
            name: typeof g.name === "string" ? g.name.trim() : "",
            note: typeof g.note === "string" ? g.note.trim() : "",
          }))
          .filter((g) => g.name.length > 0)
      : [];

    return new Response(JSON.stringify({ gifts }), {
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  }
});
