-- Demo users were originally inserted directly into auth.users. Current GoTrue
-- versions expect token/change string columns to contain empty strings rather
-- than NULL. Normalize every compatible column that exists in the hosted Auth
-- schema without depending on one specific Supabase Auth schema version.
do $$
declare
  target_column text;
  auth_string_columns constant text[] := array[
    'confirmation_token',
    'recovery_token',
    'email_change',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change',
    'phone_change_token',
    'reauthentication_token'
  ];
begin
  foreach target_column in array auth_string_columns loop
    if exists (
      select 1
      from information_schema.columns c
      where c.table_schema = 'auth'
        and c.table_name = 'users'
        and c.column_name = target_column
    ) then
      execute format(
        'update auth.users set %I = '''' where %I is null and id in (
          ''00000000-0000-4000-8000-000000000001'',
          ''00000000-0000-4000-8000-000000000002'',
          ''00000000-0000-4000-8000-000000000003'',
          ''00000000-0000-4000-8000-000000000011'',
          ''00000000-0000-4000-8000-000000000012'',
          ''00000000-0000-4000-8000-000000000013''
        )',
        target_column,
        target_column
      );
    end if;
  end loop;
end;
$$;

-- Ensure email identities have the fields GoTrue expects when loading a user.
update auth.identities
set identity_data = coalesce(identity_data, '{}'::jsonb)
  || jsonb_build_object(
    'sub', user_id::text,
    'email', coalesce(identity_data ->> 'email', (select email from auth.users where id = auth.identities.user_id)),
    'email_verified', true
  ),
  provider_id = coalesce(nullif(provider_id, ''), user_id::text),
  updated_at = now()
where provider = 'email'
  and user_id in (
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000002',
    '00000000-0000-4000-8000-000000000003',
    '00000000-0000-4000-8000-000000000011',
    '00000000-0000-4000-8000-000000000012',
    '00000000-0000-4000-8000-000000000013'
  );