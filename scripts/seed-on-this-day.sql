-- Seed three notes dated to today's calendar day in past years, so the
-- "On this day" section on Home has something to surface. Run today
-- (2026-04-25); the dates are hard-coded to that.
--
-- Substitute your account's email if it isn't the one below.

do $$
declare
  uid uuid := (select id from auth.users where email = 'ubek.ergashev@gmail.com' limit 1);
  p1 uuid;
  p2 uuid;
  p3 uuid;
begin
  if uid is null then
    raise exception 'No auth user found for that email — update the email in this script.';
  end if;

  -- Pick the three people created earliest under this account so the seed
  -- always lands on the same rows on a fresh install.
  select id into p1 from public.people where user_id = uid order by created_at limit 1;
  select id into p2 from public.people where user_id = uid order by created_at offset 1 limit 1;
  select id into p3 from public.people where user_id = uid order by created_at offset 2 limit 1;

  if p1 is null or p2 is null or p3 is null then
    raise exception 'You need at least 3 people in your account to seed this.';
  end if;

  -- 1 year ago today
  insert into public.notes (id, person_id, interaction_type, body, created_at)
  values (
    gen_random_uuid(), p1, 'Coffee',
    'Caught up at our usual spot — they were just back from Lisbon and full of stories about the rooftop concerts and the tile museum.',
    '2025-04-25 14:30:00+00'
  );

  -- 2 years ago today
  insert into public.notes (id, person_id, interaction_type, body, created_at)
  values (
    gen_random_uuid(), p2, 'Call',
    'Long phone catch-up while they walked their dog. Talked about a promotion coming up and their sister''s wedding plans.',
    '2024-04-25 19:15:00+00'
  );

  -- 3 years ago today
  insert into public.notes (id, person_id, interaction_type, body, created_at)
  values (
    gen_random_uuid(), p3, 'Event',
    'Bumped into them at the gallery opening. They mentioned starting at the new firm next month and asked if I''d still be in town for the summer.',
    '2023-04-25 21:00:00+00'
  );

  raise notice 'Seeded "On this day" notes for 3 people across 2025, 2024, 2023.';
end $$;
