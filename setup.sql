-- DMACP Assets: run this ONCE in Supabase -> SQL Editor -> New query -> Run.

-- ---------- Tables ----------
create sequence if not exists public.asset_number_seq;

create table if not exists public.assets (
  id             text primary key default ('A' || lpad(nextval('public.asset_number_seq')::text, 4, '0')),
  name           text not null check (length(trim(name)) > 0),
  notes          text not null default '',
  status         text not null default 'in' check (status in ('in', 'out')),
  holder_name    text,
  holder_contact text,
  holder_since   timestamptz,
  created_at     timestamptz not null default now()
);

create table if not exists public.events (
  id             bigint generated always as identity primary key,
  asset_id       text not null references public.assets(id) on delete cascade,
  type           text not null check (type in ('take', 'ret')),
  person_name    text,
  person_contact text,
  created_at     timestamptz not null default now()
);
create index if not exists events_asset_idx on public.events (asset_id, created_at desc);

-- ---------- Security: only signed-in staff can touch anything ----------
alter table public.assets enable row level security;
alter table public.events enable row level security;

revoke all on public.assets, public.events from anon;
grant select, insert, update, delete on public.assets to authenticated;
grant select, insert on public.events to authenticated;
grant usage on sequence public.asset_number_seq to authenticated;

drop policy if exists "staff manage assets" on public.assets;
create policy "staff manage assets" on public.assets
  for all to authenticated using (true) with check (true);

drop policy if exists "staff read events" on public.events;
create policy "staff read events" on public.events
  for select to authenticated using (true);

drop policy if exists "staff add events" on public.events;
create policy "staff add events" on public.events
  for insert to authenticated with check (true);

-- ---------- Check out / check in (atomic, so two scans can't clash) ----------
create or replace function public.check_out(p_asset text, p_name text, p_contact text)
returns public.assets
language plpgsql security invoker set search_path = public as $$
declare r public.assets;
begin
  if coalesce(trim(p_name), '') = '' or coalesce(trim(p_contact), '') = '' then
    raise exception 'Name and contact details are required';
  end if;
  update public.assets
     set status = 'out', holder_name = trim(p_name), holder_contact = trim(p_contact), holder_since = now()
   where id = p_asset and status = 'in'
   returning * into r;
  if not found then
    raise exception 'That item is unknown or already checked out';
  end if;
  insert into public.events (asset_id, type, person_name, person_contact)
  values (p_asset, 'take', r.holder_name, r.holder_contact);
  return r;
end $$;

create or replace function public.check_in(p_asset text)
returns public.assets
language plpgsql security invoker set search_path = public as $$
declare old public.assets; r public.assets;
begin
  select * into old from public.assets where id = p_asset and status = 'out' for update;
  if not found then
    raise exception 'That item is unknown or already in storage';
  end if;
  update public.assets
     set status = 'in', holder_name = null, holder_contact = null, holder_since = null
   where id = p_asset
   returning * into r;
  insert into public.events (asset_id, type, person_name, person_contact)
  values (p_asset, 'ret', old.holder_name, old.holder_contact);
  return r;
end $$;

revoke execute on function public.check_out(text, text, text) from public, anon;
revoke execute on function public.check_in(text) from public, anon;
grant execute on function public.check_out(text, text, text) to authenticated;
grant execute on function public.check_in(text) to authenticated;
