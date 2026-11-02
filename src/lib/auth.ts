import type { UserRole } from '../types/database'

export type LoginPortal = UserRole

export const pendingRoleCheckKey = 'adfc-lms-pending-role-check'

export const roleLabels: Record<LoginPortal, string> = {
  student: 'Student',
  instructor: 'Instructor',
  admin: 'Administrator',
}