USE lms_db;

SET @demo_hash = '$2y$10$6mANmD.gtzn6nODl1DVjyOBatF43dFoh3vyyd1PfxEbexADIlJ4P.';
INSERT INTO users (id, email, password_hash, requested_role) VALUES
('00000000-0000-4000-8000-000000000001','admin@adfc.edu.ph',@demo_hash,'admin'),
('00000000-0000-4000-8000-000000000002','instructor@adfc.edu.ph',@demo_hash,'instructor'),
('00000000-0000-4000-8000-000000000003','instructor2@adfc.edu.ph',@demo_hash,'instructor'),
('00000000-0000-4000-8000-000000000011','student1@adfc.edu.ph',@demo_hash,'student'),
('00000000-0000-4000-8000-000000000012','student2@adfc.edu.ph',@demo_hash,'student'),
('00000000-0000-4000-8000-000000000013','pending@adfc.edu.ph',@demo_hash,'student');

INSERT INTO profiles (id,onecampus_user_id,source_system,synced_at,school_id,email,full_name,first_name,last_name,role,status) VALUES
('00000000-0000-4000-8000-000000000001','OC-ADMIN-001','onecampus',NOW(),'ADFC-ADMIN-001','admin@adfc.edu.ph','Amelia Administrator','Amelia','Administrator','admin','active'),
('00000000-0000-4000-8000-000000000002','OC-FAC-001','employee_management',NOW(),'ADFC-FAC-001','instructor@adfc.edu.ph','Isabel Instructor','Isabel','Instructor','instructor','active'),
('00000000-0000-4000-8000-000000000003','OC-FAC-002','employee_management',NOW(),'ADFC-FAC-002','instructor2@adfc.edu.ph','Marco Mentor','Marco','Mentor','instructor','active'),
('00000000-0000-4000-8000-000000000011','OC-STU-001','enrollment_management',NOW(),'2026-0001','student1@adfc.edu.ph','Sofia Student','Sofia','Student','student','active'),
('00000000-0000-4000-8000-000000000012','OC-STU-002','enrollment_management',NOW(),'2026-0002','student2@adfc.edu.ph','Paolo Pupil','Paolo','Pupil','student','active'),
('00000000-0000-4000-8000-000000000013','OC-STU-003','enrollment_management',NOW(),'2026-0003','pending@adfc.edu.ph','Alex Activate','Alex','Activate','student','pending');

INSERT INTO activation_records (id,onecampus_user_id,school_id,email,full_name,role,auth_user_id) VALUES
('00000000-0000-4000-8000-100000000013','OC-STU-003','2026-0003','pending@adfc.edu.ph','Alex Activate','student','00000000-0000-4000-8000-000000000013');

INSERT INTO subjects (id,onecampus_subject_id,source_system,synced_at,code,title,description) VALUES
('10000000-0000-4000-8000-000000000001','OC-SUB-001','course_catalog',NOW(),'IT 101','Introduction to Computing','Computing concepts and digital literacy.'),
('10000000-0000-4000-8000-000000000002','OC-SUB-002','course_catalog',NOW(),'ENG 102','Communication Skills','Academic and professional communication.'),
('10000000-0000-4000-8000-000000000003','OC-SUB-003','course_catalog',NOW(),'MATH 103','College Mathematics','Fundamental college mathematics.');

INSERT INTO classes (id,onecampus_class_id,source_system,synced_at,subject_id,instructor_id,section,school_year,semester) VALUES
('20000000-0000-4000-8000-000000000001','OC-CLS-001','class_scheduling',NOW(),'10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000002','BSIT-1A','2026-2027','First Semester'),
('20000000-0000-4000-8000-000000000002','OC-CLS-002','class_scheduling',NOW(),'10000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000002','BSIT-1A','2026-2027','First Semester'),
('20000000-0000-4000-8000-000000000003','OC-CLS-003','class_scheduling',NOW(),'10000000-0000-4000-8000-000000000003','00000000-0000-4000-8000-000000000003','BSBA-1A','2026-2027','First Semester');

INSERT INTO enrollments (id,onecampus_enrollment_id,source_system,synced_at,class_id,student_id,status) VALUES
('21000000-0000-4000-8000-000000000001','OC-ENR-001','enrollment_management',NOW(),'20000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000011','enrolled'),
('21000000-0000-4000-8000-000000000002','OC-ENR-002','enrollment_management',NOW(),'20000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000011','enrolled'),
('21000000-0000-4000-8000-000000000003','OC-ENR-003','enrollment_management',NOW(),'20000000-0000-4000-8000-000000000003','00000000-0000-4000-8000-000000000012','enrolled');

INSERT INTO materials (id,class_id,title,description,external_url,created_by) VALUES
('30000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','Course syllabus','Review the course expectations and weekly topics.','https://www.adfc.edu.ph/','00000000-0000-4000-8000-000000000002');
INSERT INTO announcements (id,class_id,title,body,created_by) VALUES
('31000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','Welcome to IT 101','Welcome to the class. Please review the syllabus before our next meeting.','00000000-0000-4000-8000-000000000002');
INSERT INTO discussion_topics (id,class_id,title,body,created_by) VALUES
('32000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','Introduce yourself','Share your name and one technology topic you want to learn this semester.','00000000-0000-4000-8000-000000000002');
INSERT INTO discussion_posts (id,topic_id,author_id,body) VALUES
('32100000-0000-4000-8000-000000000001','32000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000011','I am Sofia, and I want to learn how web applications work.');
INSERT INTO assignments (id,class_id,title,instructions,due_at,points,status,created_by) VALUES
('33000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','Computing reflection','Write a short reflection about how computing affects your daily life.',DATE_ADD(NOW(),INTERVAL 7 DAY),20,'published','00000000-0000-4000-8000-000000000002');
INSERT INTO submissions (id,assignment_id,student_id,content,status,grade,feedback,graded_by,graded_at) VALUES
('33100000-0000-4000-8000-000000000001','33000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000011','Computing helps me communicate, study, and organize my daily tasks.','graded',18,'Clear examples and a thoughtful reflection.','00000000-0000-4000-8000-000000000002',NOW());
INSERT INTO quizzes (id,class_id,title,description,status,created_by) VALUES
('34000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','Computing basics','A short introductory knowledge check.','published','00000000-0000-4000-8000-000000000002');
INSERT INTO quiz_questions (id,quiz_id,prompt,question_type,options,points,position) VALUES
('34100000-0000-4000-8000-000000000001','34000000-0000-4000-8000-000000000001','Which component performs most calculations in a computer?','multiple_choice','["CPU","Keyboard","Monitor","Printer"]',5,1),
('34100000-0000-4000-8000-000000000002','34000000-0000-4000-8000-000000000001','RAM is a type of temporary memory.','true_false','["True","False"]',5,2);
INSERT INTO quiz_answer_keys (question_id,correct_answer) VALUES
('34100000-0000-4000-8000-000000000001','CPU'),('34100000-0000-4000-8000-000000000002','True');
INSERT INTO quiz_attempts (id,quiz_id,student_id,answers,score,max_score,status,submitted_at) VALUES
('34200000-0000-4000-8000-000000000001','34000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000011','{"34100000-0000-4000-8000-000000000001":"CPU","34100000-0000-4000-8000-000000000002":"True"}',10,10,'submitted',NOW());