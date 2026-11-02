import type { LucideIcon } from 'lucide-react'

export function AdminPageHeader({ icon: Icon, eyebrow, title, description, action }: {
  icon: LucideIcon
  eyebrow: string
  title: string
  description: string
  action?: React.ReactNode
}) {
  return (
    <div className="mb-6 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
      <div className="min-w-0">
        <div className="flex items-center gap-2 text-brand-700"><Icon size={18} /><p className="text-xs font-extrabold uppercase tracking-[0.16em]">{eyebrow}</p></div>
        <h2 className="mt-1 text-xl font-black tracking-tight text-slate-900 sm:text-2xl">{title}</h2>
        <p className="mt-1 max-w-2xl text-sm text-slate-500">{description}</p>
      </div>
      {action && <div className="mobile-action shrink-0">{action}</div>}
    </div>
  )
}