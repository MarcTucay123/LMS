/* eslint-disable react-refresh/only-export-components -- provider and paired hook intentionally share this module */
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import { useAuth } from './useAuth'
import { supabase } from '../lib/supabase'
import type { ClassNotificationCounts, ClassNotificationSection, Json } from '../types/database'

const sections: ClassNotificationSection[] = ['materials', 'assignments', 'quizzes', 'exams', 'discussions', 'announcements', 'progress']
type SeenSection = string | { through?: string; items?: Record<string, string> }
type SeenMap = Record<string, Partial<Record<ClassNotificationSection, SeenSection>>>

interface ClassNotificationContextValue {
  byClass: Record<string, ClassNotificationCounts>
  total: number
  totalsBySection: Record<ClassNotificationSection, number>
  loading: boolean
  markViewed: (classId: string, section: ClassNotificationSection) => void
  markItemViewed: (classId: string, section: ClassNotificationSection, itemId: string) => void
  isUnread: (classId: string, section: ClassNotificationSection, itemId: string) => boolean
  reload: () => Promise<void>
}

const emptySectionTotals = (): Record<ClassNotificationSection, number> => ({ materials: 0, assignments: 0, quizzes: 0, exams: 0, discussions: 0, announcements: 0, progress: 0 })
const ClassNotificationContext = createContext<ClassNotificationContextValue | undefined>(undefined)

function storageKey(userId: string) {
  return `adfc-lms-notification-seen:${userId}`
}

function readSeen(userId: string): SeenMap {
  try {
    const parsed = JSON.parse(window.localStorage.getItem(storageKey(userId)) ?? '{}')
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed as SeenMap : {}
  } catch {
    return {}
  }
}

export function ClassNotificationProvider({ children }: { children: ReactNode }) {
  const { profile } = useAuth()
  const [counts, setCounts] = useState<ClassNotificationCounts[]>([])
  const [loading, setLoading] = useState(true)

  const reload = useCallback(async () => {
    if (!profile || profile.role === 'admin') {
      setCounts([])
      setLoading(false)
      return
    }
    const { data, error } = await supabase.rpc('get_class_notification_counts', { seen_at: readSeen(profile.id) as Json })
    if (!error && data) setCounts(data)
    setLoading(false)
  }, [profile])

  useEffect(() => {
    const initial = window.setTimeout(() => void reload(), 0)
    const timer = window.setInterval(() => void reload(), 15_000)
    const refresh = () => void reload()
    const handleStorage = (event: StorageEvent) => { if (profile && event.key === storageKey(profile.id)) refresh() }
    window.addEventListener('focus', refresh)
    window.addEventListener('storage', handleStorage)
    return () => {
      window.clearTimeout(initial)
      window.clearInterval(timer)
      window.removeEventListener('focus', refresh)
      window.removeEventListener('storage', handleStorage)
    }
  }, [profile, reload])

  const markViewed = useCallback((classId: string, section: ClassNotificationSection) => {
    if (!profile || profile.role === 'admin') return
    const seen = readSeen(profile.id)
    seen[classId] = { ...(seen[classId] ?? {}), [section]: { through: new Date().toISOString(), items: {} } }
    window.localStorage.setItem(storageKey(profile.id), JSON.stringify(seen))
    setCounts((current) => current.map((item) => item.class_id !== classId ? item : { ...item, [section]: 0, total: Math.max(0, item.total - item[section]), unread_items: { ...item.unread_items, [section]: [] } }))
  }, [profile])

  const markItemViewed = useCallback((classId: string, section: ClassNotificationSection, itemId: string) => {
    if (!profile || profile.role === 'admin') return
    const seen = readSeen(profile.id)
    const existing = seen[classId]?.[section]
    const sectionSeen = typeof existing === 'string' ? { through: existing, items: {} } : existing ?? { items: {} }
    seen[classId] = { ...(seen[classId] ?? {}), [section]: { ...sectionSeen, items: { ...(sectionSeen.items ?? {}), [itemId]: new Date().toISOString() } } }
    window.localStorage.setItem(storageKey(profile.id), JSON.stringify(seen))
    setCounts((current) => current.map((item) => {
      if (item.class_id !== classId || !item.unread_items[section].includes(itemId)) return item
      return { ...item, [section]: Math.max(0, item[section] - 1), total: Math.max(0, item.total - 1), unread_items: { ...item.unread_items, [section]: item.unread_items[section].filter((id) => id !== itemId) } }
    }))
  }, [profile])

  const isUnread = useCallback((classId: string, section: ClassNotificationSection, itemId: string) => {
    return counts.find((item) => item.class_id === classId)?.unread_items[section].includes(itemId) ?? false
  }, [counts])

  const value = useMemo<ClassNotificationContextValue>(() => {
    const byClass = Object.fromEntries(counts.map((item) => [item.class_id, item]))
    const totalsBySection = emptySectionTotals()
    for (const item of counts) for (const section of sections) totalsBySection[section] += item[section]
    return { byClass, total: counts.reduce((sum, item) => sum + item.total, 0), totalsBySection, loading, markViewed, markItemViewed, isUnread, reload }
  }, [counts, isUnread, loading, markItemViewed, markViewed, reload])

  return <ClassNotificationContext.Provider value={value}>{children}</ClassNotificationContext.Provider>
}

export function useClassNotifications() {
  const context = useContext(ClassNotificationContext)
  if (!context) throw new Error('useClassNotifications must be used within ClassNotificationProvider')
  return context
}