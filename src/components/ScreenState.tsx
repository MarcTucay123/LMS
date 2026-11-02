import { AlertCircle, Inbox, LoaderCircle } from 'lucide-react'

export function LoadingState({ label = 'Loading…' }: { label?: string }) {
  return (
    <div className="state-card" role="status">
      <LoaderCircle className="animate-spin text-brand-600" aria-hidden="true" />
      <p>{label}</p>
    </div>
  )
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="state-card border-red-200 bg-red-50 text-red-800" role="alert">
      <AlertCircle aria-hidden="true" />
      <div>
        <p className="font-semibold">Something went wrong</p>
        <p className="mt-1 text-sm">{message}</p>
        {onRetry && <button className="button-secondary mt-4" onClick={onRetry}>Try again</button>}
      </div>
    </div>
  )
}

export function EmptyState({ title, description }: { title: string; description: string }) {
  return (
    <div className="state-card">
      <Inbox className="text-slate-400" aria-hidden="true" />
      <div>
        <p className="font-semibold text-slate-800">{title}</p>
        <p className="mt-1 text-sm text-slate-500">{description}</p>
      </div>
    </div>
  )
}