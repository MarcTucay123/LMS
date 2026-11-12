/* eslint-disable react-refresh/only-export-components -- provider and paired hook intentionally share this module */
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import { supabase } from '../lib/supabase'

interface OneCampusSetupContextValue {
  configured: boolean
  loading: boolean
  error: string | null
  refresh: () => Promise<boolean>
}

const OneCampusSetupContext = createContext<OneCampusSetupContextValue | undefined>(undefined)

export function OneCampusSetupProvider({ children }: { children: ReactNode }) {
  const [configured, setConfigured] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    setLoading(true)
    const { data, error: statusError } = await supabase.oneCampusStatus()
    const ready = Boolean(data?.configured)
    setConfigured(ready)
    setError(statusError?.message ?? null)
    setLoading(false)
    return ready
  }, [])

  useEffect(() => {
    let active = true
    void supabase.oneCampusStatus().then(({ data, error: statusError }) => {
      if (!active) return
      setConfigured(Boolean(data?.configured))
      setError(statusError?.message ?? null)
      setLoading(false)
    })
    return () => { active = false }
  }, [])

  const value = useMemo(() => ({ configured, loading, error, refresh }), [configured, loading, error, refresh])
  return <OneCampusSetupContext.Provider value={value}>{children}</OneCampusSetupContext.Provider>
}

export function useOneCampusSetup() {
  const context = useContext(OneCampusSetupContext)
  if (!context) throw new Error('useOneCampusSetup must be used within OneCampusSetupProvider')
  return context
}