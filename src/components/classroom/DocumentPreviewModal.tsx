import { useEffect, useMemo, useState } from 'react'
import { Download, Eye, FileText, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { messageFrom } from './workspace'

type Bucket = 'materials' | 'submissions' | 'discussions'

export interface PreviewDocument {
  bucket: Bucket
  path: string
  name: string
  allowDownload?: boolean
}

function extension(name: string) {
  return name.split('.').pop()?.toLowerCase() ?? ''
}

type PreviewKind = 'document' | 'image' | 'audio' | 'video'

function previewKind(name: string): PreviewKind {
  const ext = extension(name)
  if (['pdf', 'txt', 'docx', 'pptx', 'xlsx'].includes(ext)) return 'document'
  if (['png', 'jpg', 'jpeg', 'jfif', 'jif', 'jfi', 'gif', 'webp', 'bmp'].includes(ext)) return 'image'
  if (['mp3', 'wav', 'ogg', 'oga', 'm4a', 'aac', 'flac', 'weba'].includes(ext)) return 'audio'
  if (['mp4', 'webm', 'ogv', 'mov', 'm4v'].includes(ext)) return 'video'
  return 'document'
}

export function DocumentPreviewModal({ document, onClose }: { document: PreviewDocument | null; onClose: () => void }) {
  if (!document) return null
  return <DocumentPreviewDialog key={`${document.bucket}:${document.path}`} document={document} onClose={onClose} />
}

function DocumentPreviewDialog({ document, onClose }: { document: PreviewDocument; onClose: () => void }) {
  const [previewUrl, setPreviewUrl] = useState('')
  const [downloadUrl, setDownloadUrl] = useState('')
  const [error, setError] = useState<string | null>(null)
  const kind = useMemo(() => previewKind(document.name), [document.name])
  useEffect(() => {
    let active = true
    void Promise.all([
      supabase.storage.from(document.bucket).createSignedUrl(document.path, 300, 'preview'),
      document.allowDownload !== false ? supabase.storage.from(document.bucket).createSignedUrl(document.path, 300, 'download') : Promise.resolve(null),
    ]).then(([previewResult, downloadResult]) => {
      if (!active) return
      if (previewResult?.error) throw previewResult.error
      if (downloadResult?.error) throw downloadResult.error
      setPreviewUrl(previewResult?.data.signedUrl ?? '')
      setDownloadUrl(downloadResult?.data.signedUrl ?? '')
    }).catch((caught) => { if (active) setError(messageFrom(caught)) })
    return () => { active = false }
  }, [document])

  useEffect(() => {
    const previousOverflow = documentGlobal.body.style.overflow
    documentGlobal.body.style.overflow = 'hidden'
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') onClose() }
    window.addEventListener('keydown', closeOnEscape)
    return () => { documentGlobal.body.style.overflow = previousOverflow; window.removeEventListener('keydown', closeOnEscape) }
  }, [document, onClose])

  return (
    <div className="modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
      <section className="modal-card flex max-w-5xl flex-col p-0 sm:p-0" role="dialog" aria-modal="true" aria-labelledby="document-preview-title">
        <header className="flex items-center justify-between gap-3 border-b border-slate-200 px-4 py-3 sm:px-5">
          <div className="min-w-0">
            <p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">File preview</p>
            <h2 id="document-preview-title" className="truncate text-base font-black text-slate-900 sm:text-lg">{document.name}</h2>
          </div>
          <button type="button" className="icon-action shrink-0" onClick={onClose} aria-label="Close preview"><X size={19} /></button>
        </header>

        <div className="min-h-[360px] flex-1 bg-slate-100 p-3 sm:min-h-[520px] sm:p-4">
          {error && <div className="grid h-full min-h-[330px] place-items-center rounded-xl bg-white p-6 text-center text-sm font-semibold text-red-600">{error}</div>}
          {!error && kind === 'document' && previewUrl && <iframe className="h-[65vh] min-h-[330px] w-full rounded-xl border border-slate-200 bg-white" src={previewUrl} title={`Preview of ${document.name}`} />}
          {!error && kind === 'image' && previewUrl && <div className="grid h-[65vh] min-h-[330px] place-items-center overflow-auto rounded-xl border border-slate-200 bg-white p-3"><img className="max-h-full max-w-full object-contain" src={previewUrl} alt={`Preview of ${document.name}`} /></div>}
          {!error && kind === 'audio' && previewUrl && <div className="grid h-full min-h-[330px] place-items-center rounded-xl border border-slate-200 bg-white p-6"><div className="w-full max-w-xl text-center"><FileText className="mx-auto text-brand-700" size={56} /><p className="mt-4 break-words text-sm font-bold text-slate-700">{document.name}</p><audio className="mt-5 w-full" src={previewUrl} controls preload="metadata">Your browser does not support audio playback.</audio></div></div>}
          {!error && kind === 'video' && previewUrl && <div className="grid h-[65vh] min-h-[330px] place-items-center overflow-hidden rounded-xl border border-slate-200 bg-black"><video className="max-h-full max-w-full" src={previewUrl} controls preload="metadata">Your browser does not support video playback.</video></div>}
          {!error && !previewUrl && <div className="grid h-full min-h-[330px] place-items-center rounded-xl bg-white text-sm font-semibold text-slate-500">Preparing preview…</div>}
        </div>

        <footer className="flex flex-col-reverse gap-2 border-t border-slate-200 px-4 py-3 sm:flex-row sm:items-center sm:justify-between sm:px-5">
          <p className="flex items-center gap-2 text-xs font-semibold text-slate-500"><Eye size={15} /> Secure class-authorized file access</p>
          <div className="flex gap-2">
            <button type="button" className="button-secondary flex-1 sm:flex-none" onClick={onClose}>Close</button>
            {document.allowDownload !== false && <a className={`button-primary flex-1 sm:flex-none ${downloadUrl ? '' : 'pointer-events-none opacity-50'}`} href={downloadUrl || undefined}><Download size={17} /> Download</a>}
          </div>
        </footer>
      </section>
    </div>
  )
}

const documentGlobal = window.document