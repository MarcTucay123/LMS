import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AppLayout } from './components/AppLayout'
import { AuthLayout } from './components/AuthLayout'
import { GuestOnlyRoute, ProtectedRoute, RoleRoute, SetupRequiredRoute } from './components/RouteGuards'
import { AuthProvider } from './hooks/useAuth'
import { OneCampusSetupProvider } from './hooks/useOneCampusSetup'
import { ClassPage } from './pages/ClassPage'
import { ClassesPage } from './pages/ClassesPage'
import { DashboardPage } from './pages/DashboardPage'
import { ForgotPasswordPage } from './pages/ForgotPasswordPage'
import { LoginPage } from './pages/LoginPage'
import { OneCampusSetupPage } from './pages/OneCampusSetupPage'
import { NotFoundPage } from './pages/NotFoundPage'
import { ResetPasswordPage } from './pages/ResetPasswordPage'
import { WorkspacePage } from './pages/WorkspacePage'
import { StudentTodoPage } from './pages/StudentTodoPage'
import { AdminClassesPage } from './pages/admin/AdminClassesPage'
import { AdminSyncPage } from './pages/admin/AdminSyncPage'
import { AdminUsersPage } from './pages/admin/AdminUsersPage'
import { AdminAuditLogsPage } from './pages/admin/AdminAuditLogsPage'

export default function App() {
  return (
    <BrowserRouter basename={import.meta.env.BASE_URL}>
      <OneCampusSetupProvider>
        <AuthProvider>
          <Routes>
          <Route path="/setup" element={<OneCampusSetupPage />} />
          <Route element={<SetupRequiredRoute />}>
          <Route element={<GuestOnlyRoute />}>
            <Route element={<AuthLayout />}>
              <Route path="/login" element={<LoginPage />} />
              <Route path="/forgot-password" element={<ForgotPasswordPage />} />
              <Route path="/register/:role" element={<Navigate to="/login" replace />} />
              <Route path="/register" element={<Navigate to="/login" replace />} />
              <Route path="/activate" element={<Navigate to="/login" replace />} />
            </Route>
          </Route>
          <Route element={<AuthLayout />}>
            <Route path="/reset-password" element={<ResetPasswordPage />} />
          </Route>
          <Route element={<ProtectedRoute />}>
            <Route element={<AppLayout />}>
              <Route path="/dashboard" element={<DashboardPage />} />
              <Route path="/classes" element={<ClassesPage />} />
              <Route path="/classes/:classId" element={<ClassPage />} />
              <Route path="/workspace/:section" element={<WorkspacePage />} />
              <Route element={<RoleRoute allowed={['student']} />}>
                <Route path="/to-do" element={<StudentTodoPage />} />
              </Route>
              <Route element={<RoleRoute allowed={['admin']} />}>
                <Route path="/admin/users" element={<AdminUsersPage />} />
                <Route path="/admin/registrations" element={<Navigate to="/admin/users" replace />} />
                <Route path="/admin/classes" element={<AdminClassesPage />} />
                <Route path="/admin/sync" element={<AdminSyncPage />} />
                <Route path="/admin/audit-logs" element={<AdminAuditLogsPage />} />
              </Route>
            </Route>
          </Route>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          </Route>
          <Route path="*" element={<NotFoundPage />} />
          </Routes>
        </AuthProvider>
      </OneCampusSetupProvider>
    </BrowserRouter>
  )
}