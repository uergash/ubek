-- Screenshot-grade seed data for Friend app.
-- Designed to make the home screen, people page, and profile views feel
-- like a real, lived-in personal CRM for the website's screenshots.
--
-- What you get when you run this for user 2cd68572-da66-4f3e-a99c-759d95b1b440:
--   • 8 people with varied health states (red / yellow / green)
--   • ~75 deep, specific notes spanning the past 14 months
--   • ~55 key facts written like things a real friend would jot down
--   • 18 gifts (mix of wishlist + given, with reactions)
--   • Important dates spread across the next 60 days, plus an anniversary
--     scheduled for TODAY's calendar day so the takeover card fires.
--   • One past-year note dated to today's calendar day (drives "On this day").
--
-- Run as the postgres role (Supabase Studio → SQL editor). Existing data for
-- this user is wiped first so the seed is idempotent.
--
-- After running:
--   1. Sign in to the app as the matching user.
--   2. Pull-to-refresh the home tab to trigger Claude generations
--      (annual summary, nudges, bond line). AI features must be ON.

do $$
declare
  uid uuid := '2cd68572-da66-4f3e-a99c-759d95b1b440';

  -- People ids
  alex_id   uuid := gen_random_uuid();
  priya_id  uuid := gen_random_uuid();
  mom_id    uuid := gen_random_uuid();
  dad_id    uuid := gen_random_uuid();
  sam_id    uuid := gen_random_uuid();
  jules_id  uuid := gen_random_uuid();
  theo_id   uuid := gen_random_uuid();
  maya_id   uuid := gen_random_uuid();

  -- Note ids (kept around so key_facts can cite their source note)
  alex_n1 uuid := gen_random_uuid();
  alex_n2 uuid := gen_random_uuid();
  alex_n3 uuid := gen_random_uuid();
  alex_n4 uuid := gen_random_uuid();
  alex_n5 uuid := gen_random_uuid();
  alex_n6 uuid := gen_random_uuid();
  alex_n7 uuid := gen_random_uuid();
  alex_n8 uuid := gen_random_uuid();
  alex_n9 uuid := gen_random_uuid();
  alex_n10 uuid := gen_random_uuid();

  priya_n1 uuid := gen_random_uuid();
  priya_n2 uuid := gen_random_uuid();
  priya_n3 uuid := gen_random_uuid();
  priya_n4 uuid := gen_random_uuid();
  priya_n5 uuid := gen_random_uuid();
  priya_n6 uuid := gen_random_uuid();
  priya_n7 uuid := gen_random_uuid();
  priya_n8 uuid := gen_random_uuid();

  mom_n1  uuid := gen_random_uuid();
  mom_n2  uuid := gen_random_uuid();
  mom_n3  uuid := gen_random_uuid();
  mom_n4  uuid := gen_random_uuid();
  mom_n5  uuid := gen_random_uuid();
  mom_n6  uuid := gen_random_uuid();
  mom_n7  uuid := gen_random_uuid();
  mom_n8  uuid := gen_random_uuid();
  mom_n9  uuid := gen_random_uuid();
  mom_n10 uuid := gen_random_uuid();
  mom_n11 uuid := gen_random_uuid();
  mom_n12 uuid := gen_random_uuid();
  mom_n13 uuid := gen_random_uuid();
  mom_n14 uuid := gen_random_uuid();
  mom_n15 uuid := gen_random_uuid();
  mom_n16 uuid := gen_random_uuid();
  mom_n17 uuid := gen_random_uuid();
  -- "On this day" memory note for Mom (1 year ago today)
  mom_otd uuid := gen_random_uuid();

  dad_n1 uuid := gen_random_uuid();
  dad_n2 uuid := gen_random_uuid();
  dad_n3 uuid := gen_random_uuid();
  dad_n4 uuid := gen_random_uuid();
  dad_n5 uuid := gen_random_uuid();
  dad_n6 uuid := gen_random_uuid();
  dad_n7 uuid := gen_random_uuid();

  sam_n1 uuid := gen_random_uuid();
  sam_n2 uuid := gen_random_uuid();
  sam_n3 uuid := gen_random_uuid();
  sam_n4 uuid := gen_random_uuid();
  sam_n5 uuid := gen_random_uuid();
  sam_n6 uuid := gen_random_uuid();
  sam_n7 uuid := gen_random_uuid();
  sam_n8 uuid := gen_random_uuid();

  jules_n1 uuid := gen_random_uuid();
  jules_n2 uuid := gen_random_uuid();
  jules_n3 uuid := gen_random_uuid();
  jules_n4 uuid := gen_random_uuid();
  jules_n5 uuid := gen_random_uuid();
  jules_n6 uuid := gen_random_uuid();

  theo_n1 uuid := gen_random_uuid();
  theo_n2 uuid := gen_random_uuid();
  theo_n3 uuid := gen_random_uuid();
  theo_n4 uuid := gen_random_uuid();
  theo_n5 uuid := gen_random_uuid();

  maya_n1 uuid := gen_random_uuid();
  maya_n2 uuid := gen_random_uuid();
  maya_n3 uuid := gen_random_uuid();
  maya_n4 uuid := gen_random_uuid();
  maya_n5 uuid := gen_random_uuid();
  maya_n6 uuid := gen_random_uuid();

  -- Today's calendar values (used for the anniversary date so the takeover
  -- card fires whenever you run the seed).
  todays_month int := extract(month from now())::int;
  todays_day   int := extract(day from now())::int;
begin

-- Wipe any existing seed data for this user
delete from public.people where user_id = uid;

-- ─── People ──────────────────────────────────────────────────────────────
-- Health state derived from days_since_last_interaction vs contact_frequency_days.
--   green:  days < freq
--   yellow: freq <= days < freq * 1.5
--   red:    days >= freq * 1.5
insert into public.people
  (id, user_id, name, relation, avatar_hue, phone, contact_frequency_days, last_interaction_at)
values
  -- Alex: best friend, 14d cadence, 25 days since → red, top nudge candidate
  (alex_id,   uid, 'Alex Rivera',   'Friend',     22, '+14155550142', 14, now() - interval '25 days'),
  -- Priya: sister, 10d cadence, 5 days since → green
  (priya_id,  uid, 'Priya Shah',    'Family',    320, '+14155550118', 10, now() - interval '5 days'),
  -- Mom: 7d cadence, 3 days since → green. Anniversary today.
  (mom_id,    uid, 'Mom',           'Family',     12, '+14155550101',  7, now() - interval '3 days'),
  -- Dad: 7d cadence, 4 days since → green
  (dad_id,    uid, 'Dad',           'Family',    180, '+14155550102',  7, now() - interval '4 days'),
  -- Sam: 21d cadence, 38 days → red, recently engaged
  (sam_id,    uid, 'Sam Okafor',    'Friend',    220, '+14155550175', 21, now() - interval '38 days'),
  -- Jules: 14d cadence, 11 days → yellow
  (jules_id,  uid, 'Jules Tan',     'Friend',    150, '+14155550199', 14, now() - interval '11 days'),
  -- Theo: 30d cadence, 64 days → red, ex-colleague
  (theo_id,   uid, 'Theo Nguyen',   'Colleague', 280, '+14155550161', 30, now() - interval '64 days'),
  -- Maya: 21d cadence, 35 days → red, college roommate
  (maya_id,   uid, 'Maya Chen',     'Friend',     50, '+12125550133', 21, now() - interval '35 days');

-- ─── Notes ───────────────────────────────────────────────────────────────
-- valid interaction_type: Call, Coffee, Drinks, Event, Other

-- ── Mom (15 notes spanning ~14 months, plus 1 "on this day") ──────────────
insert into public.notes (id, person_id, interaction_type, body, created_at) values
  (mom_n1, mom_id, 'Call',
   'Mom called crying — Aunt Sue''s husband Frank passed in his sleep last night. She''s flying out tomorrow to be with Sue. Said Sue isn''t crying yet, "and that''s the part that worries me."',
   now() - interval '430 days'),

  (mom_n2, mom_id, 'Event',
   'Drove up Sunday for the day. Mom walked me through Frank''s eulogy — she stayed up until 4am writing it three times. Made her chickpea salad for lunch and packed me leftovers I forgot in the car.',
   now() - interval '395 days'),

  (mom_otd, mom_id, 'Event',
   'Their 37th anniversary. Took her and Dad to Lupa. She wore the green dress from their honeymoon — still fits, still her favorite. Dad pulled out a Polaroid of them in Capri from their first anniversary; same booth, same wine. The waiter remembered them from last year.',
   (now()::date - interval '1 year') + interval '19 hours'),

  (mom_n4, mom_id, 'Call',
   'Mother''s Day call. The herb kit arrived on time. The basil is "taking forever" but the chives are "aggressive in a good way." She''s already planning what she''ll cook with them.',
   now() - interval '353 days'),

  (mom_n5, mom_id, 'Coffee',
   'Visited for the weekend. Took her to the farmers market — she got sticker shock on the heirloom tomatoes ("eight dollars for two??") and refused on principle. Her own seedlings finally went in the ground Saturday afternoon.',
   now() - interval '330 days'),

  (mom_n6, mom_id, 'Call',
   'Knee hurt all week. She refused to go in for an x-ray. Gardening is making it worse but she won''t stop. I pushed and she changed the subject to my work for ten minutes.',
   now() - interval '290 days'),

  (mom_n7, mom_id, 'Call',
   'Birthday call. She loved the Audubon book Dad picked. "Your father has gotten very sneaky in his old age." She turned 67 and refuses to mention the number.',
   now() - interval '263 days'),

  (mom_n8, mom_id, 'Event',
   'Drove down for Labor Day. Made canning a whole project — 24 jars of marinara from her tomatoes. She gave me 6 and labeled them in her tiny handwriting: "B. 9/21 — basil heavy."',
   now() - interval '218 days'),

  (mom_n9, mom_id, 'Call',
   'She finally agreed to the knee surgery. January 14th. Said the pain in October was the worst it''s been — she couldn''t kneel to weed. Asked me to come help for two weeks after. Of course.',
   now() - interval '180 days'),

  (mom_n10, mom_id, 'Event',
   'Thanksgiving at their place. She did way too much, as always — 14 dishes for 6 people. Dad and I made the pies; I burnt the crust and she just laughed. Sue came too, first holiday without Frank.',
   now() - interval '152 days'),

  (mom_n11, mom_id, 'Event',
   'Christmas. Quiet — knee bothering her, so we did dinner sitting down at the kitchen table instead of the dining room. Watched Holiday Inn for the 20th time. She fell asleep before Bing sang White Christmas.',
   now() - interval '125 days'),

  (mom_n12, mom_id, 'Call',
   'Surgery day. Called from recovery — groggy, said the surgeon told her she''d been "bone-on-bone for years." Of course she had. Dad is staying overnight at the hospital despite her protesting.',
   now() - interval '106 days'),

  (mom_n13, mom_id, 'Event',
   'Stayed with her for 10 days post-op. PT was brutal the first week — she cried twice on Wednesday and apologized for it. By day 8 she was making her own coffee and arguing with the morning news.',
   now() - interval '99 days'),

  (mom_n14, mom_id, 'Call',
   'Six weeks out. She walked to the mailbox and back without the cane. "I had a moment, honey. I think I''m getting my body back." First time she''s sounded like herself in months.',
   now() - interval '63 days'),

  (mom_n15, mom_id, 'Coffee',
   'Drove up Saturday. Walked the lake loop together — half the usual pace but she did the whole thing. Dad cooked. We talked about the anniversary trip; she wants Italy again, but he''s nervous about her knee on cobblestones. Her solution: better shoes.',
   now() - interval '35 days'),

  (mom_n16, mom_id, 'Call',
   'She started watercolor class at the community center. First week — they painted a still life with a pear. She said her pear looks "angry" and Dad laughed for a full minute. She emailed me a photo. Pear is, in fact, angry.',
   now() - interval '14 days'),

  (mom_n17, mom_id, 'Call',
   'Anniversary plans. They''re going to Lupa Friday — same as every year since 2018. She asked me to text Dad and remind him to wear the blue tie. He says I''m a "tattle." He also wore the blue tie.',
   now() - interval '3 days');

-- ── Dad (7 notes) ────────────────────────────────────────────────────────
insert into public.notes (id, person_id, interaction_type, body, created_at) values
  (dad_n1, dad_id, 'Event',
   'Retirement party. Forty utility-crew guys showed up — Frank, Wallace, the whole Tuesday-coffee gang. He couldn''t get through his speech; Frank had to step up and finish it for him. The cake said "Peter — Finally" in his daughter Beth''s handwriting.',
   now() - interval '305 days'),

  (dad_n2, dad_id, 'Call',
   'Six months retired. He said he''s busier than when he was working — workshop, birds, lake walks, a "second pass" of the garage. I think he''s finally ok with it. He''s sleeping eight hours for the first time in 30 years.',
   now() - interval '155 days'),

  (dad_n3, dad_id, 'Event',
   'Christmas. He gave me his old leatherman — the one he''s carried since ''92, scratched up, the screwdriver bent. "You''ll get more use out of it now." I almost cried in front of Mom''s green-bean casserole.',
   now() - interval '125 days'),

  (dad_n4, dad_id, 'Call',
   'Mom mentioned he''s missing parts of conversations. Especially in restaurants. He won''t go in for a hearing test — "It''s the room, not me." I''ll mention it gently next visit, after the anniversary.',
   now() - interval '85 days'),

  (dad_n5, dad_id, 'Call',
   'He made me listen to his bird podcast for twenty minutes. The whole thing about the rufous hummingbird and how it migrates 4,000 miles. I''ve never seen him this enthusiastic about anything that isn''t a furnace.',
   now() - interval '45 days'),

  (dad_n6, dad_id, 'Event',
   'Drove up Saturday. Spent the whole afternoon in his workshop — he''s building a bookcase for Mom for the anniversary. Every single measurement is wrong by 1/16th of an inch. He doesn''t care, and I shouldn''t either.',
   now() - interval '18 days'),

  (dad_n7, dad_id, 'Call',
   'Quick chat. He saw a vermilion flycatcher at the back feeder and texted me a (very blurry) photo. Couldn''t shut up about it. "Sam, those things aren''t supposed to be this far north." Mom was laughing in the background.',
   now() - interval '4 days');

-- ── Alex (10 notes) ──────────────────────────────────────────────────────
insert into public.notes (id, person_id, interaction_type, body, created_at) values
  (alex_n1, alex_id, 'Coffee',
   'Holiday catch-up at Reveille. Things were already weird with Marina — he wouldn''t say it directly, but the way he talked around their Christmas plans gave it away. Said Milo had been limping for weeks. Bought me the espresso.',
   now() - interval '160 days'),

  (alex_n2, alex_id, 'Drinks',
   'Trivia night with the team. We won by half a point on the last music question (he insisted "Hounds of Love" was 1985 and was right). He hadn''t laughed that hard in months — first time I''d seen him out post-Marina rumblings.',
   now() - interval '142 days'),

  (alex_n3, alex_id, 'Call',
   'He told me he and Marina were splitting. Six years. They''d talked it through over Christmas at her parents''. No fight, just "we kept trying to want different things." Said I was the third person he''d told.',
   now() - interval '100 days'),

  (alex_n4, alex_id, 'Event',
   'Birthday weekend trip to Tahoe — was supposed to be him + Marina. We went ahead with the boys, three of us instead of four. He held it together on the lift then unraveled at dinner over the third bottle of red. It was a good unraveling.',
   now() - interval '88 days'),

  (alex_n5, alex_id, 'Coffee',
   'First post-breakup catch-up just the two of us. He looked tired but better. Said the apartment feels too big. We walked four miles around the park, mostly quiet. Milo was officially scheduled for the knee surgery — $4k.',
   now() - interval '70 days'),

  (alex_n6, alex_id, 'Other',
   'Texted to say Milo''s surgery went well. He sent a video of Milo trying to scratch with the cone on. "Best four thousand dollars I have ever spent in my entire life."',
   now() - interval '60 days'),

  (alex_n7, alex_id, 'Other',
   'Sent him the new La Marzocco recommendation — Linea Mini bundle on sale at Clive. He said he''s been eyeing the Linea Mini for over a year. Will he buy it? No. Will he keep talking about it? Yes.',
   now() - interval '55 days'),

  (alex_n8, alex_id, 'Call',
   'Quick call on his walk home. Mentioned his brother Marco is moving back from Lisbon in October — they''re thinking about a road trip up the Highway 1 coast together when he''s settled. First time he''s sounded excited about a future plan since the breakup.',
   now() - interval '40 days'),

  (alex_n9, alex_id, 'Coffee',
   'Caught up at Reveille. Milo is fully recovered after the knee surgery — running again, jumping into the back of the car. Alex is six weeks out from the Oakland triathlon and still hasn''t fixed his bike fit. We talked about Marina for the first time since February — he''s genuinely doing better.',
   now() - interval '25 days'),

  (alex_n10, alex_id, 'Other',
   'Sent him the bike fit appointment link at Above Category. He confirmed he''ll book "next week" which is Alex code for "in three weeks." Triathlon is in 18 days.',
   now() - interval '24 days');

-- ── Priya (8 notes) ──────────────────────────────────────────────────────
insert into public.notes (id, person_id, interaction_type, body, created_at) values
  (priya_n1, priya_id, 'Call',
   'She got the offer from UCSF. Crying laughing on the phone. Eight years of trying to get to the West Coast — she kept saying "I can finally pick the kids up from school in shorts in February." Devan is going to negotiate down to a 4-day at his firm.',
   now() - interval '105 days'),

  (priya_n2, priya_id, 'Event',
   'Visited them in Brooklyn one last time before the move. Took the twins to the carousel in Prospect Park. Maya kept trying to climb onto the giraffe; Ari refused to ride anything that moved. Devan made his pasta — the one with the lemon.',
   now() - interval '76 days'),

  (priya_n3, priya_id, 'Call',
   'Last call before the move. She''s terrified about the twins changing daycares mid-year. I told her they''ll be fine in a week. (They were. Maya already has a best friend named Rio.)',
   now() - interval '53 days'),

  (priya_n4, priya_id, 'Call',
   'Move was brutal. Movers showed up 8 hours late, broke the arm off her grandmother''s armchair. She cried in the bathroom and then carried on. Devan says the mover''s insurance "doesn''t cover sentimental." She''s trying to find a chair restorer in the Bay.',
   now() - interval '38 days'),

  (priya_n5, priya_id, 'Other',
   'Sent her Orbital. She said she''s reading more fiction lately to balance the day job — "I need someone else''s sentences in my head before I sleep." Asked me for one more rec — sent her The Bee Sting.',
   now() - interval '21 days'),

  (priya_n6, priya_id, 'Coffee',
   'Drove down to Berkeley. She made me lunch in their tiny new kitchen — every cabinet is a foot too high for her. Twins were obsessed with my watch. The yard is half the size of Brooklyn but Devan''s already drawn raised-bed plans on graph paper. He was so proud of the graph paper.',
   now() - interval '14 days'),

  (priya_n7, priya_id, 'Call',
   'Long Sunday call. House mostly unpacked. The twins keep asking when Grandma is visiting (Mom''s knee — soon). Devan loves the new commute — he can finally bike to work. Priya started her UCSF orientation Wednesday and got lost three times in the parking garage.',
   now() - interval '5 days'),

  (priya_n8, priya_id, 'Other',
   'She sent a video — Maya doing her first cartwheel on the new lawn. Ari watched and announced "I will not be doing that, thank you." Sounds like Devan.',
   now() - interval '2 days');

-- ── Sam (8 notes) ────────────────────────────────────────────────────────
insert into public.notes (id, person_id, interaction_type, body, created_at) values
  (sam_n1, sam_id, 'Coffee',
   'He asked me about my proposal — what worked, what I''d change. Knew right then he was going to. Said he''d been carrying the question for "way longer than I''d like to admit." Wanted to know how I knew Dani would say yes. (She''s going to say yes.)',
   now() - interval '350 days'),

  (sam_n2, sam_id, 'Event',
   'Camping in Pinnacles with the group. He made us a four course meal on a Coleman stove. Course three was somehow sushi. Course four was a tarte tatin in a cast iron skillet over coals. We have to stop letting him cook outdoors, it''s humiliating.',
   now() - interval '245 days'),

  (sam_n3, sam_id, 'Call',
   'Dani''s promotion came through — director of strategy. He sounded more excited than she did. He''s already secretly planning a celebration dinner that she "doesn''t need to know about" so he can make her favorite duck.',
   now() - interval '175 days'),

  (sam_n4, sam_id, 'Event',
   'His firm''s holiday party. Met his new senior engineer Hannah. The whole table got into a 90 minute argument about React vs Vue and Sam refused to step in even though he had clear opinions. Dani threatened to leave us all there at the bar. We deserved it.',
   now() - interval '125 days'),

  (sam_n5, sam_id, 'Coffee',
   'He brought me a jar of his koji-aged butter. It is genuinely incredible. It is also slightly alarming. He''s now talking about "miso''ing his spare apartment." His landlord does not know.',
   now() - interval '95 days'),

  (sam_n6, sam_id, 'Drinks',
   'He told me he was going to propose — showed me the ring at the bar. Emerald cut, Dani''s grandmother''s stone, reset by a jeweler in Oakland he found on Instagram. Tahoe in two weeks. He hasn''t told anyone else. I bought the bourbon.',
   now() - interval '78 days'),

  (sam_n7, sam_id, 'Call',
   'He asked me to be a groomsman. Tried to play it cool. I didn''t play it cool. Wedding is Sintra, April 2027 — Dani''s mom''s family is from Lisbon. Three months of trying to keep this secret from me, Sam.',
   now() - interval '52 days'),

  (sam_n8, sam_id, 'Other',
   'PROPOSED. She said yes. They''re thinking Sintra in April 2027. He''s been making koji at home and is now threatening to bring me a jar at the engagement party. I will accept the jar. Cautiously.',
   now() - interval '38 days');

-- ── Jules (6 notes) ──────────────────────────────────────────────────────
insert into public.notes (id, person_id, interaction_type, body, created_at) values
  (jules_n1, jules_id, 'Coffee',
   'She admitted she hates the hospital admin job. Knew six months ago. PT plan still vague — said she "needs the right doorway." Leon (the corgi) sat under the table the whole time and judged us.',
   now() - interval '180 days'),

  (jules_n2, jules_id, 'Event',
   'Bishop trip last fall, photos finally up on her Strava. She sent the V5 problem they''d been working two seasons — fell off it 19 times across two trips. Posted "I am not unbroken." She sent it on the 20th try.',
   now() - interval '120 days'),

  (jules_n3, jules_id, 'Drinks',
   'She and Kara had their second-anniversary dinner. She got Kara a custom Polaroid book of every climbing trip they''ve done. Kara cried at the bookmark page (June 2024 — the day the corgi tore his cruciate).',
   now() - interval '74 days'),

  (jules_n4, jules_id, 'Event',
   'Climbed Mission Cliffs. She fell off the same V5 problem six times and then sent it on the seventh try. The whole gym clapped. She bowed. She is incorrigible. We got tacos.',
   now() - interval '45 days'),

  (jules_n5, jules_id, 'Coffee',
   'She told me she finally pulled the trigger on leaving the hospital admin job — her last day was Friday. Took three months to decide. Said the calendar feels different now: "I keep waiting to be in trouble." Starting PT full time next Tuesday.',
   now() - interval '28 days'),

  (jules_n6, jules_id, 'Event',
   'Climbed at Dogpatch. She''s working a V6 at Bishop next month — first one she''s genuinely scared of. Switched to PT full-time last week — loving the schedule, says she has time to "think" again. Asked about Mom''s knee, sent over three exercises she swears by.',
   now() - interval '11 days');

-- ── Theo (5 notes) ───────────────────────────────────────────────────────
insert into public.notes (id, person_id, interaction_type, body, created_at) values
  (theo_n1, theo_id, 'Coffee',
   'He told me about his oldest having reading trouble — long talk about whether we lean too hard on screens, whether the trouble is age or attention or the second baby right when she hit kindergarten. He''s reading her Frog and Toad every night. Eight months in.',
   now() - interval '350 days'),

  (theo_n2, theo_id, 'Drinks',
   'He brought Ellen out — first time meeting her. She''s funnier than he is. Forty minutes of public-defender stories I''m still thinking about. Theo just stared at her like he''d lucked into something he doesn''t deserve. He has.',
   now() - interval '245 days'),

  (theo_n3, theo_id, 'Event',
   'Jeff''s leaving party at Notion. Theo and I closed down the bar with Jeff arguing about whether ML or rules-based ever stops being needed. Three years of this argument. None of us is ever going to win it.',
   now() - interval '155 days'),

  (theo_n4, theo_id, 'Call',
   'He told me he was leaving Notion. Two years there. The new co-founder is from his Stanford program — already raised the angel round. He''d been quietly building the prototype on weekends since November. I had no idea.',
   now() - interval '98 days'),

  (theo_n5, theo_id, 'Coffee',
   'Last day at Notion. He''s starting something in clinical AI — wants nurses, not doctors, because "nurses know the gaps and nobody''s building for them." Last raise round was tough — "two no''s for every yes" — but they got there. Seed announcing in March.',
   now() - interval '64 days');

-- ── Maya (6 notes) ───────────────────────────────────────────────────────
insert into public.notes (id, person_id, interaction_type, body, created_at) values
  (maya_n1, maya_id, 'Coffee',
   'She came up for a long weekend, just her — left Wes with Quinn for the first time. We walked the Embarcadero then sat on a bench at Pier 14 for two hours. Talked about whether either of us would have done college differently. She wouldn''t. I might have.',
   now() - interval '352 days'),

  (maya_n2, maya_id, 'Call',
   'Henrietta''s vet bill. $2,300. The cat is fourteen, weighs nineteen pounds, and was diagnosed with "minor heart issues, mostly stress." Maya is still mad. Henrietta is fine. Quinn calls her "Mama Cat."',
   now() - interval '247 days'),

  (maya_n3, maya_id, 'Event',
   'Came to SF for the publishing conference. Stayed with us four nights. Quinn fell asleep in our hammock under the lemon tree — Wes got the photo on his phone. He met all my friends and remembered every name including pets.',
   now() - interval '155 days'),

  (maya_n4, maya_id, 'Call',
   'She and Wes are talking about leaving Brooklyn. Schools, space, the rent. Hudson Valley keeps coming up. Wes wants a yard, she wants a porch. They''re going to look at three towns next month.',
   now() - interval '92 days'),

  (maya_n5, maya_id, 'Other',
   'Quinn turned 2. Sent her the board book Mr. Tiger Goes Wild — Maya sent a video of Quinn yelling "BOOK BOOK BOOK" on a loop. Best 6 seconds of footage that has ever existed.',
   now() - interval '57 days'),

  (maya_n6, maya_id, 'Call',
   'She told me she got the senior editor role. Six years building up to it. Her boss Eleanor cried at the announcement. Maya cried at the bathroom afterwards, then cried again on our call. She''s already worried about losing time with Quinn — talked through how Wes will rearrange Tuesdays.',
   now() - interval '35 days');

-- ─── Key facts ───────────────────────────────────────────────────────────
-- These are the seed for Claude prompts (nudges, bond line, summaries) AND
-- the fallback content when Claude is off. Written like things a friend
-- would actually jot down — specific, dated where useful.

insert into public.key_facts (person_id, text, source_note_id) values
  -- All facts kept ≤ ~45 chars / ~6 words so chips fit on one line.
  -- Mom (10 facts — anchors anniversary card and spotlight)
  (mom_id, 'Married Dad April 30, 1988',                                                          mom_otd),
  (mom_id, 'Recovering from knee replacement',                                                    mom_n14),
  (mom_id, 'Cans marinara every September',                                                       mom_n8),
  (mom_id, 'Takes weekly watercolor classes',                                                     mom_n16),
  (mom_id, 'Wears green dress every anniversary',                                                 mom_otd),
  (mom_id, 'Lupa on 9th is her tradition',                                                        mom_n17),
  (mom_id, 'Best friend Sue widowed Feb 2025',                                                    mom_n1),
  (mom_id, 'Wants Dad back in Italy this fall',                                                   mom_n15),
  (mom_id, 'Reads every evening before bed',                                                      null),
  (mom_id, 'Worried about Dad''s hearing',                                                        mom_n4),

  -- Dad (7 facts)
  (dad_id, 'Retired June 2025 after 38 years',                                                    dad_n1),
  (dad_id, 'Building Mom a bookcase for the anniversary',                                         dad_n6),
  (dad_id, 'Obsessed with backyard birding',                                                      dad_n7),
  (dad_id, 'Gave me his ''92 leatherman last Christmas',                                          dad_n3),
  (dad_id, 'Goes to the diner solo Fridays',                                                      null),
  (dad_id, 'Won''t admit he needs hearing aids',                                                  dad_n4),
  (dad_id, 'Sleeps 8 hours nightly since retiring',                                               dad_n2),

  -- Alex (8 facts)
  (alex_id, 'Has a golden named Milo',                                                            alex_n6),
  (alex_id, 'Training for Oakland Triathlon (May 18)',                                            alex_n9),
  (alex_id, 'Works at Stripe (product team)',                                                     null),
  (alex_id, 'Wants a Linea Mini espresso machine',                                                alex_n7),
  (alex_id, 'Brother Marco moves to Bay in October',                                              alex_n8),
  (alex_id, 'Broke up with Marina in February',                                                   alex_n3),
  (alex_id, 'Always 5 minutes late',                                                              null),
  (alex_id, 'Planning Highway 1 road trip with Marco',                                            alex_n8),

  -- Priya (7 facts)
  (priya_id, 'Twins Ari and Maya turn 3 on June 4',                                                null),
  (priya_id, 'Moved Brooklyn to Berkeley (Mar 2026)',                                              priya_n1),
  (priya_id, 'Husband Devan bikes to work now',                                                    priya_n7),
  (priya_id, 'Reading more fiction lately',                                                        priya_n5),
  (priya_id, 'Maya cartwheels; Ari refuses',                                                       priya_n8),
  (priya_id, 'Looking for a chair restorer in the Bay',                                            priya_n4),
  (priya_id, 'Vegetarian; allergic to shellfish',                                                  null),

  -- Sam (7 facts)
  (sam_id, 'Engaged to Dani in Tahoe (Mar 2026)',                                                  sam_n8),
  (sam_id, 'Ring is Dani''s grandmother''s emerald',                                               sam_n6),
  (sam_id, 'Wedding April 2027 in Sintra',                                                         sam_n8),
  (sam_id, 'I am a groomsman',                                                                     sam_n7),
  (sam_id, 'Deep into koji and miso fermentation',                                                 sam_n5),
  (sam_id, 'Engagement party May 3 at his place',                                                  null),
  (sam_id, 'Refuses to replace his 2008 Subaru',                                                   null),

  -- Jules (6 facts)
  (jules_id, 'Working a V6 at Bishop next month',                                                  jules_n6),
  (jules_id, 'Switched to PT full-time recently',                                                  jules_n5),
  (jules_id, 'Partner Kara is a pediatric resident',                                               jules_n3),
  (jules_id, 'Owns the corgi Leon',                                                                jules_n3),
  (jules_id, 'Sent PT exercises for Mom''s knee',                                                  jules_n6),
  (jules_id, 'Cannot drink coffee after 11 AM',                                                    null),

  -- Theo (6 facts)
  (theo_id, 'Left Notion in January for a startup',                                                theo_n5),
  (theo_id, 'Building clinical AI tools for nurses',                                               theo_n5),
  (theo_id, 'Seed round announced in March',                                                       theo_n4),
  (theo_id, 'Wife Ellen is a public defender',                                                     theo_n2),
  (theo_id, 'Three kids; oldest in early reading',                                                 theo_n1),
  (theo_id, 'Pickup basketball Tue/Thu lunch',                                                     null),

  -- Maya (6 facts)
  (maya_id, 'College roommate at Brown',                                                           null),
  (maya_id, 'Just promoted to senior editor',                                                      maya_n6),
  (maya_id, 'Husband Wes teaches high school history',                                             maya_n3),
  (maya_id, 'Daughter Quinn turned 2 in March',                                                    maya_n5),
  (maya_id, 'Cat Henrietta is 14 and high-strung',                                                 maya_n2),
  (maya_id, 'Looking at Hudson Valley towns',                                                      maya_n4);

-- ─── Important dates ─────────────────────────────────────────────────────
-- The anniversary uses today's calendar values so the home takeover card
-- always fires. Other dates are spread across the next 60 days for upcoming.

insert into public.important_dates
  (person_id, kind, label, date_month, date_day, remind, remind_days_before)
values
  -- TODAY → fires the takeover anniversary card
  (mom_id,   'anniversary', 'Wedding anniversary — Dad',  todays_month, todays_day, true, 3),
  (mom_id,   'birthday',    'Birthday',                   8,  9,  true, 1),
  (mom_id,   'custom',      'Knee surgery anniversary',   1,  14, false, 1),

  (dad_id,   'birthday',    'Birthday',                   11, 23, true, 1),
  (dad_id,   'custom',      'Retirement anniversary',     6,  30, false, 0),

  (alex_id,  'birthday',    'Birthday',                   5,  14, true, 1),
  (alex_id,  'custom',      'Oakland Triathlon',          5,  18, true, 3),
  (alex_id,  'anniversary', 'Started at Stripe',          9,  2,  false, 1),

  (priya_id, 'birthday',    'Birthday',                   8,  22, true, 1),
  (priya_id, 'custom',      'Twins'' birthday',           6,  4,  true, 7),

  (sam_id,   'custom',      'Engagement party',           5,  3,  true, 3),
  (sam_id,   'birthday',    'Birthday',                   11, 11, true, 1),

  (jules_id, 'birthday',    'Birthday',                   10, 30, true, 1),

  (theo_id,  'birthday',    'Birthday',                   3,  15, true, 1),

  (maya_id,  'birthday',    'Birthday',                   7,  20, true, 1),
  (maya_id,  'custom',      'Quinn''s birthday',          3,  18, true, 7);

-- ─── Gifts ───────────────────────────────────────────────────────────────
-- Year-of-given gifts power the giftCount stat on the anniversary takeover.
-- Mom gets 3 within the past year so the stat reads honestly.

insert into public.gifts (person_id, name, note, status, occasion, given_date, reaction) values
  -- Mom — wishlist + 3 given in past year
  (mom_id, 'Audubon Birds of North America (large format)',
            'She''s sketching the chickadees at the feeder — wants the proper field guide',
            'wishlist', null, null, null),
  (mom_id, 'Italy travel guide (Capri + Amalfi)',
            'For the anniversary trip in the fall — she''s anxious about her knee but wants it',
            'wishlist', null, null, null),
  (mom_id, 'Anniversary roses + Lupa dinner certificate',
            null, 'given', 'Anniversary 2025',
            (current_date - interval '365 days')::date, 'loved'),
  (mom_id, 'Mother''s Day herb kit',
            'Basil, chives, mint — to replace the windowsill basil that always dies',
            'given', 'Mother''s Day 2025',
            (current_date - interval '352 days')::date, 'loved'),
  (mom_id, 'Cashmere throw (post-surgery)',
            'For the long weeks on the couch — she said "this is the softest thing I''ve owned"',
            'given', 'Knee surgery, January 2026',
            (current_date - interval '105 days')::date, 'loved'),

  -- Dad
  (dad_id, 'Sibley birds field guide (regional supplement)',
            'He''s working through the eastern guide; this fills in the western birds',
            'wishlist', null, null, null),
  (dad_id, 'New leatherman (replacement)',
            'He gave me his old one at Christmas — overdue to give him one of his own',
            'wishlist', null, null, null),
  (dad_id, 'Bird-feeder camera',
            null, 'given', 'Father''s Day 2025',
            (current_date - interval '320 days')::date, 'loved'),

  -- Alex
  (alex_id, 'Linea Mini espresso machine',
            'He''s been talking about it for over a year. Suspect he''ll never buy it himself.',
            'wishlist', null, null, null),
  (alex_id, 'Bike fit session at Above Category',
            'Mentioned his hips are stiff after long rides — must use before triathlon',
            'wishlist', null, null, null),
  (alex_id, 'Hario V60 + Origin beans',
            null, 'given', 'Birthday 2025',
            (current_date - interval '345 days')::date, 'loved'),

  -- Priya
  (priya_id, 'Twin balance bikes',
             'For their June birthday — Devan vetoed pedal bikes "for one more year"',
             'wishlist', null, null, null),
  (priya_id, 'Chair restorer gift card',
             'For grandmother''s armchair — broken in the move',
             'wishlist', null, null, null),

  -- Sam
  (sam_id, 'Donabe rice pot',
           'For all the fermentation experiments — he''s been eyeing one',
           'wishlist', null, null, null),
  (sam_id, 'Engagement bourbon (Eagle Rare 17)',
           null, 'given', 'Engagement 2026',
           (current_date - interval '37 days')::date, 'loved'),

  -- Jules
  (jules_id, 'New climbing shoes (TC Pro)',
             'Hers are blown out — she''s been resoling for two seasons',
             'wishlist', null, null, null),

  -- Theo
  (theo_id, 'Frog and Toad complete collection (hardback)',
            'For his daughter — they read it nightly',
            'wishlist', null, null, null),

  -- Maya
  (maya_id, 'Mr. Tiger Goes Wild board book',
            null, 'given', 'Quinn''s 2nd birthday',
            (current_date - interval '57 days')::date, 'loved');

-- ─── Done ────────────────────────────────────────────────────────────────
-- Refresh last_interaction_at to match the most recent note for each
-- person. The trigger normally handles this, but our explicit timestamps
-- in the notes insert mean the trigger only sees them in order — this
-- guarantees the latest one wins regardless of insert ordering above.
update public.people p
   set last_interaction_at = sub.last_at
  from (select person_id, max(created_at) as last_at
          from public.notes
          where person_id in
            (select id from public.people where user_id = uid)
         group by person_id) sub
 where p.id = sub.person_id;

raise notice 'Seeded 8 people, ~75 notes, 55 facts, 18 gifts, 16 dates for user %.', uid;
raise notice 'Anniversary date set for month=%, day=% (today). Pull-to-refresh Home to fire the takeover card.',
  todays_month, todays_day;
end $$;
