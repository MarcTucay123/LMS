import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AppLayout } from './components/AppLayout'
import { AuthLayout } from './components/AuthLayout'
import { GuestOnlyRoute, ProtectedRoute, RoleRoute } from './components/RouteGuards'
import { AuthProvider } from './hooks/useAuth'
import { ActivatePage } from './pages/ActivatePage'
import { ClassPage } from './pages/ClassPage'
import { ClassesPage } from './pages/ClassesPage'
import { DashboardPage } from './pages/DashboardPage'
import { LoginPage } from './pages/LoginPage'
import { NotFoundPage } from './pages/NotFoundPage'
import { WorkspacePage } from './pages/WorkspacePage'
import { AdminClassesPage } from './pages/admin/AdminClassesPage'
import { AdminSyncPage } from './pages/admin/AdminSyncPage'
import { AdminUsersPage } from './pages/admin/AdminUsersPage'

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route element={<GuestOnlyRoute />}>
            <Route element={<AuthLayout />}>
              <Route path="/login" element={<LoginPage />} />
              <Route path="/activate" element={<ActivatePage />} />
            </Route>
          </Route>
          <Route element={<ProtectedRoute />}>
            <Route element={<AppLayout />}>
              <Route path="/dashboard" element={<DashboardPage />} />
              <Route path="/classes" element={<ClassesPage />} />
              <Route path="/classes/:classId" element={<ClassPage />} />
              <Route path="/workspace/:section" element={<WorkspacePage />} />
              <Route element={<RoleRoute allowed={['admin']} />}>
                <Route path="/admin/users" element={<AdminUsersPage />} />
                <Route path="/admin/classes" element={<AdminClassesPage />} />
                <Route path="/admin/sync" element={<AdminSyncPage />} />
              </Route>
            </Route>
          </Route>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}