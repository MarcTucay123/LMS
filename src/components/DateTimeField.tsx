import { useId, useState } from 'react'
import { CalendarDays, X } from 'lucide-react'

interface DateTimeFieldProps {
  label: string
  value: string
  min?: string
  minimumError?: string
  allowCurrentBeforeMin?: boolean
  onChange: (value: string) => void
}

export function DateTimeField({ label, value, min, minimumError = 'The selected date and time is too early.', allowCurrentBeforeMin = false, onChange }: DateTimeFieldProps) {
  const titleId = useId()
  const [pickerOpen, setPickerOpen] = useState(false)
  const [draftDate, setDraftDate] = useState('')
  const [draftTime, setDraftTime] = useState('')

  const openPicker = () => {
    const [date = '', time = ''] = value.split('T')
    setDraftDate(date)
    setDraftTime(time.slice(0, 5))
    setPickerOpen(true)
  }

  const closePicker = () => setPickerOpen(false)
  const draftValue = draftDate && draftTime ? `${draftDate}T${draftTime}` : ''
  const unchangedExistingValue = allowCurrentBeforeMin && draftValue === value
  const invalidMinimum = Boolean(min && draftValue && !unchangedExistingValue && new Date(draftValue).getTime() < new Date(min).getTime())
  const minimumDate = min?.slice(0, 10)
  const minimumTime = minimumDate && draftDate === minimumDate ? min?.slice(11, 16) : undefined

  const save = () => {
    if (!draftValue || invalidMinimum) return
    onChange(draftValue)
    closePicker()
  }

  const clear = () => {
    onChange('')
    closePicker()
  }

  return <div className="block text-sm font-semibold text-slate-700">
    <span>{label}</span>
    <button type="button" className="form-input mt-1 flex items-center justify-between gap-3 text-left" onClick={openPicker}>
      <span className={value ? 'text-slate-900' : 'text-slate-400'}>{value ? formatLocalInputDate(value) : 'Select date and time'}</span>
      <CalendarDays className="shrink-0 text-brand-700" size={18} aria-hidden="true" />
    </button>
    {pickerOpen && <div className="modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) closePicker() }}>
      <section className="modal-card max-w-md" role="dialog" aria-modal="true" aria-labelledby={titleId}>
        <div className="flex items-start justify-between gap-3">
          <div><h3 id={titleId} className="text-xl font-black text-slate-900">{label}</h3><p className="mt-1 text-sm font-normal text-slate-500">Choose the date and time, then press Save to close this calendar.</p></div>
          <button type="button" className="icon-action" title="Close calendar" aria-label="Close calendar" onClick={closePicker}><X size={18} /></button>
        </div>
        <div className="mt-5 grid gap-4 sm:grid-cols-2">
          <label className="text-sm font-semibold text-slate-700">
            <span className="flex items-center justify-between gap-3"><span>Date</span><button type="button" className="text-xs font-extrabold text-brand-700 hover:text-brand-900 hover:underline" onClick={() => setDraftDate(localDateValue(new Date()))}>Today</button></span>
            <input className="form-input" type="date" min={minimumDate} value={draftDate} onChange={(event) => setDraftDate(event.target.value)} />
          </label>
          <label className="text-sm font-semibold text-slate-700">Time<input className="form-input" type="time" min={minimumTime} value={draftTime} onChange={(event) => setDraftTime(event.target.value)} /></label>
        </div>
        {invalidMinimum && <p className="mt-3 rounded-lg bg-red-50 px-3 py-2 text-sm font-semibold text-red-700">{minimumError}</p>}
        <div className="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-between">
          <button type="button" className="button-secondary" onClick={clear}>Clear</button>
          <div className="flex flex-col-reverse gap-2 sm:flex-row"><button type="button" className="button-secondary" onClick={closePicker}>Cancel</button><button type="button" className="button-primary" disabled={!draftValue || invalidMinimum} onClick={save}>Save date &amp; time</button></div>
        </div>
      </section>
    </div>}
  </div>
}

function localDateValue(date: Date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function formatLocalInputDate(value: string) {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString()
}