-- When the reader saw their library card print after first signing in. Null
-- means the welcome animation still needs to play.
alter table public.profiles add column card_printed_at timestamptz;
grant update (card_printed_at) on public.profiles to authenticated;
