-- Replace `Text` with `Drinks` in the allowed interaction types.
-- The previous CHECK constraint included Text; iMessage integration is
-- deferred, so we drop Text for now and add Drinks. Existing rows with
-- 'Text' (none expected outside the seed data) get backfilled to 'Other'.

-- 1. Backfill any existing 'Text' rows so the new CHECK passes.
update public.notes set interaction_type = 'Other' where interaction_type = 'Text';

-- 2. Swap the CHECK constraint. Postgres doesn't let us alter a check in
-- place — drop and re-add.
alter table public.notes drop constraint notes_interaction_type_check;
alter table public.notes add constraint notes_interaction_type_check
  check (interaction_type in ('Call','Coffee','Drinks','Event','Other'));
