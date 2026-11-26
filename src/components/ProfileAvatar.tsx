import { useEffect, useState } from 'react'
import { createPortal } from 'react-dom'
import { X } from 'lucide-react'
import { supabase } from '../lib/supabase'

const signedPhotoCache = new Map<string, { url: string; expiresAt: number }>()
const pendingPhotoUrls = new Map<string, Promise<string>>()

async function profilePhotoUrl(path: string) {
  const cached = signedPhotoCache.get(path)
  if (cached && cached.expiresAt > Date.now()) return cached.url
  const pending = pendingPhotoUrls.get(path)
  if (pending) return pending
  const request = supabase.storage.from('profiles').createSignedUrl(path, 300, 'preview').then(({ data, error }) => {
    if (error) throw error
    signedPhotoCache.set(path, { url: data.signedUrl, expiresAt: Date.now() + 4 * 60 * 1000 })
    return data.signedUrl
  }).finally(() => pendingPhotoUrls.delete(path))
  pendingPhotoUrls.set(path, request)
  return request
}

interface ProfileAvatarProps {
  name: string
  avatarPath?: string | null
  className?: string
  imageClassName?: string
  clickable?: boolean
}

function initials(name: string) {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join('')
    .toUpperCase() || '?'
}

export function ProfileAvatar({ name, avatarPath, className = 'size-10', imageClassName = '', clickable = true }: ProfileAvatarProps) {
  const [resolvedImage, setResolvedImage] = useState<{ path: string; url: string } | null>(null)
  const [viewerOpen, setViewerOpen] = useState(false)

  useEffect(() => {
    let active = true
    if (!avatarPath) return () => { active = false }
    void profilePhotoUrl(avatarPath).then((url) => { if (active) setResolvedImage({ path: avatarPath, url }) }).catch(() => undefined)
    return () => { active = false }
  }, [avatarPath])

  const imageUrl = avatarPath && resolvedImage?.path === avatarPath ? resolvedImage.url : ''

  const content = imageUrl
    ? <img src={imageUrl} alt="" className={`size-full object-cover ${imageClassName}`} onError={() => setResolvedImage(null)} />
    : <span aria-hidden="true">{initials(name)}</span>
  const commonClass = `grid shrink-0 place-items-center overflow-hidden rounded-full bg-blue-50 font-bold text-brand-700 ring-2 ring-blue-100 ${className}`

  return <>
    {clickable && imageUrl ? (
      <button type="button" className={`${commonClass} cursor-zoom-in transition hover:ring-brand-300 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-brand-300`} onClick={() => setViewerOpen(true)} aria-label={`View ${name}'s profile picture`} title={`View ${name}'s profile picture`}>
        {content}
      </button>
    ) : <span className={commonClass} aria-label={`${name}'s profile picture`}>{content}</span>}
    {viewerOpen && imageUrl && createPortal(<ProfilePictureViewer name={name} imageUrl={imageUrl} onClose={() => setViewerOpen(false)} />, document.body)}
  </>
}

function ProfilePictureViewer({ name, imageUrl, onClose }: { name: string; imageUrl: string; onClose: () => void }) {
  useEffect(() => {
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') onClose() }
    window.addEventListener('keydown', closeOnEscape)
    return () => {
      document.body.style.overflow = previousOverflow
      window.removeEventListener('keydown', closeOnEscape)
    }
  }, [onClose])

  return <div className="modal-backdrop z-[80]" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
    <section className="relative mx-3 flex max-h-[90vh] w-full max-w-3xl flex-col overflow-hidden rounded-2xl bg-slate-950 shadow-2xl" role="dialog" aria-modal="true" aria-labelledby="profile-picture-title">
      <header className="flex items-center justify-between gap-3 border-b border-white/10 px-4 py-3 text-white">
        <h2 id="profile-picture-title" className="truncate font-extrabold">{name}'s profile picture</h2>
        <button type="button" className="grid size-10 shrink-0 place-items-center rounded-xl text-white transition hover:bg-white/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white" onClick={onClose} aria-label="Close profile picture"><X size={20} /></button>
      </header>
      <div className="flex min-h-0 flex-1 items-center justify-center overflow-auto p-3 sm:p-6">
        <img src={imageUrl} alt={`${name}'s profile picture`} className="max-h-[75vh] max-w-full rounded-xl object-contain" />
      </div>
    </section>
  </div>
}