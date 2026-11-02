import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { ClassSummary } from '../types/database'

type RawClass = Omit<ClassSummary, 'subject' | 'instructor'> & {
  subject: { code: string; title: string } | { code: string; title: string }[] | null
  instructor: { full_name: string } | { full_name: string }[] | null
}

function normalizeRelation<T>(relation: T | T[] | null): T | null {
  return Array.isArray(relation) ? relation[0] ?? null : relation
}

export function useClasses() {
  const [classes, setClasses] = useState<ClassSummary[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    const { data, error: queryError } = await supabase
      .from('classes')
      .select('id, section, school_year, semester, status, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)')
      .eq('status', 'active')
      .order('created_at')
    if (queryError) setError(queryError.message)
    else {
      const rows = (data ?? []) as unknown as RawClass[]
      setClasses(rows.map((row) => ({ ...row, subject: normalizeRelation(row.subject), instructor: normalizeRelation(row.instructor) })))
    }
    setLoading(false)
  }, [])

  useEffect(() => {
    let active = true
    void supabase
      .from('classes')
      .select('id, section, school_year, semester, status, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)')
      .eq('status', 'active')
      .order('created_at')
      .then(({ data, error: queryError }) => {
        if (!active) return
        if (queryError) setError(queryError.message)
        else {
          const rows = (data ?? []) as unknown as RawClass[]
          setClasses(rows.map((row) => ({ ...row, subject: normalizeRelation(row.subject), instructor: normalizeRelation(row.instructor) })))
        }
        setLoading(false)
      })
    return () => { active = false }
  }, [])
  return { classes, loading, error, reload: load }
}