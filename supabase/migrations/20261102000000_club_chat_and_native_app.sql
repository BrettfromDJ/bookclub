-- Plot Twist native iOS app: book club chat and in-app account deletion.

-- ---------------------------------------------------------------------------
-- Book club chat ("join the chat"): one conversation per monthly pick.
-- ---------------------------------------------------------------------------
create table public.club_messages (
  id uuid primary key default gen_random_uuid(),
  month date not null references public.club_months (month) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index club_messages_month_created_idx on public.club_messages (month, created_at desc);

alter table public.club_messages enable row level security;

-- Every signed-in reader can read the club chat, minus people they've blocked (or who blocked them).
create policy "read club chat" on public.club_messages for select to authenticated
  using (not public.is_blocked(user_id, auth.uid()));
create policy "post to club chat" on public.club_messages for insert to authenticated
  with check (user_id = auth.uid());
create policy "delete own messages or moderate" on public.club_messages for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- Messages can be reported like comments.
alter table public.reports drop constraint if exists reports_target_kind_check;
alter table public.reports add constraint reports_target_kind_check
  check (target_kind in ('user', 'comment', 'activity', 'message'));

-- ---------------------------------------------------------------------------
-- In-app account deletion (App Store guideline 5.1.1(v)).
-- The app can't hold the service-role key, so the signed-in user deletes
-- themselves through this function. Removing the auth user cascades to the
-- profile and everything that references it.
-- ---------------------------------------------------------------------------
create function public.delete_my_account() returns void
language plpgsql security definer set search_path = public, auth as $$
begin
  if auth.uid() is null then
    raise exception 'not signed in';
  end if;
  delete from auth.users where id = auth.uid();
end $$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
