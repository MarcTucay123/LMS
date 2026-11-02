alter table public.registration_applications
add column if not exists first_name text,
add column if not exists middle_name text,
add column if not exists last_name text,
add column if not exists suffix text;

alter table public.profiles
add column if not exists first_name text,
add column if not exists middle_name text,
add column if not exists last_name text,
add column if not exists suffix text;

-- Preserve compatibility with applications submitted before structured names.
update public.registration_applications
set first_name = coalesce(first_name, nullif(split_part(trim(full_name), ' ', 1), '')),
    last_name = coalesce(
      last_name,
      nullif(trim(regexp_replace(trim(full_name), '^[^[:space:]]+[[:space:]]*', '')), ''),
      nullif(split_part(trim(full_name), ' ', 1), '')
    )
where first_name is null or last_name is null;

alter table public.registration_applications
alter column first_name set not null,
alter column last_name set not null;

alter table public.registration_applications
drop constraint if exists registration_applications_first_name_check,
drop constraint if exists registration_applications_middle_name_check,
drop constraint if exists registration_applications_last_name_check,
drop constraint if exists registration_applications_suffix_check;

alter table public.registration_applications
add constraint registration_applications_first_name_check
check (first_name is null or length(trim(first_name)) between 1 and 80),
add constraint registration_applications_middle_name_check
check (middle_name is null or length(trim(middle_name)) between 1 and 80),
add constraint registration_applications_last_name_check
check (last_name is null or length(trim(last_name)) between 1 and 80),
add constraint registration_applications_suffix_check
check (suffix is null or length(trim(suffix)) between 1 and 20);

alter table public.profiles
drop constraint if exists profiles_first_name_check,
drop constraint if exists profiles_middle_name_check,
drop constraint if exists profiles_last_name_check,
drop constraint if exists profiles_suffix_check;

alter table public.profiles
add constraint profiles_first_name_check
check (first_name is null or length(trim(first_name)) between 1 and 80),
add constraint profiles_middle_name_check
check (middle_name is null or length(trim(middle_name)) between 1 and 80),
add constraint profiles_last_name_check
check (last_name is null or length(trim(last_name)) between 1 and 80),
add constraint profiles_suffix_check
check (suffix is null or length(trim(suffix)) between 1 and 20);

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
    first_name,
    middle_name,
    last_name,
    suffix,
    role,
    status
  ) values (
    application.auth_user_id,
    generated_onecampus_id,
    generated_school_id,
    application.email,
    application.full_name,
    application.first_name,
    application.middle_name,
    application.last_name,
    application.suffix,
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

revoke all on function public.admin_approve_registration(uuid, uuid[]) from public;
grant execute on function public.admin_approve_registration(uuid, uuid[]) to authenticated;