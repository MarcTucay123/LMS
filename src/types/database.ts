export type UserRole = 'student' | 'instructor' | 'admin'
export type AccountStatus = 'pending' | 'active' | 'inactive'
export type EnrollmentStatus = 'enrolled' | 'dropped' | 'completed'
export type PublishStatus = 'draft' | 'published' | 'closed'
export type SubmissionStatus = 'draft' | 'submitted' | 'graded'
export type AttemptStatus = 'in_progress' | 'submitted'
export type AssessmentKind = 'quiz' | 'exam'
export type LearningItemType = 'material' | 'assignment' | 'quiz' | 'exam' | 'discussion'
export type LiveQuizStatus = 'scheduled' | 'lobby' | 'active' | 'paused' | 'completed' | 'cancelled'

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]
export type DiscussionReadReceipt = { post_id: string; user_id: string; full_name: string; avatar_path: string | null; last_read_at: string }

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          onecampus_user_id: string | null
          source_system: string
          synced_at: string | null
          school_id: string
          email: string
          full_name: string
          avatar_path: string | null
          first_name: string | null
          middle_name: string | null
          last_name: string | null
          suffix: string | null
          class_code: string | null
          program: string | null
          year_level: number | null
          block: string | null
          academic_year: string | null
          semester: string | null
          role: UserRole
          status: AccountStatus
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          onecampus_user_id?: string | null
          source_system?: string
          synced_at?: string | null
          school_id: string
          email: string
          full_name: string
          avatar_path?: string | null
          first_name?: string | null
          middle_name?: string | null
          last_name?: string | null
          suffix?: string | null
          class_code?: string | null
          program?: string | null
          year_level?: number | null
          block?: string | null
          academic_year?: string | null
          semester?: string | null
          role?: UserRole
          status?: AccountStatus
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['profiles']['Insert']>
        Relationships: []
      }
      subjects: {
        Row: {
          id: string
          onecampus_subject_id: string | null
          source_system: string
          synced_at: string | null
          code: string
          title: string
          description: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          onecampus_subject_id?: string | null
          source_system?: string
          synced_at?: string | null
          code: string
          title: string
          description?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['subjects']['Insert']>
        Relationships: []
      }
      classes: {
        Row: {
          id: string
          onecampus_class_id: string | null
          source_system: string
          synced_at: string | null
          subject_id: string
          instructor_id: string
          section: string
          school_year: string
          semester: string
          status: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          onecampus_class_id?: string | null
          source_system?: string
          synced_at?: string | null
          subject_id: string
          instructor_id: string
          section: string
          school_year: string
          semester: string
          status?: string
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['classes']['Insert']>
        Relationships: []
      }
      enrollments: {
        Row: {
          id: string
          onecampus_enrollment_id: string | null
          source_system: string
          synced_at: string | null
          class_id: string
          student_id: string
          status: EnrollmentStatus
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          onecampus_enrollment_id?: string | null
          source_system?: string
          synced_at?: string | null
          class_id: string
          student_id: string
          status?: EnrollmentStatus
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['enrollments']['Insert']>
        Relationships: []
      }
      activation_records: {
        Row: {
          id: string
          onecampus_user_id: string
          school_id: string
          email: string
          full_name: string
          role: UserRole
          auth_user_id: string | null
          activated_at: string | null
          created_at: string
        }
        Insert: {
          id?: string
          onecampus_user_id: string
          school_id: string
          email: string
          full_name: string
          role: UserRole
          auth_user_id?: string | null
          activated_at?: string | null
          created_at?: string
        }
        Update: Partial<Database['public']['Tables']['activation_records']['Insert']>
        Relationships: []
      }
      registration_applications: {
        Row: {
          id: string
          auth_user_id: string
          email: string
          full_name: string
          first_name: string
          middle_name: string | null
          last_name: string
          suffix: string | null
          student_id_number: string | null
          class_code: string | null
          program: string | null
          year_level: number | null
          block: string | null
          academic_year: string | null
          semester: string | null
          selected_class_ids: string[]
          terms_accepted_at: string | null
          requested_role: UserRole
          status: 'pending' | 'approved' | 'rejected'
          reviewed_by: string | null
          reviewed_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          auth_user_id: string
          email: string
          full_name: string
          first_name: string
          middle_name?: string | null
          last_name: string
          suffix?: string | null
          student_id_number?: string | null
          class_code?: string | null
          program?: string | null
          year_level?: number | null
          block?: string | null
          academic_year?: string | null
          semester?: string | null
          selected_class_ids?: string[]
          terms_accepted_at?: string | null
          requested_role: UserRole
          status?: 'pending' | 'approved' | 'rejected'
          reviewed_by?: string | null
          reviewed_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['registration_applications']['Insert']>
        Relationships: []
      }
      sync_logs: {
        Row: {
          id: string
          initiated_by: string | null
          source: 'mock' | 'onecampus_api' | 'onecampus_database'
          status: 'running' | 'success' | 'failed'
          records: Json
          message: string | null
          started_at: string
          completed_at: string | null
        }
        Insert: {
          id?: string
          initiated_by?: string | null
          source: 'mock' | 'onecampus_api' | 'onecampus_database'
          status: 'running' | 'success' | 'failed'
          records?: Json
          message?: string | null
          started_at?: string
          completed_at?: string | null
        }
        Update: Partial<Database['public']['Tables']['sync_logs']['Insert']>
        Relationships: []
      }
      audit_logs: {
        Row: { id: number; module_code: string; actor_name: string | null; actor_role: string | null; action: string; record_type: string | null; record_label: string | null; description: string | null; ip_address: string | null; created_at: string }
        Insert: never
        Update: never
        Relationships: []
      }
      materials: {
        Row: { id: string; class_id: string; title: string; description: string | null; file_path: string | null; external_url: string | null; created_by: string; created_at: string; updated_at: string }
        Insert: { id?: string; class_id: string; title: string; description?: string | null; file_path?: string | null; external_url?: string | null; created_by?: string; created_at?: string; updated_at?: string }
        Update: Partial<Database['public']['Tables']['materials']['Insert']>
        Relationships: []
      }
      announcements: {
        Row: { id: string; class_id: string; title: string; body: string; created_by: string; created_at: string; updated_at: string }
        Insert: { id?: string; class_id: string; title: string; body: string; created_by?: string; created_at?: string; updated_at?: string }
        Update: Partial<Database['public']['Tables']['announcements']['Insert']>
        Relationships: []
      }
      discussion_topics: {
        Row: { id: string; class_id: string; title: string; body: string; created_by: string; is_locked: boolean; is_pinned: boolean; pinned_by: string | null; pinned_at: string | null; created_at: string; updated_at: string }
        Insert: { id?: string; class_id: string; title: string; body: string; created_by?: string; is_locked?: boolean; is_pinned?: boolean; pinned_by?: string | null; pinned_at?: string | null; created_at?: string; updated_at?: string }
        Update: Partial<Database['public']['Tables']['discussion_topics']['Insert']>
        Relationships: []
      }
      discussion_posts: {
        Row: { id: string; topic_id: string; author_id: string; body: string; attachment_path: string | null; attachment_name: string | null; attachment_mime: string | null; attachment_size: number | null; attachment_kind: 'file' | 'image' | 'video' | 'audio' | null; reply_to_id: string | null; is_pinned: boolean; pinned_by: string | null; pinned_at: string | null; is_deleted: boolean; deleted_at: string | null; deleted_by: string | null; created_at: string; updated_at: string }
        Insert: { id?: string; topic_id: string; author_id?: string; body?: string; attachment_path?: string | null; attachment_name?: string | null; attachment_mime?: string | null; attachment_size?: number | null; attachment_kind?: 'file' | 'image' | 'video' | 'audio' | null; reply_to_id?: string | null; is_pinned?: boolean; pinned_by?: string | null; pinned_at?: string | null; is_deleted?: boolean; deleted_at?: string | null; deleted_by?: string | null; created_at?: string; updated_at?: string }
        Update: Partial<Database['public']['Tables']['discussion_posts']['Insert']>
        Relationships: []
      }
      assignments: {
        Row: { id: string; class_id: string; title: string; instructions: string; due_at: string | null; points: number; status: PublishStatus; created_by: string; created_at: string; updated_at: string }
        Insert: { id?: string; class_id: string; title: string; instructions: string; due_at?: string | null; points?: number; status?: PublishStatus; created_by?: string; created_at?: string; updated_at?: string }
        Update: Partial<Database['public']['Tables']['assignments']['Insert']>
        Relationships: []
      }
      submissions: {
        Row: { id: string; assignment_id: string; student_id: string; content: string | null; file_path: string | null; status: SubmissionStatus; submitted_at: string; grade: number | null; feedback: string | null; graded_by: string | null; graded_at: string | null; updated_at: string }
        Insert: { id?: string; assignment_id: string; student_id?: string; content?: string | null; file_path?: string | null; status?: SubmissionStatus; submitted_at?: string; grade?: number | null; feedback?: string | null; graded_by?: string | null; graded_at?: string | null; updated_at?: string }
        Update: Partial<Database['public']['Tables']['submissions']['Insert']>
        Relationships: []
      }
      quizzes: {
        Row: { id: string; class_id: string; title: string; description: string | null; attachment_path: string | null; attachment_name: string | null; file_submission_points: number; assessment_kind: AssessmentKind; exam_type: string | null; opens_at: string | null; closes_at: string | null; time_limit_minutes: number | null; status: PublishStatus; created_by: string; created_at: string; updated_at: string }
        Insert: { id?: string; class_id: string; title: string; description?: string | null; attachment_path?: string | null; attachment_name?: string | null; file_submission_points?: number; assessment_kind?: AssessmentKind; exam_type?: string | null; opens_at?: string | null; closes_at?: string | null; time_limit_minutes?: number | null; status?: PublishStatus; created_by?: string; created_at?: string; updated_at?: string }
        Update: Partial<Database['public']['Tables']['quizzes']['Insert']>
        Relationships: []
      }
      quiz_questions: {
        Row: { id: string; quiz_id: string; prompt: string; question_type: 'multiple_choice' | 'true_false' | 'identification' | 'essay'; options: Json; points: number; position: number; created_at: string }
        Insert: { id?: string; quiz_id: string; prompt: string; question_type: 'multiple_choice' | 'true_false' | 'identification' | 'essay'; options?: Json; points?: number; position?: number; created_at?: string }
        Update: Partial<Database['public']['Tables']['quiz_questions']['Insert']>
        Relationships: []
      }
      quiz_answer_keys: {
        Row: { question_id: string; correct_answer: string; case_sensitive: boolean }
        Insert: { question_id: string; correct_answer: string; case_sensitive?: boolean }
        Update: Partial<Database['public']['Tables']['quiz_answer_keys']['Insert']>
        Relationships: []
      }
      quiz_attempts: {
        Row: { id: string; quiz_id: string; student_id: string; answers: Json; essay_scores: Json; submission_file_path: string | null; submission_file_name: string | null; submission_file_score: number | null; score: number | null; max_score: number | null; status: AttemptStatus; started_at: string; submitted_at: string | null }
        Insert: { id?: string; quiz_id: string; student_id?: string; answers?: Json; essay_scores?: Json; submission_file_path?: string | null; submission_file_name?: string | null; submission_file_score?: number | null; score?: number | null; max_score?: number | null; status?: AttemptStatus; started_at?: string; submitted_at?: string | null }
        Update: Partial<Database['public']['Tables']['quiz_attempts']['Insert']>
        Relationships: []
      }
      quiz_live_sessions: {
        Row: { id: string; quiz_id: string; class_id: string; meeting_id: number | null; scheduled_start: string | null; mode: 'instructor_paced'; status: LiveQuizStatus; current_question_id: string | null; question_time_seconds: number | null; question_opened_at: string | null; show_correct_answer: boolean; show_leaderboard: boolean; randomize_choices: boolean; started_at: string | null; ended_at: string | null; created_by: string; created_at: string; updated_at: string; quiz_title?: string; assessment_kind?: AssessmentKind; participant_count?: number; response_count?: number }
        Insert: never
        Update: never
        Relationships: []
      }
      quiz_live_participants: {
        Row: { id: string; session_id: string; student_id: number; status: 'connected' | 'active' | 'submitted' | 'disconnected'; joined_at: string; last_seen_at: string; completed_at: string | null }
        Insert: never
        Update: never
        Relationships: []
      }
      quiz_live_responses: {
        Row: { id: string; session_id: string; question_id: string; student_id: number; answer: string; is_correct: boolean | null; points_awarded: number; response_time_ms: number | null; submitted_at: string }
        Insert: never
        Update: never
        Relationships: []
      }
      learning_modules: {
        Row: { id: string; class_id: string; title: string; description: string | null; position: number; opens_at: string | null; due_at: string | null; status: PublishStatus; prerequisite_module_id: string | null; created_by: string; created_at: string; updated_at: string }
        Insert: { id?: string; class_id: string; title: string; description?: string | null; position?: number; opens_at?: string | null; due_at?: string | null; status?: PublishStatus; prerequisite_module_id?: string | null; created_by?: string; created_at?: string; updated_at?: string }
        Update: Partial<Database['public']['Tables']['learning_modules']['Insert']>
        Relationships: []
      }
      learning_module_items: {
        Row: { id: string; module_id: string; item_type: LearningItemType; item_id: string; title_override: string | null; position: number; is_required: boolean; estimated_minutes: number | null; created_by: string; created_at: string; updated_at: string; is_completed: boolean }
        Insert: { id?: string; module_id: string; item_type: LearningItemType; item_id: string; title_override?: string | null; position?: number; is_required?: boolean; estimated_minutes?: number | null; created_by?: string; created_at?: string; updated_at?: string }
        Update: Partial<Database['public']['Tables']['learning_module_items']['Insert']>
        Relationships: []
      }
    }
    Views: Record<string, never>
    Functions: {
      admin_update_user: {
        Args: {
          target_user_id: string
          target_role: UserRole
          target_status: AccountStatus
        }
        Returns: Database['public']['Tables']['profiles']['Row']
      }
      get_security_settings: {
        Args: Record<string, never>
        Returns: SecuritySettings
      }
      admin_update_security_settings: {
        Args: SecuritySettings
        Returns: SecuritySettings
      }
      get_class_notification_counts: {
        Args: { seen_at: Json }
        Returns: ClassNotificationCounts[]
      }
      toggle_discussion_reaction: { Args: { target_post_id: string; emoji: string }; Returns: { post_id: string; emoji: string | null } }
      mark_discussion_read: { Args: { target_topic_id: string; target_post_id: string | null }; Returns: DiscussionReadReceipt[] }
      join_discussion: { Args: { target_topic_id: string }; Returns: { topic_id: string; is_joined: boolean } }
      leave_discussion: { Args: { target_topic_id: string }; Returns: { topic_id: string; is_joined: boolean } }
      set_discussion_mute: { Args: { target_topic_id: string; duration: 'one_hour' | 'eight_hours' | 'one_day' | 'until_unmuted' | 'unmute' }; Returns: { topic_id: string; muted_until: string | null } }
      discussion_live_call_status: { Args: { target_topic_id: string }; Returns: DiscussionCallStatus | null }
      discussion_live_session_history: { Args: { target_class_id: string }; Returns: DiscussionLiveSessionHistory[] }
      current_user_role: { Args: Record<string, never>; Returns: UserRole }
      is_admin: { Args: Record<string, never>; Returns: boolean }
      is_active_admin: { Args: Record<string, never>; Returns: boolean }
      can_access_class: { Args: { target_class_id: string }; Returns: boolean }
      can_view_profile: { Args: { target_profile_id: string }; Returns: boolean }
      can_manage_class: { Args: { target_class_id: string }; Returns: boolean }
      submit_assignment: { Args: { target_assignment_id: string; submission_content: string; submission_file_path: string }; Returns: Database['public']['Tables']['submissions']['Row'] }
      grade_submission: { Args: { target_submission_id: string; awarded_grade: number; grading_feedback: string }; Returns: Database['public']['Tables']['submissions']['Row'] }
      update_quiz_question: { Args: { target_question_id: string; question_prompt: string; question_type: 'multiple_choice' | 'true_false' | 'identification' | 'essay'; question_options: Json; question_points: number; correct_answer: string }; Returns: Database['public']['Tables']['quiz_questions']['Row'] }
      grade_quiz_essay: { Args: { target_attempt_id: string; target_question_id: string; awarded_points: number }; Returns: Database['public']['Tables']['quiz_attempts']['Row'] }
      grade_quiz_file: { Args: { target_attempt_id: string; awarded_points: number }; Returns: Database['public']['Tables']['quiz_attempts']['Row'] }
      start_quiz: { Args: { target_quiz_id: string }; Returns: Database['public']['Tables']['quiz_attempts']['Row'] }
      submit_quiz: { Args: { target_quiz_id: string; submitted_answers: Json; submission_file_path: string; submission_file_name: string }; Returns: Database['public']['Tables']['quiz_attempts']['Row'] }
      set_quiz_attachment: { Args: { target_quiz_id: string; attachment_path: string; attachment_name: string }; Returns: Database['public']['Tables']['quizzes']['Row'] }
      remove_quiz_submission_file: { Args: { target_attempt_id: string }; Returns: Database['public']['Tables']['quiz_attempts']['Row'] }
      list_live_quiz_sessions: { Args: { target_class_id: string; assessment_kind: AssessmentKind }; Returns: Database['public']['Tables']['quiz_live_sessions']['Row'][] }
      create_live_quiz_session: { Args: { target_quiz_id: string; meeting_id: number | null; scheduled_start: string | null; question_time_seconds: number; show_correct_answer: boolean; show_leaderboard: boolean; randomize_choices: boolean }; Returns: Database['public']['Tables']['quiz_live_sessions']['Row'] }
      live_quiz_state: { Args: { target_session_id: string }; Returns: LiveQuizState }
      join_live_quiz_session: { Args: { target_session_id: string }; Returns: LiveQuizState }
      control_live_quiz_session: { Args: { target_session_id: string; session_action: 'open_lobby' | 'start' | 'pause' | 'resume' | 'complete' | 'cancel' }; Returns: LiveQuizState }
      submit_live_quiz_answer: { Args: { target_session_id: string; submitted_answer: string }; Returns: LiveQuizState }
      set_learning_item_complete: { Args: { target_module_item_id: string; completed: boolean }; Returns: { module_item_id: string; completed: boolean } }
      discussion_live_state: { Args: { target_topic_id: string; after_signal_id: number }; Returns: DiscussionLiveState }
      start_discussion_live_session: { Args: { target_topic_id: string }; Returns: DiscussionLiveState }
      join_discussion_live_session: { Args: { target_session_id: string }; Returns: DiscussionLiveState }
      update_discussion_live_presence: { Args: { target_session_id: string; mic_muted: boolean; camera_enabled: boolean; screen_sharing: boolean; is_attending: boolean; after_signal_id: number }; Returns: DiscussionLiveState }
      leave_discussion_live_session: { Args: { target_session_id: string }; Returns: { left: boolean } }
      end_discussion_live_session: { Args: { target_session_id: string }; Returns: { ended: boolean } }
      send_discussion_live_signal: { Args: { target_session_id: string; recipient_id: string; signal_type: 'offer' | 'answer' | 'ice'; payload: Json }; Returns: { sent: boolean } }
      post_discussion_live_event: { Args: { target_session_id: string; event_type: 'comment' | 'reaction'; content: string; attachment_path?: string; attachment_name?: string; attachment_mime?: string; attachment_size?: number; attachment_kind?: 'image' | 'file' }; Returns: { posted: boolean } }
    }
    Enums: {
      user_role: UserRole
      account_status: AccountStatus
      enrollment_status: EnrollmentStatus
      publish_status: PublishStatus
      submission_status: SubmissionStatus
      attempt_status: AttemptStatus
    }
    CompositeTypes: Record<string, never>
  }
}

export type Profile = Database['public']['Tables']['profiles']['Row']
export type RegistrationApplication = Database['public']['Tables']['registration_applications']['Row']

export interface SecuritySettings {
  max_login_attempts: number
  lockout_minutes: number
  inactivity_timeout_minutes: number
  live_attendance_minimized_enabled: boolean
  live_attendance_tab_hidden_enabled: boolean
  live_attendance_window_blur_enabled: boolean
  live_attendance_inactivity_enabled: boolean
  live_attendance_inactivity_seconds: number
}

export interface ClassSummary {
  id: string
  instructor_id?: string
  section: string
  school_year: string
  semester: string
  status: string
  enrolled_student_count: number
  subject: { code: string; title: string } | null
  instructor: { full_name: string; avatar_path: string | null } | null
  schedule: ClassScheduleMeeting[]
}

export interface ClassScheduleMeeting {
  meeting_id: number
  class_type: 'LEC' | 'LAB'
  day_of_week: string
  start_time: string
  end_time: string
  room_code: string
  building: string
}

export type ClassNotificationSection = 'materials' | 'assignments' | 'quizzes' | 'exams' | 'discussions' | 'announcements' | 'progress'

export interface ClassNotificationCounts extends Record<ClassNotificationSection, number> {
  class_id: string
  total: number
  unread_items: Record<ClassNotificationSection, string[]>
}

export interface LiveQuizResult {
  student_id?: number
  rank?: number
  student_name?: string
  student_number?: string
  avatar_path?: string | null
  score: number
  max_score: number
  answered_count: number
}

export interface LiveQuizState {
  session: Database['public']['Tables']['quiz_live_sessions']['Row'] & { quiz_title: string; quiz_description: string | null; assessment_kind: AssessmentKind }
  questions: Database['public']['Tables']['quiz_questions']['Row'][]
  participant: Omit<Database['public']['Tables']['quiz_live_participants']['Row'], 'id' | 'session_id' | 'student_id'> | null
  my_responses: Pick<Database['public']['Tables']['quiz_live_responses']['Row'], 'question_id' | 'answer' | 'is_correct' | 'points_awarded' | 'submitted_at'>[]
  participant_count: number
  response_count: number
  enrolled_count: number
  joined_student_ids: string[]
  results: LiveQuizResult[]
}

export interface LiveQuizLobbyStatus {
  session_id: string
  joined_student_ids: string[]
}

export interface DiscussionLiveParticipant {
  user_id: string
  full_name: string
  avatar_path: string | null
  mic_muted: boolean
  camera_enabled: boolean
  screen_sharing: boolean
  is_attending: boolean
  is_host: boolean
  joined_at: string
  last_seen_at: string
}

export interface DiscussionCallAttendance {
  user_id: string
  full_name: string
  school_id: string
  avatar_path: string | null
  attendance_status: 'active' | 'inactive' | 'not_joined'
  screen_sharing: boolean
  joined_at: string | null
  last_seen_at: string | null
}

export interface DiscussionLiveEvent {
  id: number
  user_id: string
  full_name: string
  avatar_path: string | null
  event_type: 'comment' | 'reaction'
  content: string
  attachment_path: string | null
  attachment_name: string | null
  attachment_mime: string | null
  attachment_size: number | null
  attachment_kind: 'image' | 'file' | null
  created_at: string
}

export interface DiscussionLiveSignal {
  id: number
  sender_id: string
  signal_type: 'offer' | 'answer' | 'ice'
  payload: Json
  created_at: string
}

export interface DiscussionLiveState {
  session: { id: string; topic_id: string; class_id: string; topic_title: string; status: 'active' | 'ended'; created_by: string; started_at: string; ended_at: string | null } | null
  participants: DiscussionLiveParticipant[]
  attendance_roster: DiscussionCallAttendance[]
  events: DiscussionLiveEvent[]
  signals: DiscussionLiveSignal[]
  is_host: boolean
  joined: boolean
  can_manage: boolean
  attendance_settings: LiveCallAttendanceSettings
}

export type LiveCallAttendanceSettings = Pick<SecuritySettings,
  | 'live_attendance_minimized_enabled'
  | 'live_attendance_tab_hidden_enabled'
  | 'live_attendance_window_blur_enabled'
  | 'live_attendance_inactivity_enabled'
  | 'live_attendance_inactivity_seconds'
>

export interface DiscussionCallStatus {
  id: string
  topic_id: string
  created_by: string
  started_at: string
  host_name: string
  host_avatar_path: string | null
  participant_count: number
  is_host: boolean
}

export interface DiscussionLiveSessionHistoryAttendance {
  student_id: number
  user_id: string | null
  full_name: string
  school_id: string
  avatar_path: string | null
  attendance_status: 'active' | 'inactive' | 'not_joined'
  joined_at: string | null
  last_seen_at: string | null
  recorded_at: string
}

export interface DiscussionLiveSessionHistory {
  id: string
  topic_id: string
  topic_title: string
  host_name: string
  host_avatar_path: string | null
  started_at: string
  ended_at: string
  active_count: number
  inactive_count: number
  not_joined_count: number
  can_manage: boolean
  attendance: DiscussionLiveSessionHistoryAttendance[]
  events: DiscussionLiveEvent[]
}
