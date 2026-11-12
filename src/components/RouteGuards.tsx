import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { useOneCampusSetup } from '../hooks/useOneCampusSetup'
import type { UserRole } from '../types/database'
import { ErrorState, LoadingState } from './ScreenState'

export function GuestOnlyRoute() {
  const { user, profile, loading } = useAuth()
  if (loading) return <FullScreenState><LoadingState label="Checking your session…" /></FullScreenState>
  if (user && profile) return <Navigate to="/dashboard" replace />
  return <Outlet />
}

export function SetupRequiredRoute() {
  const { configured, loading } = useOneCampusSetup()
  const location = useLocation()
  if (loading) return <FullScreenState><LoadingState label="Checking OneCampus database setup…" /></FullScreenState>
  if (!configured) return <Navigate to="/setup" replace state={{ from: location }} />
  return <Outlet />
}

export function ProtectedRoute() {
  const { user, profile, loading, error, refreshProfile } = useAuth()
  const location = useLocation()
  if (loading) return <FullScreenState><LoadingState label="Loading your account…" /></FullScreenState>
  if (!user) return <Navigate to="/login" replace state={{ from: location }} />
  if (error || !profile) {
    return <FullScreenState><ErrorState message={error ?? 'No profile is linked to this account.'} onRetry={() => void refreshProfile()} /></FullScreenState>
  }
  return <Outlet />
}

export function RoleRoute({ allowed }: { allowed: UserRole[] }) {
  const { profile } = useAuth()
  if (!profile || !allowed.includes(profile.role)) return <Navigate to="/dashboard" replace />
  return <Outlet />
}

function FullScreenState({ children }: { children: React.ReactNode }) {
  return <main className="grid min-h-screen place-items-center bg-slate-50 p-6">{children}</main>
}