import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { Eye, FileUp, Link2, Plus, Trash2, X } from 'lucide-react'
import { EmptyState, ErrorState, LoadingState } from '../ScreenState'
import { supabase } from '../../lib/supabase'
import type { Database } from '../../types/database'
import { DocumentPreviewModal, type PreviewDocument } from './DocumentPreviewModal'
import { messageFrom, safeFileName, storedFileName } from './workspace'
import { useClassNotifications } from '../../hooks/useClassNotifications'
import { destructiveActionConfirmation } from '../../lib/confirmDestructiveAction'
import { useConfirmation } from '../../hooks/useConfirmation'

type Material = Database['public']['Tables']['materials']['Row']

export function MaterialsTab({ classId, canManage }: { classId: string; canManage: boolean }) {
  const { confirm } = useConfirmation()
  const { isUnread, markItemViewed } = useClassNotifications()
  const [items, setItems] = useState<Material[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [formOpen, setFormOpen] = useState(false)
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [url, setUrl] = useState('')
  const [file, setFile] = useState<File | null>(null)
  const [saving, setSaving] = useState(false)
  const [previewDocument, setPreviewDocument] = useState<PreviewDocument | null>(null)

  const load = useCallback(async () => {
    setLoading(true); setError(null)
    const { data, error: queryError } = await supabase.from('materials').select('*').eq('class_id', classId).order('created_at', { ascending: false })
    if (queryError) setError(queryError.message); else setItems(data ?? [])
    setLoading(false)
  }, [classId])

  useEffect(() => {
    let active = true
    void supabase.from('materials').select('*').eq('class_id', classId).order('created_at', { ascending: false }).then(({ data, error: queryError }) => {
      if (!active) return
      if (queryError) setError(queryError.message); else setItems(data ?? [])
      setLoading(false)
    })
    return () => { active = false }
  }, [classId])

  const submit = async (event: FormEvent) => {
    event.preventDefault(); setError(null)
    if (!title.trim() || (!file && !url.trim())) return setError('Add a title and either a file or external link.')
    setSaving(true)
    let filePath: string | null = null
    try {
      if (file) {
        filePath = `${classId}/${crypto.randomUUID()}-${safeFileName(file.name)}`
        const { error: uploadError } = await supabase.storage.from('materials').upload(filePath, file)
        if (uploadError) throw uploadError
      }
      const { error: insertError } = await supabase.from('materials').insert({ class_id: classId, title: title.trim(), description: description.trim() || null, file_path: filePath, external_url: url.trim() || null })
      if (insertError) throw insertError
      setTitle(''); setDescription(''); setUrl(''); setFile(null); setFormOpen(false)
      await load()
    } catch (caught) {
      if (filePath) await supabase.storage.from('materials').remove([filePath])
      setError(messageFrom(caught))
    } finally { setSaving(false) }
  }

  const remove = async (item: Material) => {
    if (!await confirm(destructiveActionConfirmation({ action: 'delete', item: `the material “${item.title}”`, detail: 'The material and its uploaded file will be permanently deleted. This action cannot be undone.' }))) return
    setError(null)
    const { error: deleteError } = await supabase.from('materials').delete().eq('id', item.id)
    if (deleteError) return setError(deleteError.message)
    if (item.file_path) await supabase.storage.from('materials').remove([item.file_path])
    setItems((current) => current.filter((value) => value.id !== item.id))
  }

  return <section>
    <TabHeading title="Learning materials" description="Files and links shared with this class." action={canManage && <button className={formOpen ? 'button-secondary' : 'button-primary'} onClick={() => setFormOpen((value) => !value)}>{formOpen ? <><X size={17} /> Cancel</> : <><Plus size={17} /> Add material</>}</button>} />
    {formOpen && <form className="workspace-form mb-5" onSubmit={submit}><input className="form-input" placeholder="Material title" value={title} onChange={(event) => setTitle(event.target.value)} /><textarea className="form-textarea" placeholder="Description (optional)" value={description} onChange={(event) => setDescription(event.target.value)} /><input className="form-input" type="url" placeholder="External link (optional)" value={url} onChange={(event) => setUrl(event.target.value)} /><label className="file-picker"><FileUp size={18} /><span>{file?.name ?? 'Choose any file type'}</span><input type="file" onChange={(event) => setFile(event.target.files?.[0] ?? null)} /></label><p className="text-xs text-slate-500">Almost all file types are accepted up to 10 MB, including images, audio, video, Word, PowerPoint, and Excel. Browser-supported files can be previewed; Office and other formats can be downloaded.</p><div className="flex justify-end gap-2"><button type="button" className="button-secondary" onClick={() => setFormOpen(false)}>Cancel</button><button className="button-primary" disabled={saving}>{saving ? 'Saving…' : 'Share material'}</button></div></form>}
    {loading && <LoadingState label="Loading materials…" />}{error && <ErrorState message={error} onRetry={() => void load()} />}
    {!loading && !error && items.length === 0 && <EmptyState title="No materials yet" description={canManage ? 'Share a file or external resource with the class.' : 'Your instructor has not shared materials yet.'} />}
    {!loading && items.length > 0 && <div className="space-y-3">{items.map((item) => <article className={`workspace-item ${isUnread(classId, 'materials', item.id) ? 'notification-content-unread' : ''}`} key={item.id} onClick={() => markItemViewed(classId, 'materials', item.id)}><div className="min-w-0 flex-1"><h3>{item.title}</h3>{item.description && <p>{item.description}</p>}<small>{new Date(item.created_at).toLocaleString()}</small></div><div className="flex flex-wrap gap-2 sm:justify-end">{item.file_path && <button className="button-secondary" title="Preview material" aria-label={`Preview ${item.title}`} onClick={() => setPreviewDocument({ bucket: 'materials', path: item.file_path!, name: storedFileName(item.file_path!) })}><Eye size={16} /> Preview</button>}{item.external_url && <a className="icon-action" href={item.external_url} target="_blank" rel="noreferrer" title="Open external link"><Link2 size={18} /></a>}{canManage && <button className="icon-action text-red-600" title="Delete" onClick={() => void remove(item)}><Trash2 size={18} /></button>}</div></article>)}</div>}
    <DocumentPreviewModal document={previewDocument} onClose={() => setPreviewDocument(null)} />
  </section>
}

export function TabHeading({ title, description, action }: { title: string; description: string; action?: React.ReactNode }) {
  return <div className="mb-5 flex flex-col justify-between gap-3 sm:flex-row sm:items-end"><div className="min-w-0"><h2 className="text-xl font-black text-slate-900">{title}</h2><p className="mt-1 text-sm text-slate-500">{description}</p></div>{action && <div className="mobile-action shrink-0">{action}</div>}</div>
}