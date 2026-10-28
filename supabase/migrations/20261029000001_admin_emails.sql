-- Emails listed here become admins as soon as they sign up, so an admin can be
-- named before their account exists. No policies: only the SQL editor can read it.
create table public.admin_emails (
  email citext primary key
);
alter table public.admin_emails enable row level security;

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  base text := left(regexp_replace(lower(split_part(new.email, '@', 1)), '[^a-z0-9_]', '', 'g'), 16);
begin
  if char_length(base) < 3 then base := 'reader'; end if;
  insert into public.profiles (id, username, display_name, is_admin)
  values (
    new.id,
    base || '_' || substr(md5(new.id::text), 1, 4),
    split_part(new.email, '@', 1),
    exists (select 1 from public.admin_emails where email = new.email)
  );
  return new;
end $$;

-- Covers anyone on the list who signed up before it existed.
update public.profiles p set is_admin = true
from auth.users u join public.admin_emails a on a.email = u.email
where p.id = u.id;
