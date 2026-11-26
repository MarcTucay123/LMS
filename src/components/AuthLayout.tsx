import { GraduationCap } from 'lucide-react'
import { Outlet } from 'react-router-dom'
import { ThemeToggle } from './ThemeToggle'

export function AuthLayout() {
  return (
    <main className="relative min-h-screen bg-auth-pattern px-3 py-6 sm:px-4 sm:py-16">
      <ThemeToggle className="absolute right-3 top-3 border-white/25 bg-slate-950/25 text-white hover:bg-slate-950/40 sm:right-5 sm:top-5" />
      <div className="mx-auto w-full max-w-lg">
        <div className="mb-5 text-center text-white sm:mb-7">
          <div className="mx-auto mb-4 grid size-16 place-items-center rounded-2xl bg-white/15 ring-1 ring-white/30 backdrop-blur">
            <GraduationCap size={36} aria-hidden="true" />
          </div>
          <h1 className="text-2xl font-bold">ADFC OneCampus</h1>
          <p className="mt-1 text-sm text-blue-100">Learning Management System</p>
        </div>
        <div className="rounded-2xl bg-white p-4 shadow-2xl shadow-slate-950/20 min-[380px]:p-5 sm:p-8"><Outlet /></div>
      </div>
    </main>
  )
}