import type { Database } from '../types/database'

type ApiError = Error & { context?: Response }

export interface LocalUser {
  id: string
  email: string
  user_metadata?: Record<string, unknown>
}

export interface LocalSession {
  user: LocalUser
}

type AuthEvent = 'INITIAL_SESSION' | 'SIGNED_IN' | 'SIGNED_OUT' | 'PASSWORD_RECOVERY' | 'USER_UPDATED'
type AuthListener = (event: AuthEvent, session: LocalSession | null) => void
type Filter = { type: 'eq' | 'neq' | 'in'; column: string; value: unknown }
type TableName = keyof Database['public']['Tables']
type TableRow<T extends TableName> = Database['public']['Tables'][T]['Row']
type QueryResult<T, Single extends boolean> = { data: Single extends true ? T : T[]; error: ApiError | null }
type RpcName = keyof Database['public']['Functions']
type RpcArgs<T extends RpcName> = Database['public']['Functions'][T]['Args']
type RpcResult<T extends RpcName> = Database['public']['Functions'][T]['Returns']

const configuredUrl = import.meta.env.VITE_API_URL as string | undefined
const apiUrl = configuredUrl || `${import.meta.env.BASE_URL.replace(/\/$/, '')}/api/index.php`
const listeners = new Set<AuthListener>()
let currentSession: LocalSession | null = null

function apiError(message: string, response?: Response, payload?: unknown): ApiError {
  const error = new Error(message) as ApiError
  if (response) error.context = new Response(JSON.stringify(payload ?? { error: message }), {
    status: response.status,
    headers: { 'Content-Type': 'application/json' },
  })
  return error
}

async function request<T>(action: string, body: Record<string, unknown> = {}, options: RequestInit = {}): Promise<T> {
  const response = await fetch(apiUrl, {
    method: 'POST',
    credentials: 'include',
    headers: options.body instanceof FormData ? undefined : { 'Content-Type': 'application/json' },
    ...options,
    body: options.body ?? JSON.stringify({ action, ...body }),
  })
  const payload = await response.json().catch(() => ({})) as { error?: string } & T
  if (!response.ok) throw apiError(payload.error || `Request failed with status ${response.status}.`, response, payload)
  return payload
}

function notify(event: AuthEvent, session: LocalSession | null) {
  currentSession = session
  for (const listener of listeners) listener(event, session)
}

class QueryBuilder<T, Single extends boolean = false> implements PromiseLike<QueryResult<T, Single>> {
  private operation: 'select' | 'insert' | 'update' | 'delete' = 'select'
  private columns = '*'
  private values: unknown = null
  private filters: Filter[] = []
  private orders: { column: string; ascending: boolean }[] = []
  private rowLimit: number | null = null
  private singular: 'single' | 'maybeSingle' | null = null
  private returning = false

  constructor(private readonly table: string) {}

  select(columns = '*') { this.columns = columns; if (this.operation !== 'select') this.returning = true; return this }
  insert(values: unknown) { this.operation = 'insert'; this.values = values; return this }
  update(values: unknown) { this.operation = 'update'; this.values = values; return this }
  delete() { this.operation = 'delete'; return this }
  eq(column: string, value: unknown) { this.filters.push({ type: 'eq', column, value }); return this }
  neq(column: string, value: unknown) { this.filters.push({ type: 'neq', column, value }); return this }
  in(column: string, value: unknown[]) { this.filters.push({ type: 'in', column, value }); return this }
  order(column: string, options: { ascending?: boolean } = {}) { this.orders.push({ column, ascending: options.ascending !== false }); return this }
  limit(value: number) { this.rowLimit = value; return this }
  single() { this.singular = 'single'; return this as unknown as QueryBuilder<T, true> }
  maybeSingle() { this.singular = 'maybeSingle'; return this as unknown as QueryBuilder<T, true> }

  private async execute() {
    try {
      const response = await request<{ data: unknown }>('query', {
        table: this.table,
        operation: this.operation,
        columns: this.columns,
        values: this.values,
        filters: this.filters,
        orders: this.orders,
        limit: this.rowLimit,
        singular: this.singular,
        returning: this.returning,
      })
      return { data: response.data, error: null } as QueryResult<T, Single>
    } catch (caught) {
      return { data: (this.singular ? null : []) as QueryResult<T, Single>['data'], error: caught as ApiError }
    }
  }

  then<TResult1 = QueryResult<T, Single>, TResult2 = never>(
    onfulfilled?: ((value: QueryResult<T, Single>) => TResult1 | PromiseLike<TResult1>) | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null,
  ): PromiseLike<TResult1 | TResult2> {
    return this.execute().then(onfulfilled, onrejected)
  }
}

const auth = {
  async getSession() {
    try {
      const result = await request<{ session: LocalSession | null }>('auth.session')
      currentSession = result.session
      return { data: { session: result.session }, error: null }
    } catch (caught) {
      return { data: { session: null }, error: caught as ApiError }
    }
  },
  onAuthStateChange(listener: AuthListener) {
    listeners.add(listener)
    window.setTimeout(() => listener('INITIAL_SESSION', currentSession), 0)
    return { data: { subscription: { unsubscribe: () => listeners.delete(listener) } } }
  },
  async signInWithPassword(credentials: { email: string; password: string }) {
    try {
      const result = await request<{ session: LocalSession; user: LocalUser }>('auth.login', credentials)
      notify('SIGNED_IN', result.session)
      return { data: result, error: null }
    } catch (caught) {
      return { data: { session: null, user: null }, error: caught as ApiError }
    }
  },
  async signOut() {
    try { await request('auth.logout') } finally { notify('SIGNED_OUT', null) }
    return { error: null }
  },
  async refreshSession() {
    const result = await auth.getSession()
    if (result.data.session) notify('SIGNED_IN', result.data.session)
    return result
  },
  async resetPasswordForEmail(email: string, options: { redirectTo?: string } = {}) {
    try {
      const data = await request<{ reset_url?: string }>('auth.forgot-password', { email, redirectTo: options.redirectTo })
      return { data, error: null }
    } catch (caught) { return { data: null, error: caught as ApiError } }
  },
  async updateUser(values: { password?: string }) {
    try {
      const data = await request<{ user: LocalUser }>('auth.update-user', { ...values, token: new URLSearchParams(window.location.search).get('token') })
      return { data, error: null }
    } catch (caught) { return { data: null, error: caught as ApiError } }
  },
}

function storageBucket(bucket: string) {
  return {
    async upload(path: string, file: File) {
      const form = new FormData()
      form.append('action', 'storage.upload')
      form.append('bucket', bucket)
      form.append('path', path)
      form.append('file', file)
      try { return { data: await request('storage.upload', {}, { body: form }), error: null } } catch (caught) { return { data: null, error: caught as ApiError } }
    },
    async remove(paths: string[]) {
      try { return { data: await request('storage.remove', { bucket, paths }), error: null } } catch (caught) { return { data: null, error: caught as ApiError } }
    },
    async createSignedUrl(path: string, expiresIn: number) {
      try {
        const data = await request<{ signedUrl: string }>('storage.signed-url', { bucket, path, expiresIn })
        return { data, error: null }
      } catch (caught) { return { data: { signedUrl: '' }, error: caught as ApiError } }
    },
  }
}

export const supabase = {
  auth,
  from: <T extends TableName>(table: T) => new QueryBuilder<TableRow<T>>(table),
  rpc: async <T extends RpcName>(name: T, args: RpcArgs<T>) => {
    try { const response = await request<{ data: RpcResult<T> }>('rpc', { name, args }); return { data: response.data, error: null } }
    catch (caught) { return { data: null, error: caught as ApiError } }
  },
  functions: {
    invoke: async <T>(name: string, options: { body?: Record<string, unknown> } = {}) => {
      try { const data = await request<T>('function', { name, body: options.body ?? {} }); return { data, error: null } }
      catch (caught) { return { data: null, error: caught as ApiError } }
    },
  },
  storage: { from: storageBucket },
}