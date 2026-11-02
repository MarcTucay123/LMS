create type public.publish_status as enum ('draft', 'published', 'closed');
create type public.submission_status as enum ('draft', 'submitted', 'graded');
create type public.attempt_status as enum ('in_progress', 'submitted');

create or replace function public.can_manage_class(target_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_active_admin() or exists (
    select 1
    from public.classes c
    join public.profiles p on p.id = auth.uid()
    where c.id = target_class_id
      and c.instructor_id = auth.uid()
      and p.role = 'instructor'
      and p.status = 'active'
  );
$$;

revoke all on function public.can_manage_class(uuid) from public;
grant execute on function public.can_manage_class(uuid) to authenticated;

create or replace function public.can_access_class(target_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.status = 'active'
      and (
        p.role = 'admin'
        or exists (select 1 from public.classes c where c.id = target_class_id and c.instructor_id = auth.uid())
        or exists (
          select 1 from public.enrollments e
          where e.class_id = target_class_id and e.student_id = auth.uid() and e.status = 'enrolled'
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
    or public.is_active_admin()
    or exists (
      select 1 from public.classes c
      where c.instructor_id = target_profile_id and public.can_access_class(c.id)
    )
    or exists (
      select 1 from public.enrollments e
      where e.student_id = target_profile_id and e.status = 'enrolled' and public.can_access_class(e.class_id)
    );
$$;

create table public.materials (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  title text not null check (length(trim(title)) > 1),
  description text,
  file_path text,
  external_url text,
  created_by uuid not null references public.profiles(id) on delete restrict default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (file_path is not null or external_url is not null)
);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  title text not null check (length(trim(title)) > 1),
  body text not null check (length(trim(body)) > 1),
  created_by uuid not null references public.profiles(id) on delete restrict default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.discussion_topics (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  title text not null check (length(trim(title)) > 1),
  body text not null check (length(trim(body)) > 1),
  created_by uuid not null references public.profiles(id) on delete restrict default auth.uid(),
  is_locked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.discussion_posts (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.discussion_topics(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete restrict default auth.uid(),
  body text not null check (length(trim(body)) > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.assignments (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  title text not null check (length(trim(title)) > 1),
  instructions text not null,
  due_at timestamptz,
  points numeric(8,2) not null default 100 check (points > 0),
  status public.publish_status not null default 'draft',
  created_by uuid not null references public.profiles(id) on delete restrict default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade default auth.uid(),
  content text,
  file_path text,
  status public.submission_status not null default 'submitted',
  submitted_at timestamptz not null default now(),
  grade numeric(8,2),
  feedback text,
  graded_by uuid references public.profiles(id) on delete set null,
  graded_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (assignment_id, student_id),
  check (content is not null or file_path is not null)
);

create table public.quizzes (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  title text not null check (length(trim(title)) > 1),
  description text,
  opens_at timestamptz,
  closes_at timestamptz,
  time_limit_minutes integer check (time_limit_minutes is null or time_limit_minutes > 0),
  status public.publish_status not null default 'draft',
  created_by uuid not null references public.profiles(id) on delete restrict default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  prompt text not null check (length(trim(prompt)) > 0),
  question_type text not null check (question_type in ('multiple_choice', 'true_false', 'short_answer')),
  options jsonb not null default '[]'::jsonb,
  points numeric(8,2) not null default 1 check (points > 0),
  position integer not null default 1 check (position > 0),
  created_at timestamptz not null default now(),
  unique (quiz_id, position)
);

create table public.quiz_answer_keys (
  question_id uuid primary key references public.quiz_questions(id) on delete cascade,
  correct_answer text not null,
  case_sensitive boolean not null default false
);

create table public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade default auth.uid(),
  answers jsonb not null default '{}'::jsonb,
  score numeric(8,2),
  max_score numeric(8,2),
  status public.attempt_status not null default 'submitted',
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  unique (quiz_id, student_id)
);

create index materials_class_idx on public.materials(class_id, created_at desc);
create index announcements_class_idx on public.announcements(class_id, created_at desc);
create index discussion_topics_class_idx on public.discussion_topics(class_id, created_at desc);
create index discussion_posts_topic_idx on public.discussion_posts(topic_id, created_at);
create index assignments_class_idx on public.assignments(class_id, due_at);
create index submissions_assignment_idx on public.submissions(assignment_id, student_id);
create index quizzes_class_idx on public.quizzes(class_id, created_at desc);
create index quiz_questions_quiz_idx on public.quiz_questions(quiz_id, position);
create index quiz_attempts_quiz_idx on public.quiz_attempts(quiz_id, student_id);

create trigger materials_set_updated_at before update on public.materials for each row execute function public.set_updated_at();
create trigger announcements_set_updated_at before update on public.announcements for each row execute function public.set_updated_at();
create trigger discussion_topics_set_updated_at before update on public.discussion_topics for each row execute function public.set_updated_at();
create trigger discussion_posts_set_updated_at before update on public.discussion_posts for each row execute function public.set_updated_at();
create trigger assignments_set_updated_at before update on public.assignments for each row execute function public.set_updated_at();
create trigger submissions_set_updated_at before update on public.submissions for each row execute function public.set_updated_at();
create trigger quizzes_set_updated_at before update on public.quizzes for each row execute function public.set_updated_at();

alter table public.materials enable row level security;
alter table public.announcements enable row level security;
alter table public.discussion_topics enable row level security;
alter table public.discussion_posts enable row level security;
alter table public.assignments enable row level security;
alter table public.submissions enable row level security;
alter table public.quizzes enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.quiz_answer_keys enable row level security;
alter table public.quiz_attempts enable row level security;

create policy "Class members can read materials" on public.materials for select to authenticated using (public.can_access_class(class_id));
create policy "Class managers can create materials" on public.materials for insert to authenticated with check (public.can_manage_class(class_id) and created_by = auth.uid());
create policy "Class managers can update materials" on public.materials for update to authenticated using (public.can_manage_class(class_id)) with check (public.can_manage_class(class_id));
create policy "Class managers can delete materials" on public.materials for delete to authenticated using (public.can_manage_class(class_id));

create policy "Class members can read announcements" on public.announcements for select to authenticated using (public.can_access_class(class_id));
create policy "Class managers can create announcements" on public.announcements for insert to authenticated with check (public.can_manage_class(class_id) and created_by = auth.uid());
create policy "Class managers can update announcements" on public.announcements for update to authenticated using (public.can_manage_class(class_id)) with check (public.can_manage_class(class_id));
create policy "Class managers can delete announcements" on public.announcements for delete to authenticated using (public.can_manage_class(class_id));

create policy "Class members can read topics" on public.discussion_topics for select to authenticated using (public.can_access_class(class_id));
create policy "Class members can create topics" on public.discussion_topics for insert to authenticated with check (public.can_access_class(class_id) and created_by = auth.uid());
create policy "Authors and managers can update topics" on public.discussion_topics for update to authenticated using (created_by = auth.uid() or public.can_manage_class(class_id)) with check ((created_by = auth.uid() and public.can_access_class(class_id)) or public.can_manage_class(class_id));
create policy "Authors and managers can delete topics" on public.discussion_topics for delete to authenticated using (created_by = auth.uid() or public.can_manage_class(class_id));

create policy "Class members can read posts" on public.discussion_posts for select to authenticated using (exists (select 1 from public.discussion_topics t where t.id = topic_id and public.can_access_class(t.class_id)));
create policy "Class members can create posts" on public.discussion_posts for insert to authenticated with check (author_id = auth.uid() and exists (select 1 from public.discussion_topics t where t.id = topic_id and not t.is_locked and public.can_access_class(t.class_id)));
create policy "Authors and managers can update posts" on public.discussion_posts for update to authenticated using (author_id = auth.uid() or exists (select 1 from public.discussion_topics t where t.id = topic_id and public.can_manage_class(t.class_id))) with check ((author_id = auth.uid() and exists (select 1 from public.discussion_topics t where t.id = topic_id and public.can_access_class(t.class_id))) or exists (select 1 from public.discussion_topics t where t.id = topic_id and public.can_manage_class(t.class_id)));
create policy "Authors and managers can delete posts" on public.discussion_posts for delete to authenticated using (author_id = auth.uid() or exists (select 1 from public.discussion_topics t where t.id = topic_id and public.can_manage_class(t.class_id)));

create policy "Members can read available assignments" on public.assignments for select to authenticated using (public.can_manage_class(class_id) or (status <> 'draft' and public.can_access_class(class_id)));
create policy "Managers can create assignments" on public.assignments for insert to authenticated with check (public.can_manage_class(class_id) and created_by = auth.uid());
create policy "Managers can update assignments" on public.assignments for update to authenticated using (public.can_manage_class(class_id)) with check (public.can_manage_class(class_id));
create policy "Managers can delete assignments" on public.assignments for delete to authenticated using (public.can_manage_class(class_id));

create policy "Students and managers can read submissions" on public.submissions for select to authenticated using (student_id = auth.uid() or exists (select 1 from public.assignments a where a.id = assignment_id and public.can_manage_class(a.class_id)));

create policy "Members can read available quizzes" on public.quizzes for select to authenticated using (public.can_manage_class(class_id) or (status <> 'draft' and public.can_access_class(class_id)));
create policy "Managers can create quizzes" on public.quizzes for insert to authenticated with check (public.can_manage_class(class_id) and created_by = auth.uid());
create policy "Managers can update quizzes" on public.quizzes for update to authenticated using (public.can_manage_class(class_id)) with check (public.can_manage_class(class_id));
create policy "Managers can delete quizzes" on public.quizzes for delete to authenticated using (public.can_manage_class(class_id));

create policy "Members can read quiz questions" on public.quiz_questions for select to authenticated using (exists (select 1 from public.quizzes q where q.id = quiz_id and (public.can_manage_class(q.class_id) or (q.status <> 'draft' and public.can_access_class(q.class_id)))));
create policy "Managers can create quiz questions" on public.quiz_questions for insert to authenticated with check (exists (select 1 from public.quizzes q where q.id = quiz_id and public.can_manage_class(q.class_id)));
create policy "Managers can update quiz questions" on public.quiz_questions for update to authenticated using (exists (select 1 from public.quizzes q where q.id = quiz_id and public.can_manage_class(q.class_id)));
create policy "Managers can delete quiz questions" on public.quiz_questions for delete to authenticated using (exists (select 1 from public.quizzes q where q.id = quiz_id and public.can_manage_class(q.class_id)));

create policy "Managers can read answer keys" on public.quiz_answer_keys for select to authenticated using (exists (select 1 from public.quiz_questions qq join public.quizzes q on q.id = qq.quiz_id where qq.id = question_id and public.can_manage_class(q.class_id)));
create policy "Managers can create answer keys" on public.quiz_answer_keys for insert to authenticated with check (exists (select 1 from public.quiz_questions qq join public.quizzes q on q.id = qq.quiz_id where qq.id = question_id and public.can_manage_class(q.class_id)));
create policy "Managers can update answer keys" on public.quiz_answer_keys for update to authenticated using (exists (select 1 from public.quiz_questions qq join public.quizzes q on q.id = qq.quiz_id where qq.id = question_id and public.can_manage_class(q.class_id)));
create policy "Managers can delete answer keys" on public.quiz_answer_keys for delete to authenticated using (exists (select 1 from public.quiz_questions qq join public.quizzes q on q.id = qq.quiz_id where qq.id = question_id and public.can_manage_class(q.class_id)));

create policy "Students and managers can read attempts" on public.quiz_attempts for select to authenticated using (student_id = auth.uid() or exists (select 1 from public.quizzes q where q.id = quiz_id and public.can_manage_class(q.class_id)));

grant select, insert, update, delete on public.materials, public.announcements, public.discussion_topics, public.discussion_posts, public.assignments, public.quizzes, public.quiz_questions, public.quiz_answer_keys to authenticated;
grant select on public.submissions to authenticated;
grant select on public.quiz_attempts to authenticated;

create or replace function public.submit_assignment(target_assignment_id uuid, submission_content text, submission_file_path text)
returns public.submissions
language plpgsql
security definer
set search_path = ''
as $$
declare
  assignment_row public.assignments;
  result public.submissions;
begin
  select * into assignment_row from public.assignments where id = target_assignment_id;
  if assignment_row.id is null or assignment_row.status <> 'published' or not public.can_access_class(assignment_row.class_id) then
    raise exception 'Assignment is not available' using errcode = '42501';
  end if;
  if public.current_user_role() <> 'student' then
    raise exception 'Only students can submit assignments' using errcode = '42501';
  end if;
  if nullif(trim(submission_content), '') is null and nullif(trim(submission_file_path), '') is null then
    raise exception 'Add text or a file before submitting' using errcode = '22023';
  end if;
  if nullif(trim(submission_file_path), '') is not null
    and submission_file_path not like (assignment_row.class_id::text || '/' || auth.uid()::text || '/%') then
    raise exception 'Submission file path is invalid' using errcode = '22023';
  end if;

  insert into public.submissions (assignment_id, student_id, content, file_path, status, submitted_at, grade, feedback, graded_by, graded_at)
  values (target_assignment_id, auth.uid(), nullif(trim(submission_content), ''), nullif(trim(submission_file_path), ''), 'submitted', now(), null, null, null, null)
  on conflict (assignment_id, student_id) do update
    set content = excluded.content,
        file_path = excluded.file_path,
        status = 'submitted',
        submitted_at = now(),
        grade = null,
        feedback = null,
        graded_by = null,
        graded_at = null
    where submissions.status <> 'graded'
  returning * into result;

  if result.id is null then
    raise exception 'Graded submissions cannot be replaced' using errcode = '22023';
  end if;
  return result;
end;
$$;

create or replace function public.grade_submission(target_submission_id uuid, awarded_grade numeric, grading_feedback text)
returns public.submissions
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.submissions;
  maximum_points numeric(8,2);
  target_class_id uuid;
begin
  select a.points, a.class_id into maximum_points, target_class_id
  from public.submissions s join public.assignments a on a.id = s.assignment_id
  where s.id = target_submission_id;
  if target_class_id is null or not public.can_manage_class(target_class_id) then
    raise exception 'Only the class instructor or administrator can grade this submission' using errcode = '42501';
  end if;
  if awarded_grade < 0 or awarded_grade > maximum_points then
    raise exception 'Grade must be between 0 and the assignment points' using errcode = '22023';
  end if;

  update public.submissions
  set grade = awarded_grade,
      feedback = nullif(trim(grading_feedback), ''),
      status = 'graded',
      graded_by = auth.uid(),
      graded_at = now()
  where id = target_submission_id
  returning * into result;
  return result;
end;
$$;

revoke all on function public.submit_assignment(uuid, text, text) from public;
revoke all on function public.grade_submission(uuid, numeric, text) from public;
grant execute on function public.submit_assignment(uuid, text, text) to authenticated;
grant execute on function public.grade_submission(uuid, numeric, text) to authenticated;

create or replace function public.submit_quiz(target_quiz_id uuid, submitted_answers jsonb)
returns public.quiz_attempts
language plpgsql
security definer
set search_path = ''
as $$
declare
  quiz_row public.quizzes;
  total_score numeric(8,2) := 0;
  maximum_score numeric(8,2) := 0;
  question record;
  supplied text;
  attempt public.quiz_attempts;
begin
  select * into quiz_row from public.quizzes where id = target_quiz_id;
  if quiz_row.id is null or quiz_row.status <> 'published' or not public.can_access_class(quiz_row.class_id) then
    raise exception 'Quiz is not available' using errcode = '42501';
  end if;
  if public.current_user_role() <> 'student' then
    raise exception 'Only students can submit quiz attempts' using errcode = '42501';
  end if;
  if quiz_row.opens_at is not null and now() < quiz_row.opens_at then raise exception 'Quiz is not open yet'; end if;
  if quiz_row.closes_at is not null and now() > quiz_row.closes_at then raise exception 'Quiz is closed'; end if;
  if exists (select 1 from public.quiz_attempts where quiz_id = target_quiz_id and student_id = auth.uid()) then
    raise exception 'Quiz has already been submitted' using errcode = '23505';
  end if;

  for question in
    select qq.id, qq.points, k.correct_answer, k.case_sensitive
    from public.quiz_questions qq join public.quiz_answer_keys k on k.question_id = qq.id
    where qq.quiz_id = target_quiz_id
  loop
    maximum_score := maximum_score + question.points;
    supplied := submitted_answers ->> question.id::text;
    if supplied is not null and (
      (question.case_sensitive and trim(supplied) = trim(question.correct_answer))
      or (not question.case_sensitive and lower(trim(supplied)) = lower(trim(question.correct_answer)))
    ) then
      total_score := total_score + question.points;
    end if;
  end loop;

  insert into public.quiz_attempts (quiz_id, student_id, answers, score, max_score, status, submitted_at)
  values (target_quiz_id, auth.uid(), submitted_answers, total_score, maximum_score, 'submitted', now())
  returning * into attempt;
  return attempt;
end;
$$;

revoke all on function public.submit_quiz(uuid, jsonb) from public;
grant execute on function public.submit_quiz(uuid, jsonb) to authenticated;

create policy "Class members can download materials" on storage.objects for select to authenticated
using (bucket_id = 'materials' and public.can_access_class(((storage.foldername(name))[1])::uuid));
create policy "Class managers can upload materials" on storage.objects for insert to authenticated
with check (bucket_id = 'materials' and public.can_manage_class(((storage.foldername(name))[1])::uuid));
create policy "Class managers can update materials files" on storage.objects for update to authenticated
using (bucket_id = 'materials' and public.can_manage_class(((storage.foldername(name))[1])::uuid));
create policy "Class managers can delete materials files" on storage.objects for delete to authenticated
using (bucket_id = 'materials' and public.can_manage_class(((storage.foldername(name))[1])::uuid));

create policy "Students and class managers can download submissions" on storage.objects for select to authenticated
using (bucket_id = 'submissions' and (auth.uid()::text = (storage.foldername(name))[2] or public.can_manage_class(((storage.foldername(name))[1])::uuid)));
create policy "Students can upload own submissions" on storage.objects for insert to authenticated
with check (bucket_id = 'submissions' and public.can_access_class(((storage.foldername(name))[1])::uuid) and auth.uid()::text = (storage.foldername(name))[2]);
create policy "Students can update own submissions" on storage.objects for update to authenticated
using (bucket_id = 'submissions' and public.can_access_class(((storage.foldername(name))[1])::uuid) and auth.uid()::text = (storage.foldername(name))[2])
with check (bucket_id = 'submissions' and public.can_access_class(((storage.foldername(name))[1])::uuid) and auth.uid()::text = (storage.foldername(name))[2]);
create policy "Students can delete own submissions" on storage.objects for delete to authenticated
using (bucket_id = 'submissions' and public.can_access_class(((storage.foldername(name))[1])::uuid) and auth.uid()::text = (storage.foldername(name))[2]);