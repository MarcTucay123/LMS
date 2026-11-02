export type UserRole = 'student' | 'instructor' | 'admin'
export type AccountStatus = 'pending' | 'active' | 'inactive'
export type EnrollmentStatus = 'enrolled' | 'dropped' | 'completed'
export type PublishStatus = 'draft' | 'published' | 'closed'
export type SubmissionStatus = 'draft' | 'submitted' | 'graded'
export type AttemptStatus = 'in_progress' | 'submitted'

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          onecampus_user_id: string | null
          school_id: string
          email: string
          full_name: string
          role: UserRole
          status: AccountStatus
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          onecampus_user_id?: string | null
          school_id: string
          email: string
          full_name: string
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
          code: string
          title: string
          description: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          onecampus_subject_id?: string | null
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
          class_id: string
          student_id: string
          status: EnrollmentStatus
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          onecampus_enrollment_id?: string | null
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
          source: 'mock' | 'onecampus_api'
          status: 'running' | 'success' | 'failed'
          records: Json
          message: string | null
          started_at: string
          completed_at: string | null
        }
        Insert: {
          id?: string
          initiated_by?: string | null
          source: 'mock' | 'onecampus_api'
          status: 'running' | 'success' | 'failed'
          records?: Json
          message?: string | null
          started_at?: string
          completed_at?: string | null
        }
        Update: Partial<Database['public']['Tables']['sync_logs']['Insert']>
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
        Row: { id: string; class_id: string; title: string; body: string; created_by: string; is_locked: boolean; created_at: string; updated_at: string }
        Insert: { id?: string; class_id: string; title: string; body: string; created_by?: string; is_locked?: boolean; created_at?: string; updated_at?: string }
        Update: Partial<Database['public']['Tables']['discussion_topics']['Insert']>
        Relationships: []
      }
      discussion_posts: {
        Row: { id: string; topic_id: string; author_id: string; body: string; created_at: string; updated_at: string }
        Insert: { id?: string; topic_id: string; author_id?: string; body: string; created_at?: string; updated_at?: string }
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
        Row: { id: string; class_id: string; title: string; description: string | null; opens_at: string | null; closes_at: string | null; time_limit_minutes: number | null; status: PublishStatus; created_by: string; created_at: string; updated_at: string }
        Insert: { id?: string; class_id: string; title: string; description?: string | null; opens_at?: string | null; closes_at?: string | null; time_limit_minutes?: number | null; status?: PublishStatus; created_by?: string; created_at?: string; updated_at?: string }
        Update: Partial<Database['public']['Tables']['quizzes']['Insert']>
        Relationships: []
      }
      quiz_questions: {
        Row: { id: string; quiz_id: string; prompt: string; question_type: 'multiple_choice' | 'true_false' | 'short_answer'; options: Json; points: number; position: number; created_at: string }
        Insert: { id?: string; quiz_id: string; prompt: string; question_type: 'multiple_choice' | 'true_false' | 'short_answer'; options?: Json; points?: number; position?: number; created_at?: string }
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
        Row: { id: string; quiz_id: string; student_id: string; answers: Json; score: number | null; max_score: number | null; status: AttemptStatus; started_at: string; submitted_at: string | null }
        Insert: { id?: string; quiz_id: string; student_id?: string; answers?: Json; score?: number | null; max_score?: number | null; status?: AttemptStatus; started_at?: string; submitted_at?: string | null }
        Update: Partial<Database['public']['Tables']['quiz_attempts']['Insert']>
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
      admin_approve_registration: {
        Args: { target_application_id: string; assigned_class_ids?: string[] }
        Returns: Database['public']['Tables']['profiles']['Row']
      }
      admin_reject_registration: {
        Args: { target_application_id: string }
        Returns: Database['public']['Tables']['registration_applications']['Row']
      }
      current_user_role: { Args: Record<string, never>; Returns: UserRole }
      is_admin: { Args: Record<string, never>; Returns: boolean }
      is_active_admin: { Args: Record<string, never>; Returns: boolean }
      can_access_class: { Args: { target_class_id: string }; Returns: boolean }
      can_view_profile: { Args: { target_profile_id: string }; Returns: boolean }
      can_manage_class: { Args: { target_class_id: string }; Returns: boolean }
      submit_assignment: { Args: { target_assignment_id: string; submission_content: string; submission_file_path: string }; Returns: Database['public']['Tables']['submissions']['Row'] }
      grade_submission: { Args: { target_submission_id: string; awarded_grade: number; grading_feedback: string }; Returns: Database['public']['Tables']['submissions']['Row'] }
      submit_quiz: { Args: { target_quiz_id: string; submitted_answers: Json }; Returns: Database['public']['Tables']['quiz_attempts']['Row'] }
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

export interface ClassSummary {
  id: string
  instructor_id?: string
  section: string
  school_year: string
  semester: string
  status: string
  subject: { code: string; title: string } | null
  instructor: { full_name: string } | null
}