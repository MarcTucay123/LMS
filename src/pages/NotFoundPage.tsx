import { Link } from 'react-router-dom'
import { ThemeToggle } from '../components/ThemeToggle'

export function NotFoundPage() {
  return <main className="relative grid min-h-screen place-items-center bg-slate-50 p-6 text-center"><ThemeToggle className="absolute right-4 top-4" /><div><p className="text-6xl font-black text-brand-700">404</p><h1 className="mt-3 text-2xl font-bold text-slate-900">Page not found</h1><p className="mt-2 text-slate-500">The page you requested is unavailable.</p><Link className="button-primary mt-6 inline-flex" to="/dashboard">Return to dashboard</Link></div></main>
}