/* eslint-disable react-refresh/only-export-components -- provider and paired hook intentionally share this module */
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import type { LocalSession as Session, LocalUser as User } from '../lib/supabase'
import { inactivityLogoutKey, pendingRoleCheckKey } from '../lib/auth'
import { supabase } from '../lib/supabase'
import type { Profile } from '../types/database'

interface AuthContextValue {
  session: Session | null
  user: User | null
  profile: Profile | null
  loading: boolean
  error: string | null
  signOut: () => Promise<void>
  registerBeforeSignOut: (handler: () => void | Promise<void>) => () => void
  refreshProfile: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const beforeSignOutHandlers = useRef(new Set<() => void | Promise<void>>())

  const loadProfile = useCallback(async (userId: string) => {
    const { data, error: profileError } = await supabase.from('profiles').select('*').eq('id', userId).single()
    if (profileError) throw profileError
    if (data.status !== 'active') throw new Error('Your account is not active. Contact an administrator.')
    setProfile(data)
  }, [])

  const refreshProfile = useCallback(async () => {
    if (!session?.user.id) return
    setError(null)
    try {
      await loadProfile(session.user.id)
    } catch (caught) {
      setProfile(null)
      setError(caught instanceof Error ? caught.message : 'Unable to load your profile.')
    }
  }, [loadProfile, session])

  const registerBeforeSignOut = useCallback((handler: () => void | Promise<void>) => {
    beforeSignOutHandlers.current.add(handler)
    return () => { beforeSignOutHandlers.current.delete(handler) }
  }, [])

  const signOut = useCallback(async () => {
    await Promise.allSettled(Array.from(beforeSignOutHandlers.current, (handler) => handler()))
    await supabase.auth.signOut()
  }, [])

  useEffect(() => {
    let active = true

    const initialize = async () => {
      const { data, error: sessionError } = await supabase.auth.getSession()
      if (!active) return
      if (sessionError) {
        setError(sessionError.message)
        setLoading(false)
        return
      }
      setSession(data.session)
      if (data.session) {
        try {
          await loadProfile(data.session.user.id)
        } catch (caught) {
          if (active) setError(caught instanceof Error ? caught.message : 'Unable to load your profile.')
        }
      }
      if (active) setLoading(false)
    }

    void initialize()
    const { data: listener } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession)
      setProfile(null)
      setError(null)
      if (!nextSession) {
        setLoading(false)
        return
      }
      if (window.sessionStorage.getItem(pendingRoleCheckKey)) {
        setLoading(false)
        return
      }
      setLoading(true)
      window.setTimeout(() => {
        void loadProfile(nextSession.user.id)
          .catch((caught) => setError(caught instanceof Error ? caught.message : 'Unable to load your profile.'))
          .finally(() => setLoading(false))
      }, 0)
    })

    return () => {
      active = false
      listener.subscription.unsubscribe()
    }
  }, [loadProfile])

  useEffect(() => {
    if (!session) return
    let active = true
    let timeoutMinutes = 10
    let logoutTimer = 0
    let lastServerUpdate = 0

    const expireSession = () => {
      if (!active) return
      window.sessionStorage.setItem(inactivityLogoutKey, 'Your session expired because there was no activity.')
      void signOut()
    }
    const scheduleLogout = () => {
      window.clearTimeout(logoutTimer)
      logoutTimer = window.setTimeout(expireSession, timeoutMinutes * 60 * 1000)
    }
    const updateServerActivity = async (force = false) => {
      const now = Date.now()
      if (!force && now - lastServerUpdate < 30_000) return
      lastServerUpdate = now
      const { data, error: activityError } = await supabase.auth.recordActivity()
      if (!active) return
      if (activityError || !data) {
        window.sessionStorage.setItem(inactivityLogoutKey, 'Your session expired. Please sign in again.')
        await signOut()
        return
      }
      timeoutMinutes = data.inactivity_timeout_minutes
      scheduleLogout()
    }
    const handleActivity = () => {
      scheduleLogout()
      void updateServerActivity()
    }
    const events: (keyof WindowEventMap)[] = ['mousemove', 'mousedown', 'keydown', 'scroll', 'touchstart']
    for (const event of events) window.addEventListener(event, handleActivity, { passive: true })
    scheduleLogout()
    void updateServerActivity(true)

    return () => {
      active = false
      window.clearTimeout(logoutTimer)
      for (const event of events) window.removeEventListener(event, handleActivity)
    }
  }, [session, signOut])

  const value = useMemo<AuthContextValue>(
    () => ({
      session,
      user: session?.user ?? null,
      profile,
      loading,
      error,
      refreshProfile,
      registerBeforeSignOut,
      signOut,
    }),
    [session, profile, loading, error, refreshProfile, registerBeforeSignOut, signOut],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used within AuthProvider')
  return context
}