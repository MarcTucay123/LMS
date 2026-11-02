create sequence if not exists public.registration_identity_seq start with 1;

create table public.registration_applications (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  email text not null unique check (email = lower(email) and email ~ '^[a-z0-9._%+-]+@gmail[.]com$'),
  full_name text not null check (length(trim(full_name)) > 1),
  requested_role public.user_role not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index registration_applications_status_created_idx
on public.registration_applications(status, created_at desc);

create trigger registration_applications_set_updated_at
before update on public.registration_applications
for each row execute function public.set_updated_at();

alter table public.registration_applications enable row level security;

create policy "Active admins can read registration applications"
on public.registration_applications for select to authenticated
using (public.is_active_admin());

grant select on public.registration_applications to authenticated;

create or replace function public.admin_approve_registration(
  target_application_id uuid,
  assigned_class_ids uuid[] default '{}'::uuid[]
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  application public.registration_applications;
  generated_number bigint;
  role_code text;
  generated_onecampus_id text;
  generated_school_id text;
  approved_profile public.profiles;
begin
  if not public.is_active_admin() then
    raise exception 'Only active administrators can approve registrations' using errcode = '42501';
  end if;

  select * into application
  from public.registration_applications
  where id = target_application_id
  for update;

  if application.id is null then
    raise exception 'Registration application not found' using errcode = 'P0002';
  end if;

  if application.status <> 'pending' then
    raise exception 'This registration has already been reviewed' using errcode = '23514';
  end if;

  generated_number := nextval('public.registration_identity_seq');
  role_code := case application.requested_role
    when 'student' then 'STU'
    when 'instructor' then 'FAC'
    when 'admin' then 'ADMIN'
  end;
  generated_onecampus_id := format('OC-%s-%s', role_code, to_char(generated_number, 'FM000000'));
  generated_school_id := format('ADFC-%s-%s', role_code, to_char(generated_number, 'FM000000'));

  insert into public.profiles (
    id,
    onecampus_user_id,
    school_id,
    email,
    full_name,
    role,
    status
  ) values (
    application.auth_user_id,
    generated_onecampus_id,
    generated_school_id,
    application.email,
    application.full_name,
    application.requested_role,
    'active'
  )
  returning * into approved_profile;

  if application.requested_role = 'instructor' and coalesce(array_length(assigned_class_ids, 1), 0) > 0 then
    if exists (
      select 1
      from unnest(assigned_class_ids) as requested(requested_id)
      where not exists (select 1 from public.classes c where c.id = requested.requested_id)
    ) then
      raise exception 'One or more selected classes do not exist' using errcode = '23503';
    end if;

    update public.classes
    set instructor_id = application.auth_user_id
    where id = any(assigned_class_ids);
  elsif application.requested_role <> 'instructor' and coalesce(array_length(assigned_class_ids, 1), 0) > 0 then
    raise exception 'Classes can only be assigned to instructor registrations' using errcode = '23514';
  end if;

  update public.registration_applications
  set status = 'approved',
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where id = application.id;

  return approved_profile;
end;
$$;

create or replace function public.admin_reject_registration(target_application_id uuid)
returns public.registration_applications
language plpgsql
security definer
set search_path = ''
as $$
declare
  rejected_application public.registration_applications;
begin
  if not public.is_active_admin() then
    raise exception 'Only active administrators can reject registrations' using errcode = '42501';
  end if;

  update public.registration_applications
  set status = 'rejected',
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where id = target_application_id
    and status = 'pending'
  returning * into rejected_application;

  if rejected_application.id is null then
    raise exception 'Pending registration application not found' using errcode = 'P0002';
  end if;

  return rejected_application;
end;
$$;

revoke all on function public.admin_approve_registration(uuid, uuid[]) from public;
revoke all on function public.admin_reject_registration(uuid) from public;
grant execute on function public.admin_approve_registration(uuid, uuid[]) to authenticated;
grant execute on function public.admin_reject_registration(uuid) to authenticated;