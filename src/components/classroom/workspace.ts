import { supabase } from '../../lib/supabase'

export function formatDate(value: string | null, fallback = 'No date set') {
  return value ? new Date(value).toLocaleString() : fallback
}

export function safeFileName(name: string) {
  return name.replace(/[^a-zA-Z0-9._-]/g, '_')
}

export function storedFileName(path: string) {
  const basename = path.split('/').pop() ?? 'Submitted document'
  return basename.replace(/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}-/i, '')
}

export async function openPrivateFile(bucket: 'materials' | 'submissions' | 'discussions', path: string) {
  const { data, error } = await supabase.storage.from(bucket).createSignedUrl(path, 60)
  if (error) throw error
  window.open(data.signedUrl, '_blank', 'noopener,noreferrer')
}

export function messageFrom(error: unknown) {
  return error instanceof Error ? error.message : 'Something went wrong.'
}