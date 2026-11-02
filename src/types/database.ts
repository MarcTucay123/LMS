export type UserRole = 'student' | 'instructor' | 'admin'
export type AccountStatus = 'pending' | 'active' | 'inactive'
export type EnrollmentStatus = 'enrolled' | 'dropped' | 'completed'

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
      current_user_role: { Args: Record<string, never>; Returns: UserRole }
      is_admin: { Args: Record<string, never>; Returns: boolean }
      is_active_admin: { Args: Record<string, never>; Returns: boolean }
      can_access_class: { Args: { target_class_id: string }; Returns: boolean }
      can_view_profile: { Args: { target_profile_id: string }; Returns: boolean }
    }
    Enums: {
      user_role: UserRole
      account_status: AccountStatus
      enrollment_status: EnrollmentStatus
    }
    CompositeTypes: Record<string, never>
  }
}

export type Profile = Database['public']['Tables']['profiles']['Row']

export interface ClassSummary {
  id: string
  section: string
  school_year: string
  semester: string
  status: string
  subject: { code: string; title: string } | null
  instructor: { full_name: string } | null
}