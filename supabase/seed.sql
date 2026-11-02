-- Phase 1 deterministic demo identities. Password for all active demo accounts: DemoPass123!
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change, email_change_token_new,
  email_change_token_current, phone_change, phone_change_token, reauthentication_token
) values
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'admin@adfc.edu.ph', extensions.crypt('DemoPass123!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Amelia Administrator"}', now(), now(), '', '', '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'instructor@adfc.edu.ph', extensions.crypt('DemoPass123!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Isabel Instructor"}', now(), now(), '', '', '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'instructor2@adfc.edu.ph', extensions.crypt('DemoPass123!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Marco Mentor"}', now(), now(), '', '', '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', 'student1@adfc.edu.ph', extensions.crypt('DemoPass123!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Sofia Student"}', now(), now(), '', '', '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-000000000012', 'authenticated', 'authenticated', 'student2@adfc.edu.ph', extensions.crypt('DemoPass123!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Paolo Pupil"}', now(), now(), '', '', '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-000000000013', 'authenticated', 'authenticated', 'pending@adfc.edu.ph', extensions.crypt(encode(extensions.gen_random_bytes(24), 'hex'), extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Alex Activate"}', now(), now(), '', '', '', '', '', '', '', '')
on conflict (id) do nothing;

insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
select id, id, id::text, jsonb_build_object('sub', id::text, 'email', email, 'email_verified', true), 'email', now(), now(), now()
from auth.users
where id in (
  '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002',
  '00000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000011',
  '00000000-0000-4000-8000-000000000012', '00000000-0000-4000-8000-000000000013'
)
on conflict (provider_id, provider) do nothing;

insert into public.profiles (id, onecampus_user_id, school_id, email, full_name, role, status) values
  ('00000000-0000-4000-8000-000000000001', 'OC-ADMIN-001', 'ADFC-ADMIN-001', 'admin@adfc.edu.ph', 'Amelia Administrator', 'admin', 'active'),
  ('00000000-0000-4000-8000-000000000002', 'OC-FAC-001', 'ADFC-FAC-001', 'instructor@adfc.edu.ph', 'Isabel Instructor', 'instructor', 'active'),
  ('00000000-0000-4000-8000-000000000003', 'OC-FAC-002', 'ADFC-FAC-002', 'instructor2@adfc.edu.ph', 'Marco Mentor', 'instructor', 'active'),
  ('00000000-0000-4000-8000-000000000011', 'OC-STU-001', '2026-0001', 'student1@adfc.edu.ph', 'Sofia Student', 'student', 'active'),
  ('00000000-0000-4000-8000-000000000012', 'OC-STU-002', '2026-0002', 'student2@adfc.edu.ph', 'Paolo Pupil', 'student', 'active'),
  ('00000000-0000-4000-8000-000000000013', 'OC-STU-003', '2026-0003', 'pending@adfc.edu.ph', 'Alex Activate', 'student', 'pending')
on conflict (id) do nothing;

insert into public.activation_records (onecampus_user_id, school_id, email, full_name, role, auth_user_id) values
  ('OC-STU-003', '2026-0003', 'pending@adfc.edu.ph', 'Alex Activate', 'student', '00000000-0000-4000-8000-000000000013')
on conflict (onecampus_user_id) do nothing;

insert into public.subjects (id, onecampus_subject_id, code, title, description) values
  ('10000000-0000-4000-8000-000000000001', 'OC-SUB-001', 'IT 101', 'Introduction to Computing', 'Computing concepts and digital literacy.'),
  ('10000000-0000-4000-8000-000000000002', 'OC-SUB-002', 'ENG 102', 'Communication Skills', 'Academic and professional communication.'),
  ('10000000-0000-4000-8000-000000000003', 'OC-SUB-003', 'MATH 103', 'College Mathematics', 'Fundamental college mathematics.')
on conflict (id) do nothing;

insert into public.classes (id, onecampus_class_id, subject_id, instructor_id, section, school_year, semester) values
  ('20000000-0000-4000-8000-000000000001', 'OC-CLS-001', '10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002', 'BSIT-1A', '2026-2027', 'First Semester'),
  ('20000000-0000-4000-8000-000000000002', 'OC-CLS-002', '10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002', 'BSIT-1A', '2026-2027', 'First Semester'),
  ('20000000-0000-4000-8000-000000000003', 'OC-CLS-003', '10000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000003', 'BSBA-1A', '2026-2027', 'First Semester')
on conflict (id) do nothing;

insert into public.enrollments (onecampus_enrollment_id, class_id, student_id, status) values
  ('OC-ENR-001', '20000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000011', 'enrolled'),
  ('OC-ENR-002', '20000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000011', 'enrolled'),
  ('OC-ENR-003', '20000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000012', 'enrolled')
on conflict (class_id, student_id) do nothing;

insert into public.materials (id, class_id, title, description, external_url, created_by) values
  ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'Course syllabus', 'Review the course expectations and weekly topics.', 'https://www.adfc.edu.ph/', '00000000-0000-4000-8000-000000000002')
on conflict (id) do nothing;

insert into public.announcements (id, class_id, title, body, created_by) values
  ('31000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'Welcome to IT 101', 'Welcome to the class. Please review the syllabus before our next meeting.', '00000000-0000-4000-8000-000000000002')
on conflict (id) do nothing;

insert into public.discussion_topics (id, class_id, title, body, created_by) values
  ('32000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'Introduce yourself', 'Share your name and one technology topic you want to learn this semester.', '00000000-0000-4000-8000-000000000002')
on conflict (id) do nothing;

insert into public.discussion_posts (id, topic_id, author_id, body) values
  ('32100000-0000-4000-8000-000000000001', '32000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000011', 'I am Sofia, and I want to learn how web applications work.')
on conflict (id) do nothing;

insert into public.assignments (id, class_id, title, instructions, due_at, points, status, created_by) values
  ('33000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'Computing reflection', 'Write a short reflection about how computing affects your daily life.', now() + interval '7 days', 20, 'published', '00000000-0000-4000-8000-000000000002')
on conflict (id) do nothing;

insert into public.submissions (id, assignment_id, student_id, content, status, submitted_at, grade, feedback, graded_by, graded_at) values
  ('33100000-0000-4000-8000-000000000001', '33000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000011', 'Computing helps me communicate, study, and organize my daily tasks.', 'graded', now(), 18, 'Clear examples and a thoughtful reflection.', '00000000-0000-4000-8000-000000000002', now())
on conflict (id) do nothing;

insert into public.quizzes (id, class_id, title, description, status, created_by) values
  ('34000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'Computing basics', 'A short introductory knowledge check.', 'published', '00000000-0000-4000-8000-000000000002')
on conflict (id) do nothing;

insert into public.quiz_questions (id, quiz_id, prompt, question_type, options, points, position) values
  ('34100000-0000-4000-8000-000000000001', '34000000-0000-4000-8000-000000000001', 'Which component performs most calculations in a computer?', 'multiple_choice', '["CPU", "Keyboard", "Monitor", "Printer"]', 5, 1),
  ('34100000-0000-4000-8000-000000000002', '34000000-0000-4000-8000-000000000001', 'RAM is a type of temporary memory.', 'true_false', '["True", "False"]', 5, 2)
on conflict (id) do nothing;

insert into public.quiz_answer_keys (question_id, correct_answer) values
  ('34100000-0000-4000-8000-000000000001', 'CPU'),
  ('34100000-0000-4000-8000-000000000002', 'True')
on conflict (question_id) do nothing;

insert into public.quiz_attempts (id, quiz_id, student_id, answers, score, max_score, status, submitted_at) values
  ('34200000-0000-4000-8000-000000000001', '34000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000011', '{"34100000-0000-4000-8000-000000000001":"CPU","34100000-0000-4000-8000-000000000002":"True"}', 10, 10, 'submitted', now())
on conflict (id) do nothing;