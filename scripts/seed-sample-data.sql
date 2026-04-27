-- Sample data for Friend app. Run as postgres (bypasses RLS).
-- Replaces any prior people/notes/etc for the target user, then inserts a
-- realistic set of 6 friends, family members, and colleagues with notes,
-- facts, gifts, and dates spread across health states.

do $$
declare
  uid uuid := '2cd68572-da66-4f3e-a99c-759d95b1b440';
  alex_id uuid := gen_random_uuid();
  priya_id uuid := gen_random_uuid();
  mom_id uuid := gen_random_uuid();
  sam_id uuid := gen_random_uuid();
  jules_id uuid := gen_random_uuid();
  theo_id uuid := gen_random_uuid();

  -- helper note ids so we can attach key facts to specific notes
  alex_n1 uuid := gen_random_uuid();
  alex_n2 uuid := gen_random_uuid();
  alex_n3 uuid := gen_random_uuid();
  priya_n1 uuid := gen_random_uuid();
  priya_n2 uuid := gen_random_uuid();
  mom_n1 uuid := gen_random_uuid();
  sam_n1 uuid := gen_random_uuid();
  jules_n1 uuid := gen_random_uuid();
  theo_n1 uuid := gen_random_uuid();
begin

-- Wipe any existing seed data for this user
delete from public.people where user_id = uid;

-- ─── People ──────────────────────────────────────────────────────────────
insert into public.people (id, user_id, name, relation, avatar_hue, contact_frequency_days, last_interaction_at) values
  (alex_id,  uid, 'Alex Rivera',   'Friend',    22,  14, now() - interval '21 days'),  -- red
  (priya_id, uid, 'Priya Shah',    'Family',    320, 10, now() - interval '5 days'),   -- green
  (mom_id,   uid, 'Mom',           'Family',    12,  7,  now() - interval '3 days'),   -- green
  (sam_id,   uid, 'Sam Okafor',    'Friend',    220, 21, now() - interval '38 days'),  -- red
  (jules_id, uid, 'Jules Tan',     'Friend',    150, 14, now() - interval '11 days'),  -- yellow
  (theo_id,  uid, 'Theo Nguyen',   'Colleague', 280, 30, now() - interval '64 days');  -- red

-- ─── Notes ───────────────────────────────────────────────────────────────
insert into public.notes (id, person_id, interaction_type, body, created_at) values
  (alex_n1, alex_id, 'Coffee',
   'Caught up at Reveille. Milo is fully recovered after the knee surgery — Alex called it "the best $4k I''ve ever spent." He''s six weeks out from the Oakland triathlon and still hasn''t fixed his bike fit.',
   now() - interval '21 days'),
  (alex_n2, alex_id, 'Call',
   'Quick call on his walk home. Mentioned his brother is moving back from Lisbon in the fall and they''re thinking about a road trip up the coast in October.',
   now() - interval '40 days'),
  (alex_n3, alex_id, 'Text',
   'Sent him the new La Marzocco recommendation. He said he''d been eyeing the Linea Mini for a year.',
   now() - interval '55 days'),

  (priya_n1, priya_id, 'Call',
   'Long Sunday call. House is mostly unpacked. The twins keep asking when Grandma is visiting. Devan loves the new commute — he can finally bike to work.',
   now() - interval '5 days'),
  (priya_n2, priya_id, 'Text',
   'Sent her Orbital. She said she''s reading more fiction lately to balance the day job.',
   now() - interval '20 days'),

  (mom_n1, mom_id, 'Call',
   'Knee is at 95%. She walked to the farmers market and back on Saturday. Tomato plants are doing great this year.',
   now() - interval '3 days'),

  (sam_n1, sam_id, 'Text',
   'PROPOSED. She said yes. They''re thinking Sintra in April 2027. He''s been making koji at home and threatening to bring me a jar.',
   now() - interval '38 days'),

  (jules_n1, jules_id, 'Event',
   'Climbed at Dogpatch. She''s working a V6 at Bishop next month. Switched to PT full-time last week — loving the schedule.',
   now() - interval '11 days'),

  (theo_n1, theo_id, 'Coffee',
   'Last day at Notion. He''s starting something in clinical AI — wants nurses, not doctors. Last raise round was tough but they got there.',
   now() - interval '64 days');

-- ─── Key facts ───────────────────────────────────────────────────────────
insert into public.key_facts (person_id, text, source_note_id) values
  (alex_id, 'Has a dog named Milo',                alex_n1),
  (alex_id, 'Training for the Oakland triathlon',  alex_n1),
  (alex_id, 'Works at Stripe',                     null),
  (alex_id, 'Loves single-origin coffee',          alex_n3),
  (alex_id, 'Brother lives in Lisbon',             alex_n2),
  (alex_id, 'Wants a Linea Mini espresso machine', alex_n3),

  (priya_id, 'Twins turn 3 in June',         null),
  (priya_id, 'Just moved to Berkeley',       priya_n1),
  (priya_id, 'Reading more fiction lately',  priya_n2),
  (priya_id, 'Husband Devan bikes to work',  priya_n1),

  (mom_id, 'Garden is her happy place',  mom_n1),
  (mom_id, 'Recovering from knee surgery in January', null),

  (sam_id, 'Just got engaged to Dani',     sam_n1),
  (sam_id, 'Wedding in Sintra April 2027', sam_n1),
  (sam_id, 'Deep into fermentation / koji', sam_n1),

  (jules_id, 'Climbing project: V6 at Bishop',    jules_n1),
  (jules_id, 'Switched to PT full-time',          jules_n1),

  (theo_id, 'Left Notion to start a company', theo_n1),
  (theo_id, 'Working on AI for nurses',       theo_n1);

-- ─── Important dates ─────────────────────────────────────────────────────
-- Use months/days that produce upcoming dates over the next ~60 days.
insert into public.important_dates (person_id, kind, label, date_month, date_day, remind, remind_days_before) values
  (alex_id,  'birthday',    'Birthday',         5,  14, true, 1),
  (alex_id,  'anniversary', 'Started at Stripe', 9, 2,  false, 1),
  (alex_id,  'custom',      'Oakland Triathlon', 5, 18, true, 3),

  (priya_id, 'birthday', 'Birthday',     8, 22, true, 1),
  (priya_id, 'custom',   'Twins'' birthday', 6, 4, true, 7),

  (mom_id, 'birthday', 'Birthday', 7, 9, true, 1),

  (sam_id, 'birthday', 'Birthday',         11, 11, true, 1),
  (sam_id, 'custom',   'Engagement party', 5,  3, true, 3),

  (jules_id, 'birthday', 'Birthday', 10, 30, true, 1),

  (theo_id, 'birthday', 'Birthday', 3, 15, true, 1);

-- ─── Gifts ───────────────────────────────────────────────────────────────
insert into public.gifts (person_id, name, note, status, occasion, given_date, reaction) values
  (alex_id, 'Linea Mini espresso machine',
            'He''s been talking about it for over a year', 'wishlist', null, null, null),
  (alex_id, 'Bike fit session at Above Category',
            'Mentioned his hips are stiff after long rides', 'wishlist', null, null, null),
  (alex_id, 'Hario V60 + Origin beans',
            null, 'given', 'Birthday 2025', current_date - interval '345 days', 'loved'),

  (priya_id, 'Twin balance bikes',
             'For their June birthday', 'wishlist', null, null, null),

  (mom_id, 'Indoor herb garden kit',
           'Said her windowsill basil keeps dying', 'wishlist', null, null, null),

  (sam_id, 'Donabe rice pot',
           'For all the fermentation experiments', 'wishlist', null, null, null);

-- ─── Done ────────────────────────────────────────────────────────────────
raise notice 'Seeded 6 people, 9 notes, 19 key facts, 10 dates, 6 gifts for user %', uid;
end $$;
