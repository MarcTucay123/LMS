import { useCallback, useEffect, useMemo, useState } from 'react'
import { Search, UserCog, UsersRound } from 'lucide-react'
import { AdminPageHeader } from '../../components/AdminPageHeader'
import { EmptyState, ErrorState, LoadingState } from '../../components/ScreenState'
import { useAuth } from '../../hooks/useAuth'
import { supabase } from '../../lib/supabase'
import type { AccountStatus, Profile, UserRole } from '../../types/database'

const roles: UserRole[] = ['student', 'instructor', 'admin']
const statuses: AccountStatus[] = ['pending', 'active', 'inactive']

export function AdminUsersPage() {
  const { profile: currentProfile } = useAuth()
  const [users, setUsers] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [query, setQuery] = useState('')
  const [savingId, setSavingId] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true); setError(null)
    const { data, error: queryError } = await supabase.from('profiles').select('*').order('full_name')
    if (queryError) setError(queryError.message)
    else setUsers(data ?? [])
    setLoading(false)
  }, [])

  useEffect(() => {
    let active = true
    void supabase.from('profiles').select('*').order('full_name').then(({ data, error: queryError }) => {
      if (!active) return
      if (queryError) setError(queryError.message)
      else setUsers(data ?? [])
      setLoading(false)
    })
    return () => { active = false }
  }, [])

  const filteredUsers = useMemo(() => {
    const term = query.trim().toLowerCase()
    if (!term) return users
    return users.filter((user) => [user.full_name, user.email, user.school_id, user.role, user.status].some((value) => value.toLowerCase().includes(term)))
  }, [query, users])

  const updateUser = async (user: Profile, role: UserRole, status: AccountStatus) => {
    setSavingId(user.id); setError(null); setMessage(null)
    const { data, error: updateError } = await supabase.rpc('admin_update_user', {
      target_user_id: user.id,
      target_role: role,
      target_status: status,
    })
    setSavingId(null)
    if (updateError) {
      setError(updateError.message)
      return
    }
    setUsers((current) => current.map((item) => item.id === user.id ? data : item))
    setMessage(`${data.full_name} was updated.`)
  }

  return (
    <div className="mx-auto max-w-[1500px]">
      <AdminPageHeader icon={UsersRound} eyebrow="Administration" title="User accounts" description="Review synchronized users, activate or deactivate access, and manage database-assigned roles." />

      <div className="mb-5 flex flex-col gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
        <label className="relative block w-full max-w-md">
          <Search className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
          <input className="admin-search-input" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search name, email, ID, role, or status" />
        </label>
        <p className="text-sm font-semibold text-slate-500">{filteredUsers.length} of {users.length} accounts</p>
      </div>

      {message && <div className="mb-4 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm font-semibold text-emerald-800">{message}</div>}
      {loading && <LoadingState label="Loading user accounts…" />}
      {error && <ErrorState message={error} onRetry={() => void load()} />}
      {!loading && !error && filteredUsers.length === 0 && <EmptyState title="No matching users" description="Try another search term or run OneCampus synchronization." />}
      {!loading && !error && filteredUsers.length > 0 && (
        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="overflow-x-auto">
            <table className="admin-table">
              <thead><tr><th>User</th><th>School ID</th><th>Role</th><th>Status</th><th>Action</th></tr></thead>
              <tbody>
                {filteredUsers.map((user) => {
                  const isSelf = user.id === currentProfile?.id
                  return (
                    <UserRow key={`${user.id}-${user.role}-${user.status}`} user={user} isSelf={isSelf} saving={savingId === user.id} onSave={updateUser} />
                  )
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}

function UserRow({ user, isSelf, saving, onSave }: { user: Profile; isSelf: boolean; saving: boolean; onSave: (user: Profile, role: UserRole, status: AccountStatus) => Promise<void> }) {
  const [role, setRole] = useState<UserRole>(user.role)
  const [status, setStatus] = useState<AccountStatus>(user.status)
  const changed = role !== user.role || status !== user.status

  return (
    <tr>
      <td><div className="flex items-center gap-3"><div className="grid size-10 shrink-0 place-items-center rounded-full bg-blue-50 font-bold text-brand-700"><UserCog size={18} /></div><div><p className="font-bold text-slate-900">{user.full_name}{isSelf && <span className="ml-2 text-xs text-brand-700">You</span>}</p><p className="text-xs text-slate-500">{user.email}</p></div></div></td>
      <td><span className="font-mono text-xs text-slate-600">{user.school_id}</span></td>
      <td><select className="admin-select" value={role} onChange={(event) => setRole(event.target.value as UserRole)} disabled={isSelf}>{roles.map((item) => <option key={item} value={item}>{item}</option>)}</select></td>
      <td><select className="admin-select" value={status} onChange={(event) => setStatus(event.target.value as AccountStatus)} disabled={isSelf}>{statuses.map((item) => <option key={item} value={item}>{item}</option>)}</select></td>
      <td><button className="button-secondary min-w-20" disabled={!changed || saving || isSelf} onClick={() => void onSave(user, role, status)}>{saving ? 'Saving…' : 'Save'}</button></td>
    </tr>
  )
}