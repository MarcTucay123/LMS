create extension if not exists pgcrypto with schema extensions;

create type public.user_role as enum ('student', 'instructor', 'admin');
create type public.account_status as enum ('pending', 'active', 'inactive');
create type public.enrollment_status as enum ('enrolled', 'dropped', 'completed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  onecampus_user_id text unique,
  school_id text not null unique,
  email text not null unique,
  full_name text not null check (length(trim(full_name)) > 1),
  role public.user_role not null,
  status public.account_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  onecampus_subject_id text unique,
  code text not null unique,
  title text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  onecampus_class_id text unique,
  subject_id uuid not null references public.subjects(id) on delete restrict,
  instructor_id uuid not null constraint classes_instructor_id_fkey references public.profiles(id) on delete restrict,
  section text not null,
  school_year text not null,
  semester text not null,
  status text not null default 'active' check (status in ('active', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (subject_id, section, school_year, semester)
);

create table public.enrollments (
  id uuid primary key default gen_random_uuid(),
  onecampus_enrollment_id text unique,
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  status public.enrollment_status not null default 'enrolled',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (class_id, student_id)
);

create table public.activation_records (
  id uuid primary key default gen_random_uuid(),
  onecampus_user_id text not null unique,
  school_id text not null unique,
  email text not null unique,
  full_name text not null,
  role public.user_role not null,
  auth_user_id uuid unique references auth.users(id) on delete set null,
  activated_at timestamptz,
  created_at timestamptz not null default now()
);

create index enrollments_student_status_idx on public.enrollments(student_id, status);
create index enrollments_class_status_idx on public.enrollments(class_id, status);
create index classes_instructor_idx on public.classes(instructor_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger subjects_set_updated_at before update on public.subjects for each row execute function public.set_updated_at();
create trigger classes_set_updated_at before update on public.classes for each row execute function public.set_updated_at();
create trigger enrollments_set_updated_at before update on public.enrollments for each row execute function public.set_updated_at();

create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.profiles where id = auth.uid() and status = 'active';
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.current_user_role() = 'admin', false);
$$;

create or replace function public.can_access_class(target_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.classes c
    where c.id = target_class_id
      and (
        public.is_admin()
        or c.instructor_id = auth.uid()
        or exists (
          select 1 from public.enrollments e
          where e.class_id = c.id
            and e.student_id = auth.uid()
            and e.status = 'enrolled'
        )
      )
  );
$$;

create or replace function public.can_view_profile(target_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select target_profile_id = auth.uid()
    or public.is_admin()
    or exists (
      select 1 from public.classes c
      where c.instructor_id = target_profile_id
        and public.can_access_class(c.id)
    );
$$;

revoke all on function public.current_user_role() from public;
revoke all on function public.is_admin() from public;
revoke all on function public.can_access_class(uuid) from public;
revoke all on function public.can_view_profile(uuid) from public;
grant execute on function public.current_user_role() to authenticated;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.can_access_class(uuid) to authenticated;
grant execute on function public.can_view_profile(uuid) to authenticated;

alter table public.profiles enable row level security;
alter table public.subjects enable row level security;
alter table public.classes enable row level security;
alter table public.enrollments enable row level security;
alter table public.activation_records enable row level security;

create policy "Users can read permitted profiles"
on public.profiles for select to authenticated
using (public.can_view_profile(id));

create policy "Users can read subjects for permitted classes"
on public.subjects for select to authenticated
using (public.is_admin() or exists (
  select 1 from public.classes c
  where c.subject_id = subjects.id and public.can_access_class(c.id)
));

create policy "Users can read permitted classes"
on public.classes for select to authenticated
using (public.can_access_class(id));

create policy "Users can read permitted enrollments"
on public.enrollments for select to authenticated
using (student_id = auth.uid() or public.is_admin() or exists (
  select 1 from public.classes c where c.id = enrollments.class_id and c.instructor_id = auth.uid()
));

-- activation_records intentionally has no browser policy. It is available only to service-role code.

grant usage on schema public to anon, authenticated;
grant select on public.profiles, public.subjects, public.classes, public.enrollments to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('materials', 'materials', false, 10485760, array['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/zip']),
  ('submissions', 'submissions', false, 10485760, array['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/zip'])
on conflict (id) do nothing;