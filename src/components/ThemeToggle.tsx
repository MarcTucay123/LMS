import { Moon, Sun } from 'lucide-react'
import { useTheme } from '../hooks/useTheme'

export function ThemeToggle({ className = '' }: { className?: string }) {
  const { theme, toggleTheme } = useTheme()
  const dark = theme === 'dark'
  const label = dark ? 'Switch to light mode' : 'Switch to dark mode'

  return <button type="button" className={`theme-toggle ${className}`} onClick={toggleTheme} aria-label={label} title={label} aria-pressed={dark}>
    <span className="theme-toggle-icon" aria-hidden="true">{dark ? <Sun size={18} /> : <Moon size={18} />}</span>
    <span className="theme-toggle-label">{dark ? 'Light' : 'Dark'}</span>
  </button>
}