-- Optional base64-encoded JPEG thumbnail for a person's avatar.
-- Populated by the iOS Contacts import flow when the user's contact has a
-- photo. iOS thumbnails are ~5–15KB JPEGs; base64 inflates by ~33%, well
-- within reasonable row sizes. Falls back to the gradient initials avatar
-- when null.

alter table public.people
  add column avatar_image_data text;
