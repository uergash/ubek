-- Add note_group_id to notes so a single capture (e.g. an event with several
-- people) can be duplicated as one row per person while remaining linked.
-- Notes captured for a single person have note_group_id = null.

alter table public.notes
  add column note_group_id uuid;

create index notes_group_idx on public.notes (note_group_id);
