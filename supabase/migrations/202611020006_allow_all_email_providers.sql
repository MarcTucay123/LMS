-- Replace the original Gmail-only registration constraint with a general
-- normalized email-address constraint. Discover the old constraint by its
-- expression so this remains safe even if PostgreSQL generated a different
-- constraint name.
do $$
declare
  constraint_name text;
begin
  select c.conname into constraint_name
  from pg_catalog.pg_constraint c
  join pg_catalog.pg_class t on t.oid = c.conrelid
  join pg_catalog.pg_namespace n on n.oid = t.relnamespace
  where n.nspname = 'public'
    and t.relname = 'registration_applications'
    and c.contype = 'c'
    and pg_catalog.pg_get_constraintdef(c.oid) ilike '%gmail%'
  limit 1;

  if constraint_name is not null then
    execute format(
      'alter table public.registration_applications drop constraint %I',
      constraint_name
    );
  end if;
end;
$$;

alter table public.registration_applications
drop constraint if exists registration_applications_email_format_check;

alter table public.registration_applications
add constraint registration_applications_email_format_check
check (
  email = lower(email)
  and email ~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$'
);