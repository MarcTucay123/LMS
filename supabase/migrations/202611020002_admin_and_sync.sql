create table public.sync_logs (
  id uuid primary key default gen_random_uuid(),
  initiated_by uuid references public.profiles(id) on delete set null,
  source text not null check (source in ('mock', 'onecampus_api')),
  status text not null check (status in ('running', 'success', 'failed')),
  records jsonb not null default '{}'::jsonb,
  message text,
  started_at timestamptz not null default now(),
  completed_at timestamptz
);

create index sync_logs_started_at_idx on public.sync_logs(started_at desc);

alter table public.sync_logs enable row level security;

create or replace function public.is_active_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and status = 'active'
  );
$$;

revoke all on function public.is_active_admin() from public;
grant execute on function public.is_active_admin() to authenticated;

create policy "Admins can read sync logs"
on public.sync_logs for select to authenticated
using (public.is_active_admin());

grant select on public.sync_logs to authenticated;

create or replace function public.admin_update_user(
  target_user_id uuid,
  target_role public.user_role,
  target_status public.account_status
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  updated_profile public.profiles;
begin
  if not public.is_active_admin() then
    raise exception 'Only administrators can manage users' using errcode = '42501';
  end if;

  if target_user_id = auth.uid()
    and (target_role <> 'admin' or target_status <> 'active') then
    raise exception 'You cannot remove your own active administrator access' using errcode = '22023';
  end if;

  if target_role <> 'instructor' and exists (
    select 1 from public.classes where instructor_id = target_user_id
  ) then
    raise exception 'Reassign this instructor''s class offerings before changing their role' using errcode = '23514';
  end if;

  update public.profiles
  set role = target_role,
      status = target_status
  where id = target_user_id
  returning * into updated_profile;

  if updated_profile.id is null then
    raise exception 'User profile not found' using errcode = 'P0002';
  end if;

  return updated_profile;
end;
$$;

revoke all on function public.admin_update_user(uuid, public.user_role, public.account_status) from public;
grant execute on function public.admin_update_user(uuid, public.user_role, public.account_status) to authenticated;

create policy "Admins can create class offerings"
on public.classes for insert to authenticated
with check (public.is_active_admin());

create policy "Admins can update class offerings"
on public.classes for update to authenticated
using (public.is_active_admin())
with check (public.is_active_admin());

create policy "Admins can delete class offerings"
on public.classes for delete to authenticated
using (public.is_active_admin());

grant insert, update, delete on public.classes to authenticated;

create or replace function public.validate_class_instructor()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.profiles
    where id = new.instructor_id and role = 'instructor'
  ) then
    raise exception 'Class offerings must be assigned to an instructor profile' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger classes_validate_instructor
before insert or update of instructor_id on public.classes
for each row execute function public.validate_class_instructor();