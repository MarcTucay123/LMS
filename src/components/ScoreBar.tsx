interface ScoreBarProps {
  earned: number | null | undefined
  possible: number | null | undefined
  label?: string
  compact?: boolean
}

export function ScoreBar({ earned, possible, label = 'Score', compact = false }: ScoreBarProps) {
  const earnedValue = Number.isFinite(Number(earned)) ? Number(earned) : 0
  const possibleValue = Number.isFinite(Number(possible)) ? Math.max(0, Number(possible)) : 0
  const percentage = possibleValue > 0 ? Math.min(100, Math.max(0, earnedValue / possibleValue * 100)) : 0

  return (
    <div className={`min-w-36 ${compact ? 'w-full max-w-52' : 'w-full'}`}>
      <div className="mb-1.5 flex items-baseline justify-between gap-3">
        <span className={`${compact ? 'text-[11px]' : 'text-xs'} font-extrabold uppercase tracking-wide text-slate-500`}>{label}</span>
        <span className={`${compact ? 'text-xs' : 'text-sm'} whitespace-nowrap font-black text-slate-800`}>
          {formatScore(earnedValue)} / {formatScore(possibleValue)} <span className="font-bold text-slate-500">({percentage.toFixed(1)}%)</span>
        </span>
      </div>
      <div
        className={`${compact ? 'h-2' : 'h-3'} flex overflow-hidden rounded-full bg-red-400 shadow-inner ring-1 ring-red-500/20`}
        role="meter"
        aria-label={`${label}: ${formatScore(earnedValue)} out of ${formatScore(possibleValue)}`}
        aria-valuemin={0}
        aria-valuemax={possibleValue}
        aria-valuenow={Math.min(Math.max(earnedValue, 0), possibleValue)}
      >
        <div className="h-full bg-emerald-500 transition-[width] duration-500" style={{ width: `${percentage}%` }} />
      </div>
    </div>
  )
}

function formatScore(value: number) {
  return Number.isInteger(value) ? value.toString() : value.toFixed(2).replace(/0+$/, '').replace(/[.]$/, '')
}