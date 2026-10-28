-- Book Club: initial schema.
--
-- Privacy model: a profile's showcase (name, photo, skin, song, top 8, badges)
-- is always visible. Reading activity, shelves and monthly picks follow
-- `can_view()`: public accounts are open to everyone, private accounts only
-- to accepted followers. Blocking hides everything both ways.

create extension if not exists citext;

-- ---------------------------------------------------------------------------
-- Profiles
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username citext not null unique check (username ~ '^[a-z0-9_]{3,24}$'),
  display_name text not null default '' check (char_length(display_name) <= 60),
  avatar_url text,
  bio text not null default '' check (char_length(bio) <= 300),
  skin text not null default 'library',
  song_url text,
  monthly_goal smallint not null default 4 check (monthly_goal between 1 and 50),
  is_private boolean not null default false,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

-- Every new account gets a profile with a username derived from the email.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  base text := left(regexp_replace(lower(split_part(new.email, '@', 1)), '[^a-z0-9_]', '', 'g'), 16);
begin
  if char_length(base) < 3 then base := 'reader'; end if;
  insert into public.profiles (id, username, display_name)
  values (new.id, base || '_' || substr(md5(new.id::text), 1, 4), split_part(new.email, '@', 1));
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select is_admin from profiles where id = auth.uid()), false)
$$;

-- ---------------------------------------------------------------------------
-- Social graph
-- ---------------------------------------------------------------------------
create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  followee_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'accepted' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);
create index follows_followee_idx on public.follows (followee_id);

-- Following a private account creates a request instead.
create function public.set_follow_status() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.status := case when (select is_private from profiles where id = new.followee_id) then 'pending' else 'accepted' end;
  return new;
end $$;
create trigger follows_set_status before insert on public.follows
  for each row execute function public.set_follow_status();

create table public.blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

create function public.is_blocked(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from blocks where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a))
$$;

create function public.can_view(owner uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select owner = auth.uid()
    or (
      not public.is_blocked(owner, auth.uid())
      and (
        not (select is_private from profiles where id = owner)
        or exists (select 1 from follows where follower_id = auth.uid() and followee_id = owner and status = 'accepted')
      )
    )
$$;

-- ---------------------------------------------------------------------------
-- Books (shared cache of Google Books / Open Library results)
-- ---------------------------------------------------------------------------
create table public.books (
  id uuid primary key default gen_random_uuid(),
  source text not null check (source in ('google', 'openlibrary', 'manual')),
  external_id text not null,
  title text not null,
  authors text[] not null default '{}',
  cover_url text,
  page_count integer,
  published_year smallint,
  categories text[] not null default '{}',
  -- One of the genre badge codes in public.badges (without the "genre:" prefix).
  badge_category text,
  created_at timestamptz not null default now(),
  unique (source, external_id)
);

-- A user's relationship to a book: on the TBR, being read, or finished.
-- One row per book; `formats` holds every format the reader has it in.
create table public.user_books (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  book_id uuid not null references public.books (id) on delete cascade,
  status text not null default 'tbr' check (status in ('tbr', 'reading', 'read')),
  formats text[] not null default '{physical}' check (formats <@ array['physical', 'audio', 'kindle'] and cardinality(formats) > 0),
  -- TBR rank. Fractional so a drag only rewrites the moved row.
  position double precision not null default 0,
  started_at date,
  finished_at date,
  rating smallint check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  unique (user_id, book_id),
  check (status <> 'read' or finished_at is not null)
);
create index user_books_user_status_idx on public.user_books (user_id, status, position);

-- The best book a reader finished that month.
create table public.monthly_picks (
  user_id uuid not null references public.profiles (id) on delete cascade,
  month date not null check (extract(day from month) = 1),
  book_id uuid not null references public.books (id) on delete cascade,
  note text not null default '' check (char_length(note) <= 500),
  created_at timestamptz not null default now(),
  primary key (user_id, month)
);

-- MySpace-style top 8.
create table public.top_books (
  user_id uuid not null references public.profiles (id) on delete cascade,
  slot smallint not null check (slot between 1 and 8),
  book_id uuid not null references public.books (id) on delete cascade,
  primary key (user_id, slot)
);

-- ---------------------------------------------------------------------------
-- App-wide monthly book club
-- ---------------------------------------------------------------------------
create table public.club_months (
  month date primary key check (extract(day from month) = 1),
  book_id uuid not null references public.books (id),
  blurb text not null default '',
  partner_name text,
  partner_url text,
  partner_logo_url text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Badges
-- ---------------------------------------------------------------------------
create table public.badges (
  code text primary key,
  kind text not null check (kind in ('genre', 'goal', 'milestone', 'club')),
  name text not null,
  description text not null,
  sort smallint not null default 0
);

-- `period` is '' for one-time badges and 'YYYY-MM' for monthly ones.
create table public.user_badges (
  user_id uuid not null references public.profiles (id) on delete cascade,
  badge_code text not null references public.badges (code),
  period text not null default '',
  earned_at timestamptz not null default now(),
  primary key (user_id, badge_code, period)
);

insert into public.badges (code, kind, name, description, sort) values
  ('genre:fantasy', 'genre', 'Dragon Rider', 'Finished a fantasy book', 10),
  ('genre:scifi', 'genre', 'Star Charter', 'Finished a science fiction book', 11),
  ('genre:mystery', 'genre', 'Sleuth', 'Finished a mystery', 12),
  ('genre:thriller', 'genre', 'Edge of Seat', 'Finished a thriller', 13),
  ('genre:romance', 'genre', 'Hopeless Romantic', 'Finished a romance', 14),
  ('genre:horror', 'genre', 'Night Owl', 'Finished a horror book', 15),
  ('genre:historical', 'genre', 'Time Traveler', 'Finished historical fiction', 16),
  ('genre:literary', 'genre', 'Deep Reader', 'Finished literary fiction', 17),
  ('genre:classics', 'genre', 'Old Soul', 'Finished a classic', 18),
  ('genre:ya', 'genre', 'Forever Young', 'Finished a young adult book', 19),
  ('genre:nonfiction', 'genre', 'Fact Finder', 'Finished a nonfiction book', 20),
  ('genre:biography', 'genre', 'Life Story', 'Finished a biography or memoir', 21),
  ('genre:selfhelp', 'genre', 'Glow Up', 'Finished a self-help book', 22),
  ('genre:poetry', 'genre', 'Verse Keeper', 'Finished a poetry collection', 23),
  ('genre:graphic', 'genre', 'Panel Pro', 'Finished a graphic novel or comic', 24),
  ('goal:monthly', 'goal', 'Goal Getter', 'Hit your monthly reading goal', 1),
  ('milestone:1', 'milestone', 'First Chapter', 'Finished your first book', 30),
  ('milestone:10', 'milestone', 'Full Card', 'Filled your first punch card (10 books)', 31),
  ('milestone:25', 'milestone', 'Bookworm', 'Finished 25 books', 32),
  ('milestone:50', 'milestone', 'Shelf Stacker', 'Finished 50 books', 33),
  ('milestone:100', 'milestone', 'Centurion', 'Finished 100 books', 34),
  ('club:finisher', 'club', 'Club Member', 'Finished the monthly book club pick', 2);

-- ---------------------------------------------------------------------------
-- Activity feed + comments
-- ---------------------------------------------------------------------------
create table public.activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('started', 'finished', 'monthly_pick', 'badge')),
  book_id uuid references public.books (id) on delete cascade,
  badge_code text references public.badges (code),
  created_at timestamptz not null default now()
);
create index activities_user_created_idx on public.activities (user_id, created_at desc);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index comments_activity_idx on public.comments (activity_id, created_at);

-- Required by App Store guideline 1.2 for user-generated content.
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  target_kind text not null check (target_kind in ('user', 'comment', 'activity')),
  target_id uuid not null,
  reason text not null default '' check (char_length(reason) <= 500),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Badge awarding + activity triggers
-- ---------------------------------------------------------------------------
create function public.award_for_finished(p_user uuid, p_book uuid, p_finished date) returns void
language plpgsql security definer set search_path = public as $$
declare
  category text := (select badge_category from books where id = p_book);
  total integer := (select count(*) from user_books where user_id = p_user and status = 'read');
  month_start date := date_trunc('month', p_finished)::date;
  in_month integer := (
    select count(*) from user_books
    where user_id = p_user and status = 'read' and finished_at >= month_start and finished_at < month_start + interval '1 month'
  );
  milestone integer;
begin
  if category is not null then
    insert into user_badges (user_id, badge_code) values (p_user, 'genre:' || category) on conflict do nothing;
  end if;

  foreach milestone in array array[1, 10, 25, 50, 100] loop
    if total >= milestone then
      insert into user_badges (user_id, badge_code) values (p_user, 'milestone:' || milestone) on conflict do nothing;
    end if;
  end loop;

  if in_month >= (select monthly_goal from profiles where id = p_user) then
    insert into user_badges (user_id, badge_code, period) values (p_user, 'goal:monthly', to_char(month_start, 'YYYY-MM')) on conflict do nothing;
  end if;

  if exists (select 1 from club_months where month = month_start and book_id = p_book) then
    insert into user_badges (user_id, badge_code, period) values (p_user, 'club:finisher', to_char(month_start, 'YYYY-MM')) on conflict do nothing;
  end if;
end $$;

create function public.on_user_book_change() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'reading' and (tg_op = 'INSERT' or old.status <> 'reading') then
    insert into activities (user_id, kind, book_id) values (new.user_id, 'started', new.book_id);
  elsif new.status = 'read' and (tg_op = 'INSERT' or old.status <> 'read') then
    insert into activities (user_id, kind, book_id) values (new.user_id, 'finished', new.book_id);
    perform award_for_finished(new.user_id, new.book_id, new.finished_at);
  end if;
  return new;
end $$;
create trigger user_books_activity after insert or update of status on public.user_books
  for each row execute function public.on_user_book_change();

create function public.on_badge_earned() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into activities (user_id, kind, badge_code) values (new.user_id, 'badge', new.badge_code);
  return new;
end $$;
create trigger user_badges_activity after insert on public.user_badges
  for each row execute function public.on_badge_earned();

create function public.on_monthly_pick() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into activities (user_id, kind, book_id) values (new.user_id, 'monthly_pick', new.book_id);
  return new;
end $$;
create trigger monthly_picks_activity after insert on public.monthly_picks
  for each row execute function public.on_monthly_pick();

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.follows enable row level security;
alter table public.blocks enable row level security;
alter table public.books enable row level security;
alter table public.user_books enable row level security;
alter table public.monthly_picks enable row level security;
alter table public.top_books enable row level security;
alter table public.club_months enable row level security;
alter table public.badges enable row level security;
alter table public.user_badges enable row level security;
alter table public.activities enable row level security;
alter table public.comments enable row level security;
alter table public.reports enable row level security;

create policy "profiles are visible" on public.profiles for select using (true);
create policy "edit own profile" on public.profiles for update using (id = auth.uid());
-- Users can't promote themselves to admin.
revoke update on public.profiles from authenticated;
grant update (username, display_name, avatar_url, bio, skin, song_url, monthly_goal, is_private) on public.profiles to authenticated;

create policy "see own or visible follows" on public.follows for select
  using (follower_id = auth.uid() or followee_id = auth.uid() or public.can_view(followee_id));
create policy "follow others" on public.follows for insert
  with check (follower_id = auth.uid() and not public.is_blocked(follower_id, followee_id));
create policy "accept requests" on public.follows for update using (followee_id = auth.uid());
create policy "unfollow or remove follower" on public.follows for delete
  using (follower_id = auth.uid() or followee_id = auth.uid());

create policy "own blocks" on public.blocks for all using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

create policy "books are public" on public.books for select using (true);
create policy "signed-in users add books" on public.books for insert to authenticated with check (true);

create policy "view visible shelves" on public.user_books for select using (public.can_view(user_id));
create policy "manage own shelves" on public.user_books for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "view visible picks" on public.monthly_picks for select using (public.can_view(user_id));
create policy "manage own picks" on public.monthly_picks for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "top 8 is public" on public.top_books for select using (true);
create policy "manage own top 8" on public.top_books for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "club is public" on public.club_months for select using (true);
create policy "admins run the club" on public.club_months for all using (public.is_admin()) with check (public.is_admin());

create policy "badge catalog is public" on public.badges for select using (true);
create policy "earned badges are public" on public.user_badges for select using (true);

create policy "view visible activity" on public.activities for select using (public.can_view(user_id));
create policy "delete own activity" on public.activities for delete using (user_id = auth.uid());

create policy "view comments on visible activity" on public.comments for select
  using (exists (select 1 from activities a where a.id = activity_id and public.can_view(a.user_id)));
create policy "comment on visible activity" on public.comments for insert with check (
  user_id = auth.uid()
  and exists (select 1 from activities a where a.id = activity_id and public.can_view(a.user_id) and not public.is_blocked(a.user_id, auth.uid()))
);
create policy "delete own comments or comments on own activity" on public.comments for delete using (
  user_id = auth.uid() or exists (select 1 from activities a where a.id = activity_id and a.user_id = auth.uid())
);

create policy "file reports" on public.reports for insert with check (reporter_id = auth.uid());
create policy "admins read reports" on public.reports for select using (public.is_admin());

-- ---------------------------------------------------------------------------
-- Profile photos (library card)
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true) on conflict do nothing;
create policy "upload own avatar" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "replace own avatar" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "delete own avatar" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
