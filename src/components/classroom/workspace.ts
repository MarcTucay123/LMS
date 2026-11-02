import { supabase } from '../../lib/supabase'

export function formatDate(value: string | null, fallback = 'No date set') {
  return value ? new Date(value).toLocaleString() : fallback
}

export function safeFileName(name: string) {
  return name.replace(/[^a-zA-Z0-9._-]/g, '_')
}

export async function openPrivateFile(bucket: 'materials' | 'submissions', path: string) {
  const { data, error } = await supabase.storage.from(bucket).createSignedUrl(path, 60)
  if (error) throw error
  window.open(data.signedUrl, '_blank', 'noopener,noreferrer')
}

export function messageFrom(error: unknown) {
  return error instanceof Error ? error.message : 'Something went wrong.'
}