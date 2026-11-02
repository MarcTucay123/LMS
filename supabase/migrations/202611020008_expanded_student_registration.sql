alter table public.registration_applications
add column if not exists student_id_number text,
add column if not exists class_code text,
add column if not exists program text,
add column if not exists year_level integer,
add column if not exists block text,
add column if not exists academic_year text,
add column if not exists semester text,
add column if not exists selected_class_ids uuid[] not null default '{}'::uuid[],
add column if not exists terms_accepted_at timestamptz;

alter table public.profiles
add column if not exists class_code text,
add column if not exists program text,
add column if not exists year_level integer,
add column if not exists block text,
add column if not exists academic_year text,
add column if not exists semester text;

create unique index if not exists registration_applications_student_id_number_key
on public.registration_applications (upper(student_id_number))
where student_id_number is not null;

alter table public.registration_applications
drop constraint if exists registration_applications_student_details_check;

alter table public.registration_applications
add constraint registration_applications_student_details_check check (
  (
    requested_role = 'student'
    and num_nonnulls(student_id_number, class_code, program, year_level, block, academic_year, semester, terms_accepted_at) = 8
    and student_id_number is not null
    and student_id_number ~ '^[A-Z0-9-]{4,30}$'
    and class_code ~ '^[0-9]{4}$'
    and length(trim(program)) between 2 and 30
    and year_level between 1 and 10
    and length(trim(block)) between 1 and 20
    and academic_year ~ '^[0-9]{4}-[0-9]{4}$'
    and length(trim(semester)) between 2 and 40
    and cardinality(selected_class_ids) > 0
    and terms_accepted_at is not null
  )
  or
  (
    requested_role = 'student'
    and num_nonnulls(student_id_number, class_code, program, year_level, block, academic_year, semester, terms_accepted_at) = 0
    and student_id_number is null
    and class_code is null
    and program is null
    and year_level is null
    and block is null
    and academic_year is null
    and semester is null
    and cardinality(selected_class_ids) = 0
    and terms_accepted_at is null
  )
  or
  (
    requested_role <> 'student'
    and num_nonnulls(student_id_number, class_code, program, year_level, block, academic_year, semester, terms_accepted_at) = 0
    and student_id_number is null
    and class_code is null
    and program is null
    and year_level is null
    and block is null
    and academic_year is null
    and semester is null
    and cardinality(selected_class_ids) = 0
    and terms_accepted_at is null
  )
);

alter table public.profiles
drop constraint if exists profiles_student_academic_details_check;

alter table public.profiles
add constraint profiles_student_academic_details_check check (
  role <> 'student'
  or (
    (class_code is null or class_code ~ '^[0-9]{4}$')
    and (year_level is null or year_level between 1 and 10)
  )
);

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
  approved_school_id text;
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
  approved_school_id := case
    when application.requested_role = 'student' and application.student_id_number is not null then application.student_id_number
    else format('ADFC-%s-%s', role_code, to_char(generated_number, 'FM000000'))
  end;

  if exists (select 1 from public.profiles where upper(school_id) = upper(approved_school_id)) then
    raise exception 'This student or account ID is already in use' using errcode = '23505';
  end if;

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
    class_code,
    program,
    year_level,
    block,
    academic_year,
    semester,
    role,
    status
  ) values (
    application.auth_user_id,
    generated_onecampus_id,
    approved_school_id,
    application.email,
    application.full_name,
    application.first_name,
    application.middle_name,
    application.last_name,
    application.suffix,
    application.class_code,
    application.program,
    application.year_level,
    application.block,
    application.academic_year,
    application.semester,
    application.requested_role,
    'active'
  )
  returning * into approved_profile;

  if application.requested_role = 'student' then
    if coalesce(array_length(assigned_class_ids, 1), 0) > 0 then
      raise exception 'Instructor class assignments cannot be supplied for a student registration' using errcode = '23514';
    end if;

    if cardinality(application.selected_class_ids) > 0 and exists (
      select 1
      from unnest(application.selected_class_ids) as requested(class_id)
      left join public.classes c on c.id = requested.class_id
      where c.id is null
        or c.status <> 'active'
        or upper(trim(c.section)) <> format('%s-%s%s', application.program, application.year_level, application.block)
        or trim(c.school_year) <> application.academic_year
        or trim(c.semester) <> application.semester
    ) then
      raise exception 'One or more selected student classes are no longer valid' using errcode = '23514';
    end if;

    insert into public.enrollments (class_id, student_id, status)
    select distinct class_id, application.auth_user_id, 'enrolled'::public.enrollment_status
    from unnest(application.selected_class_ids) as selected(class_id)
    on conflict (class_id, student_id) do update set status = 'enrolled';
  elsif application.requested_role = 'instructor' and coalesce(array_length(assigned_class_ids, 1), 0) > 0 then
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