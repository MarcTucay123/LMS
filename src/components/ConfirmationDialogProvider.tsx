import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react'
import { AlertTriangle, HelpCircle, LogOut, Trash2, X } from 'lucide-react'
import { ConfirmationContext, type ConfirmationOptions } from '../contexts/ConfirmationDialogContext'

interface ConfirmationRequest extends ConfirmationOptions {
  resolve: (confirmed: boolean) => void
}

export function ConfirmationDialogProvider({ children }: { children: ReactNode }) {
  const [request, setRequest] = useState<ConfirmationRequest | null>(null)
  const confirmButtonRef = useRef<HTMLButtonElement>(null)

  const confirm = useCallback((options: ConfirmationOptions) => new Promise<boolean>((resolve) => {
    setRequest((current) => {
      current?.resolve(false)
      return { ...options, resolve }
    })
  }), [])

  const close = useCallback((confirmed: boolean) => {
    setRequest((current) => {
      current?.resolve(confirmed)
      return null
    })
  }, [])

  useEffect(() => {
    if (!request) return
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    const focusTimer = window.setTimeout(() => confirmButtonRef.current?.focus(), 0)
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') close(false) }
    window.addEventListener('keydown', closeOnEscape)
    return () => {
      document.body.style.overflow = previousOverflow
      window.clearTimeout(focusTimer)
      window.removeEventListener('keydown', closeOnEscape)
    }
  }, [close, request])

  const tone = request?.tone ?? 'danger'
  const icon = request?.icon ?? (tone === 'danger' ? 'delete' : 'question')
  const Icon = icon === 'logout' ? LogOut : icon === 'delete' ? Trash2 : icon === 'warning' ? AlertTriangle : HelpCircle
  const iconStyle = tone === 'danger' ? 'bg-red-100 text-red-700' : tone === 'warning' ? 'bg-amber-100 text-amber-700' : 'bg-blue-100 text-brand-700'
  const confirmStyle = tone === 'danger' ? 'bg-red-600 hover:bg-red-700' : tone === 'warning' ? 'bg-amber-600 hover:bg-amber-700' : 'bg-brand-700 hover:bg-brand-800'

  return <ConfirmationContext.Provider value={{ confirm }}>
    {children}
    {request && <div className="modal-backdrop print-hidden" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) close(false) }}>
      <section className="modal-card max-w-md p-0 sm:p-0" role="alertdialog" aria-modal="true" aria-labelledby="confirmation-dialog-title" aria-describedby="confirmation-dialog-message">
        <header className="flex items-start justify-between gap-4 border-b border-slate-200 px-5 py-5 sm:px-6">
          <div className={`grid size-12 shrink-0 place-items-center rounded-full ${iconStyle}`}><Icon size={24} aria-hidden="true" /></div>
          <div className="min-w-0 flex-1 pt-1"><h2 id="confirmation-dialog-title" className="text-lg font-black text-slate-900">{request.title}</h2></div>
          <button type="button" className="icon-action -mr-1 -mt-1" onClick={() => close(false)} aria-label="Close confirmation"><X size={18} /></button>
        </header>
        <div className="px-5 py-5 sm:px-6"><p id="confirmation-dialog-message" className="whitespace-pre-line text-sm leading-6 text-slate-600">{request.message}</p></div>
        <footer className="flex flex-col-reverse gap-2 border-t border-slate-200 bg-slate-50 px-5 py-4 sm:flex-row sm:justify-end sm:px-6">
          <button type="button" className="button-secondary" onClick={() => close(false)}>{request.cancelLabel ?? 'Cancel'}</button>
          <button ref={confirmButtonRef} type="button" className={`inline-flex min-h-11 items-center justify-center gap-2 rounded-lg px-4 py-2.5 font-bold text-white shadow-sm transition ${confirmStyle}`} onClick={() => close(true)}><Icon size={17} aria-hidden="true" />{request.confirmLabel ?? 'Confirm'}</button>
        </footer>
      </section>
    </div>}
  </ConfirmationContext.Provider>
}