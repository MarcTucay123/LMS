import { useEffect, useMemo, useState } from 'react'
import { Download, Eye, FileText, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { messageFrom } from './workspace'

type Bucket = 'materials' | 'submissions'

export interface PreviewDocument {
  bucket: Bucket
  path: string
  name: string
}

function extension(name: string) {
  return name.split('.').pop()?.toLowerCase() ?? ''
}

export function DocumentPreviewModal({ document, onClose }: { document: PreviewDocument | null; onClose: () => void }) {
  if (!document) return null
  return <DocumentPreviewDialog key={`${document.bucket}:${document.path}`} document={document} onClose={onClose} />
}

function DocumentPreviewDialog({ document, onClose }: { document: PreviewDocument; onClose: () => void }) {
  const [previewUrl, setPreviewUrl] = useState('')
  const [downloadUrl, setDownloadUrl] = useState('')
  const [error, setError] = useState<string | null>(null)
  const previewable = useMemo(() => ['pdf', 'txt'].includes(extension(document.name)), [document.name])

  useEffect(() => {
    let active = true
    void Promise.all([
      previewable ? supabase.storage.from(document.bucket).createSignedUrl(document.path, 300, 'preview') : Promise.resolve(null),
      supabase.storage.from(document.bucket).createSignedUrl(document.path, 300, 'download'),
    ]).then(([previewResult, downloadResult]) => {
      if (!active) return
      if (previewResult?.error) throw previewResult.error
      if (downloadResult.error) throw downloadResult.error
      setPreviewUrl(previewResult?.data.signedUrl ?? '')
      setDownloadUrl(downloadResult.data.signedUrl)
    }).catch((caught) => { if (active) setError(messageFrom(caught)) })
    return () => { active = false }
  }, [document, previewable])

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
            <p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">Document preview</p>
            <h2 id="document-preview-title" className="truncate text-base font-black text-slate-900 sm:text-lg">{document.name}</h2>
          </div>
          <button type="button" className="icon-action shrink-0" onClick={onClose} aria-label="Close preview"><X size={19} /></button>
        </header>

        <div className="min-h-[360px] flex-1 bg-slate-100 p-3 sm:min-h-[520px] sm:p-4">
          {error && <div className="grid h-full min-h-[330px] place-items-center rounded-xl bg-white p-6 text-center text-sm font-semibold text-red-600">{error}</div>}
          {!error && previewable && previewUrl && <iframe className="h-[65vh] min-h-[330px] w-full rounded-xl border border-slate-200 bg-white" src={previewUrl} title={`Preview of ${document.name}`} />}
          {!error && previewable && !previewUrl && <div className="grid h-full min-h-[330px] place-items-center rounded-xl bg-white text-sm font-semibold text-slate-500">Preparing preview…</div>}
          {!error && !previewable && <div className="grid h-full min-h-[330px] place-items-center rounded-xl border border-slate-200 bg-white p-6 text-center"><div><div className="mx-auto grid size-16 place-items-center rounded-2xl bg-blue-50 text-brand-700"><FileText size={30} /></div><h3 className="mt-4 text-lg font-black text-slate-900">Preview unavailable for this file type</h3><p className="mt-2 max-w-md text-sm leading-6 text-slate-500">Word, ODT, RTF, and ZIP files must be downloaded and opened with a compatible application.</p></div></div>}
        </div>

        <footer className="flex flex-col-reverse gap-2 border-t border-slate-200 px-4 py-3 sm:flex-row sm:items-center sm:justify-between sm:px-5">
          <p className="flex items-center gap-2 text-xs font-semibold text-slate-500"><Eye size={15} /> Secure class-authorized file access</p>
          <div className="flex gap-2">
            <button type="button" className="button-secondary flex-1 sm:flex-none" onClick={onClose}>Close</button>
            <a className={`button-primary flex-1 sm:flex-none ${downloadUrl ? '' : 'pointer-events-none opacity-50'}`} href={downloadUrl || undefined}><Download size={17} /> Download</a>
          </div>
        </footer>
      </section>
    </div>
  )
}

const documentGlobal = window.document