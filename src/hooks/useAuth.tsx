/* eslint-disable react-refresh/only-export-components -- provider and paired hook intentionally share this module */
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import type { Session, User } from '@supabase/supabase-js'
import { supabase } from '../lib/supabase'
import type { Profile } from '../types/database'

interface AuthContextValue {
  session: Session | null
  user: User | null
  profile: Profile | null
  loading: boolean
  error: string | null
  signOut: () => Promise<void>
  refreshProfile: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

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

  const value = useMemo<AuthContextValue>(
    () => ({
      session,
      user: session?.user ?? null,
      profile,
      loading,
      error,
      refreshProfile,
      signOut: async () => {
        await supabase.auth.signOut()
      },
    }),
    [session, profile, loading, error, refreshProfile],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used within AuthProvider')
  return context
}