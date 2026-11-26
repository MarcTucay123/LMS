import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AppLayout } from './components/AppLayout'
import { AuthLayout } from './components/AuthLayout'
import { GuestOnlyRoute, ProtectedRoute, RoleRoute, SetupRequiredRoute } from './components/RouteGuards'
import { ScrollToTopButton } from './components/ScrollToTopButton'
import { ConfirmationDialogProvider } from './components/ConfirmationDialogProvider'
import { AuthProvider } from './hooks/useAuth'
import { ClassNotificationProvider } from './hooks/useClassNotifications'
import { DiscussionCallProvider } from './hooks/useDiscussionCall'
import { OneCampusSetupProvider } from './hooks/useOneCampusSetup'
import { ThemeProvider } from './hooks/useTheme'
import { ClassPage } from './pages/ClassPage'
import { ClassesPage } from './pages/ClassesPage'
import { DashboardPage } from './pages/DashboardPage'
import { ForgotPasswordPage } from './pages/ForgotPasswordPage'
import { LoginPage } from './pages/LoginPage'
import { OneCampusSetupPage } from './pages/OneCampusSetupPage'
import { NotFoundPage } from './pages/NotFoundPage'
import { ProfileSettingsPage } from './pages/ProfileSettingsPage'
import { ResetPasswordPage } from './pages/ResetPasswordPage'
import { WorkspacePage } from './pages/WorkspacePage'
import { StudentTodoPage } from './pages/StudentTodoPage'
import { AdminClassesPage } from './pages/admin/AdminClassesPage'
import { AdminSyncPage } from './pages/admin/AdminSyncPage'
import { AdminUsersPage } from './pages/admin/AdminUsersPage'
import { AdminAuditLogsPage } from './pages/admin/AdminAuditLogsPage'
import { AdminUserControlPage } from './pages/admin/AdminUserControlPage'

export default function App() {
  return (
    <ThemeProvider>
    <ConfirmationDialogProvider>
    <BrowserRouter basename={import.meta.env.BASE_URL}>
      <OneCampusSetupProvider>
        <AuthProvider>
          <ClassNotificationProvider>
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
            <Route element={<DiscussionCallProvider><AppLayout /></DiscussionCallProvider>}>
              <Route path="/dashboard" element={<DashboardPage />} />
              <Route path="/profile-settings" element={<ProfileSettingsPage />} />
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
                <Route path="/admin/user-control" element={<AdminUserControlPage />} />
              </Route>
            </Route>
          </Route>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          </Route>
          <Route path="*" element={<NotFoundPage />} />
          </Routes>
          <ScrollToTopButton />
          </ClassNotificationProvider>
        </AuthProvider>
      </OneCampusSetupProvider>
    </BrowserRouter>
    </ConfirmationDialogProvider>
    </ThemeProvider>
  )
}