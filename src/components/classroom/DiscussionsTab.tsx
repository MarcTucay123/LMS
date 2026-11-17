import { useCallback, useEffect, useRef, useState, type FormEvent } from 'react'
import { Lock, MessageCircle, Plus, Send, Trash2, X } from 'lucide-react'
import { EmptyState, ErrorState, LoadingState } from '../ScreenState'
import { useAuth } from '../../hooks/useAuth'
import { supabase } from '../../lib/supabase'
import type { Database } from '../../types/database'
import { TabHeading } from './MaterialsTab'

type Topic = Database['public']['Tables']['discussion_topics']['Row'] & { author: { full_name: string } | null }
type Post = Database['public']['Tables']['discussion_posts']['Row'] & { author: { full_name: string } | null }

const LIVE_REFRESH_MS = 1000

export function DiscussionsTab({ classId, canManage, canParticipate }: { classId: string; canManage: boolean; canParticipate: boolean }) {
  const { profile } = useAuth()
  const [topics, setTopics] = useState<Topic[]>([])
  const [posts, setPosts] = useState<Post[]>([])
  const [selected, setSelected] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [open, setOpen] = useState(false)
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [reply, setReply] = useState('')
  const messagesRef = useRef<HTMLDivElement>(null)
  const followLatestMessage = useRef(true)

  const fetchTopics = useCallback(async (showLoading = false) => {
    if (showLoading) setLoading(true)
    const { data, error: queryError } = await supabase
      .from('discussion_topics')
      .select('*, author:profiles!discussion_topics_created_by_fkey(full_name)')
      .eq('class_id', classId)
      .order('created_at', { ascending: false })

    if (queryError) {
      if (showLoading) setError(queryError.message)
    } else {
      setTopics((data ?? []).map(normalizeTopic))
      setError(null)
    }
    if (showLoading) setLoading(false)
  }, [classId])

  const fetchPosts = useCallback(async (topicId: string, reportError = false) => {
    const { data, error: queryError } = await supabase
      .from('discussion_posts')
      .select('*, author:profiles!discussion_posts_author_id_fkey(full_name)')
      .eq('topic_id', topicId)
      .order('created_at')

    if (queryError) {
      if (reportError) setError(queryError.message)
      return
    }
    setPosts((data ?? []).map(normalizePost))
    setError(null)
  }, [])

  const load = useCallback(async () => {
    await fetchTopics(true)
  }, [fetchTopics])

  useEffect(() => {
    queueMicrotask(() => void fetchTopics(true))
  }, [fetchTopics])

  useEffect(() => {
    let requestRunning = false
    const refreshTopics = async () => {
      if (document.hidden || requestRunning) return
      requestRunning = true
      await fetchTopics()
      requestRunning = false
    }
    const timer = window.setInterval(() => void refreshTopics(), LIVE_REFRESH_MS)
    const refreshWhenVisible = () => { if (document.visibilityState === 'visible') void refreshTopics() }
    document.addEventListener('visibilitychange', refreshWhenVisible)
    return () => {
      window.clearInterval(timer)
      document.removeEventListener('visibilitychange', refreshWhenVisible)
    }
  }, [fetchTopics])

  useEffect(() => {
    if (!selected) return
    let requestRunning = false
    const refreshPosts = async (reportError = false) => {
      if (document.hidden || requestRunning) return
      requestRunning = true
      await fetchPosts(selected, reportError)
      requestRunning = false
    }
    void refreshPosts(true)
    const timer = window.setInterval(() => void refreshPosts(), LIVE_REFRESH_MS)
    const refreshWhenVisible = () => { if (document.visibilityState === 'visible') void refreshPosts() }
    document.addEventListener('visibilitychange', refreshWhenVisible)
    return () => {
      window.clearInterval(timer)
      document.removeEventListener('visibilitychange', refreshWhenVisible)
    }
  }, [fetchPosts, selected])

  useEffect(() => {
    const frame = window.requestAnimationFrame(() => {
      const messages = messagesRef.current
      if (messages && followLatestMessage.current) messages.scrollTo({ top: messages.scrollHeight, behavior: 'smooth' })
    })
    return () => window.cancelAnimationFrame(frame)
  }, [posts.length, selected])

  const openTopic = (id: string) => {
    followLatestMessage.current = true
    setSelected(id)
    setPosts([])
    setError(null)
  }

  const createTopic = async (event: FormEvent) => {
    event.preventDefault()
    if (!title.trim() || !body.trim()) return setError('Add a title and opening message.')
    const { data, error: insertError } = await supabase.from('discussion_topics').insert({ class_id: classId, title: title.trim(), body: body.trim() }).select('id').single()
    if (insertError) return setError(insertError.message)
    setTitle('')
    setBody('')
    setOpen(false)
    await fetchTopics()
    openTopic(data.id)
  }

  const sendReply = async (event: FormEvent) => {
    event.preventDefault()
    if (!selected || !reply.trim()) return
    const { error: insertError } = await supabase.from('discussion_posts').insert({ topic_id: selected, body: reply.trim() })
    if (insertError) return setError(insertError.message)
    followLatestMessage.current = true
    setReply('')
    await fetchPosts(selected, true)
  }

  const removeTopic = async (id: string) => {
    const { error: deleteError } = await supabase.from('discussion_topics').delete().eq('id', id)
    if (deleteError) return setError(deleteError.message)
    if (selected === id) {
      setSelected(null)
      setPosts([])
    }
    await fetchTopics()
  }

  const current = topics.find((topic) => topic.id === selected)

  return (
    <section>
      <TabHeading title="Discussions" description="Ask questions and exchange ideas with classmates. Messages update every second." action={canParticipate && <button className={open ? 'button-secondary' : 'button-primary'} onClick={() => setOpen((value) => !value)}>{open ? <><X size={17} /> Cancel</> : <><Plus size={17} /> New topic</>}</button>} />

      {open && canParticipate && (
        <form className="workspace-form mb-5" onSubmit={createTopic}>
          <input className="form-input" placeholder="Topic title" value={title} onChange={(event) => setTitle(event.target.value)} />
          <textarea className="form-textarea" placeholder="Opening message" value={body} onChange={(event) => setBody(event.target.value)} />
          <div className="flex justify-end"><button className="button-primary">Post topic</button></div>
        </form>
      )}

      {loading && <LoadingState label="Loading discussions…" />}
      {error && <ErrorState message={error} onRetry={() => void load()} />}
      {!loading && !error && topics.length === 0 && <EmptyState title="No discussions yet" description={canParticipate ? 'Start the first class conversation.' : 'No discussion activity is available for review.'} />}

      {topics.length > 0 && (
        <div className="discussion-live-layout grid min-h-0 gap-4 lg:grid-cols-[320px_minmax(0,1fr)] lg:gap-5">
          <div className="min-h-0 space-y-2 overflow-y-auto overscroll-contain pr-1">
            {topics.map((topic) => (
              <button key={topic.id} className={`discussion-topic ${selected === topic.id ? 'discussion-topic-active' : ''}`} onClick={() => openTopic(topic.id)}>
                <div className="flex min-w-0 items-center gap-2"><MessageCircle className="shrink-0" size={16} /><strong className="truncate">{topic.title}</strong>{topic.is_locked && <Lock className="shrink-0" size={13} />}</div>
                <span>{topic.author?.full_name ?? 'Class member'} · {new Date(topic.created_at).toLocaleDateString()}</span>
              </button>
            ))}
          </div>

          <div className="flex min-h-0 flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white">
            {!current ? <EmptyState title="Select a topic" description="Choose a discussion to read." /> : (
              <>
                <div className="max-h-40 shrink-0 overflow-y-auto border-b border-slate-100 p-4 sm:p-5"><div className="flex items-start justify-between gap-3"><div className="min-w-0"><h3 className="break-words text-lg font-extrabold text-slate-900">{current.title}</h3><p className="mt-2 whitespace-pre-wrap break-words text-sm text-slate-600">{current.body}</p></div>{canParticipate && (canManage || current.created_by === profile?.id) && <button className="icon-action text-red-600" onClick={() => void removeTopic(current.id)}><Trash2 size={17} /></button>}</div></div>
                <div
                  ref={messagesRef}
                  className="min-h-0 flex-1 space-y-3 overflow-y-auto overscroll-contain p-4 sm:p-5"
                  onScroll={(event) => {
                    const messages = event.currentTarget
                    followLatestMessage.current = messages.scrollHeight - messages.scrollTop - messages.clientHeight < 80
                  }}
                >
                  {posts.map((post) => <div className="rounded-xl bg-slate-50 p-3" key={post.id}><p className="text-xs font-bold text-brand-700">{post.author?.full_name ?? 'Class member'}</p><p className="mt-1 whitespace-pre-wrap text-sm text-slate-700">{post.body}</p></div>)}
                  {posts.length === 0 && <p className="text-sm text-slate-400">No replies yet.</p>}
                </div>
                {canParticipate && !current.is_locked && <form className="flex shrink-0 gap-2 border-t border-slate-100 bg-white p-3 sm:p-4" onSubmit={sendReply}><input className="form-input mt-0" placeholder="Write a reply" value={reply} onChange={(event) => setReply(event.target.value)} /><button className="button-primary" aria-label="Send reply"><Send size={17} /></button></form>}
              </>
            )}
          </div>
        </div>
      )}
    </section>
  )
}

function normalizeTopic(value: unknown): Topic {
  const item = value as Topic & { author: Topic['author'] | Topic['author'][] }
  return { ...item, author: Array.isArray(item.author) ? item.author[0] ?? null : item.author }
}

function normalizePost(value: unknown): Post {
  const item = value as Post & { author: Post['author'] | Post['author'][] }
  return { ...item, author: Array.isArray(item.author) ? item.author[0] ?? null : item.author }
}