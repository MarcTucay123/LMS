import { GraduationCap } from 'lucide-react'
import { Outlet } from 'react-router-dom'

export function AuthLayout() {
  return (
    <main className="min-h-screen bg-auth-pattern px-4 py-10 sm:py-16">
      <div className="mx-auto w-full max-w-md">
        <div className="mb-7 text-center text-white">
          <div className="mx-auto mb-4 grid size-16 place-items-center rounded-2xl bg-white/15 ring-1 ring-white/30 backdrop-blur">
            <GraduationCap size={36} aria-hidden="true" />
          </div>
          <h1 className="text-2xl font-bold">ADFC OneCampus</h1>
          <p className="mt-1 text-sm text-blue-100">Learning Management System</p>
        </div>
        <div className="rounded-2xl bg-white p-6 shadow-2xl shadow-slate-950/20 sm:p-8"><Outlet /></div>
      </div>
    </main>
  )
}