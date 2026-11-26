import { useCallback, useEffect, useRef, useState, type FormEvent, type PointerEvent as ReactPointerEvent } from 'react'
import { ArrowLeft, AudioLines, Bell, BellOff, CalendarClock, Camera, Clock3, Download, EllipsisVertical, Eye, FileText, History, ImagePlus, Lock, MessageCircle, Mic, Paperclip, Pin, PinOff, Plus, Reply, Send, Smile, Square, SwitchCamera, UsersRound, Video, X } from 'lucide-react'
import { EmptyState, ErrorState, LoadingState } from '../ScreenState'
import { useAuth } from '../../hooks/useAuth'
import { supabase } from '../../lib/supabase'
import type { Database, DiscussionCallStatus, DiscussionLiveSessionHistory, DiscussionReadReceipt } from '../../types/database'
import { TabHeading } from './MaterialsTab'
import { useClassNotifications } from '../../hooks/useClassNotifications'
import { useConfirmation } from '../../hooks/useConfirmation'
import { EnrolledStudentsPanel } from './StudentsTab'
import { DocumentPreviewModal, type PreviewDocument } from './DocumentPreviewModal'
import { messageFrom, safeFileName } from './workspace'
import { ProfileAvatar } from '../ProfileAvatar'
import { useDiscussionCall } from '../../hooks/useDiscussionCall'

type Topic = Database['public']['Tables']['discussion_topics']['Row'] & { author: { full_name: string; avatar_path: string | null } | null; is_joined: boolean; muted_until: string | null }
type MuteDuration = 'one_hour' | 'eight_hours' | 'one_day' | 'until_unmuted'
type Reaction = { emoji: string; count: number; reacted_by_me: boolean; users: { id: string; full_name: string; avatar_path: string | null }[] }
type Post = Database['public']['Tables']['discussion_posts']['Row'] & {
  author: { full_name: string; avatar_path: string | null } | null
  reply_to_author_id: string | null
  reply_to_author_name: string | null
  reply_to_body: string | null
  reply_to_attachment_name: string | null
  reply_to_is_deleted: boolean
  reactions: Reaction[]
}
type MessageMenu = { postId: string; left: number; top: number; side: 'own' | 'other'; placement: 'above' | 'below' }
type ReactionMenu = { postId: string; left: number; top: number }

const LIVE_REFRESH_MS = 1000
const MAX_ATTACHMENT_BYTES = 10 * 1024 * 1024
const COMPOSER_EMOJIS = ['😀', '😃', '😄', '😁', '😂', '😊', '😍', '🥰', '😎', '🤔', '😢', '😭', '😡', '👍', '👎', '❤️', '🎉', '🔥', '🙏', '👏', '💯']

export function DiscussionsTab({ classId, canManage, canParticipate, expectedRosterCount }: { classId: string; canManage: boolean; canParticipate: boolean; expectedRosterCount: number }) {
  const { confirm } = useConfirmation()
  const { profile } = useAuth()
  const { activeTopicId: joinedCallTopicId, activeTopicTitle: joinedCallTitle, isJoined: isInDiscussionCall, openCall: openDiscussionCall } = useDiscussionCall()
  const { isUnread, markItemViewed, reload: reloadNotifications } = useClassNotifications()
  const [topics, setTopics] = useState<Topic[]>([])
  const [posts, setPosts] = useState<Post[]>([])
  const [selected, setSelected] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [open, setOpen] = useState(false)
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [reply, setReply] = useState('')
  const [emojiPickerOpen, setEmojiPickerOpen] = useState(false)
  const [attachment, setAttachment] = useState<File | null>(null)
  const [sending, setSending] = useState(false)
  const [recording, setRecording] = useState(false)
  const [recordingSeconds, setRecordingSeconds] = useState(0)
  const [cameraOpen, setCameraOpen] = useState(false)
  const [previewDocument, setPreviewDocument] = useState<PreviewDocument | null>(null)
  const [replyingTo, setReplyingTo] = useState<Post | null>(null)
  const [messageMenu, setMessageMenu] = useState<MessageMenu | null>(null)
  const [reactionMenu, setReactionMenu] = useState<ReactionMenu | null>(null)
  const [topicMenu, setTopicMenu] = useState<string | null>(null)
  const [conversationMenuOpen, setConversationMenuOpen] = useState(false)
  const [rosterOpen, setRosterOpen] = useState(false)
  const [liveHistoryOpen, setLiveHistoryOpen] = useState(false)
  const [pinnedMessagesOpen, setPinnedMessagesOpen] = useState(false)
  const [highlightedMessageId, setHighlightedMessageId] = useState<string | null>(null)
  const [activeCall, setActiveCall] = useState<DiscussionCallStatus | null>(null)
  const [muteTopic, setMuteTopic] = useState<Topic | null>(null)
  const [muteDuration, setMuteDuration] = useState<MuteDuration>('one_hour')
  const [mutePending, setMutePending] = useState(false)
  const [messageActionPending, setMessageActionPending] = useState<string | null>(null)
  const [readReceipts, setReadReceipts] = useState<DiscussionReadReceipt[]>([])
  const messagesRef = useRef<HTMLDivElement>(null)
  const replyInputRef = useRef<HTMLInputElement>(null)
  const composerEmojiRef = useRef<HTMLDivElement>(null)
  const messageMenuRef = useRef<HTMLDivElement>(null)
  const reactionMenuRef = useRef<HTMLDivElement>(null)
  const topicMenuRef = useRef<HTMLDivElement>(null)
  const conversationMenuRef = useRef<HTMLDivElement>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const mediaInputRef = useRef<HTMLInputElement>(null)
  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const mediaStreamRef = useRef<MediaStream | null>(null)
  const recordingChunksRef = useRef<Blob[]>([])
  const recordingTimerRef = useRef<number | null>(null)
  const discardRecordingRef = useRef(false)
  const longPressRef = useRef<{ timer: number; postId: string; x: number; y: number } | null>(null)
  const followLatestMessage = useRef(true)
  const highlightTimerRef = useRef<number | null>(null)
  const current = topics.find((topic) => topic.id === selected)
  const currentUserUid = profile?.onecampus_user_id ?? profile?.id
  const closeLiveHistory = useCallback(() => setLiveHistoryOpen(false), [])

  const fetchTopics = useCallback(async (showLoading = false) => {
    if (showLoading) setLoading(true)
    const { data, error: queryError } = await supabase
      .from('discussion_topics')
      .select('*, author:profiles!discussion_topics_created_by_fkey(full_name, avatar_path)')
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
      .select('*, author:profiles!discussion_posts_author_id_fkey(full_name, avatar_path)')
      .eq('topic_id', topicId)
      .order('created_at')

    if (queryError) {
      if (reportError) setError(queryError.message)
      return
    }
    const nextPosts = (data ?? []).map(normalizePost)
    setPosts(nextPosts)
    setMessageMenu((currentMenu) => currentMenu && !nextPosts.some((post) => post.id === currentMenu.postId && !post.is_deleted) ? null : currentMenu)
    setReactionMenu((currentMenu) => currentMenu && !nextPosts.some((post) => post.id === currentMenu.postId && !post.is_deleted) ? null : currentMenu)
    setReplyingTo((currentReply) => currentReply ? nextPosts.find((post) => post.id === currentReply.id && !post.is_deleted) ?? null : null)
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
    if (!selected || posts.length === 0 || (!current?.is_joined && profile?.role !== 'admin')) {
      return
    }
    let active = true
    const latestPost = posts[posts.length - 1]
    const shouldAdvance = document.visibilityState === 'visible' && document.hasFocus() && followLatestMessage.current
    void supabase.rpc('mark_discussion_read', { target_topic_id: selected, target_post_id: shouldAdvance ? latestPost.id : null }).then(({ data }) => {
      if (active && data) setReadReceipts(data)
    })
    return () => { active = false }
  }, [current?.is_joined, posts, profile?.role, selected])

  useEffect(() => {
    if (!selected) return
    let active = true
    let requestRunning = false
    const refreshCallStatus = async () => {
      if (document.hidden || requestRunning) return
      requestRunning = true
      const { data } = await supabase.rpc('discussion_live_call_status', { target_topic_id: selected })
      requestRunning = false
      if (!active) return
      setActiveCall((currentStatus) => {
        if (!data) return null
        if (currentStatus?.id === data.id && currentStatus.participant_count === data.participant_count && currentStatus.is_host === data.is_host) return currentStatus
        return data
      })
    }
    void refreshCallStatus()
    const timer = window.setInterval(() => void refreshCallStatus(), LIVE_REFRESH_MS)
    const refreshWhenVisible = () => { if (document.visibilityState === 'visible') void refreshCallStatus() }
    document.addEventListener('visibilitychange', refreshWhenVisible)
    return () => {
      active = false
      window.clearInterval(timer)
      document.removeEventListener('visibilitychange', refreshWhenVisible)
    }
  }, [selected])

  useEffect(() => {
    const frame = window.requestAnimationFrame(() => {
      const messages = messagesRef.current
      if (messages && followLatestMessage.current) messages.scrollTo({ top: messages.scrollHeight, behavior: 'smooth' })
    })
    return () => window.cancelAnimationFrame(frame)
  }, [posts.length, selected])

  const closeMessageMenu = useCallback(() => setMessageMenu(null), [])
  const closeReactionMenu = useCallback(() => setReactionMenu(null), [])

  useEffect(() => {
    if (!messageMenu) return
    const closeOnOutsidePointer = (event: PointerEvent) => {
      if (!messageMenuRef.current?.contains(event.target as Node)) closeMessageMenu()
    }
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') closeMessageMenu()
    }
    document.addEventListener('pointerdown', closeOnOutsidePointer)
    document.addEventListener('keydown', closeOnEscape)
    return () => {
      document.removeEventListener('pointerdown', closeOnOutsidePointer)
      document.removeEventListener('keydown', closeOnEscape)
    }
  }, [closeMessageMenu, messageMenu])

  useEffect(() => {
    if (!reactionMenu) return
    const closeOnOutsidePointer = (event: PointerEvent) => {
      if (!reactionMenuRef.current?.contains(event.target as Node)) closeReactionMenu()
    }
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') closeReactionMenu() }
    document.addEventListener('pointerdown', closeOnOutsidePointer)
    document.addEventListener('keydown', closeOnEscape)
    return () => {
      document.removeEventListener('pointerdown', closeOnOutsidePointer)
      document.removeEventListener('keydown', closeOnEscape)
    }
  }, [closeReactionMenu, reactionMenu])

  useEffect(() => {
    if (!topicMenu) return
    const closeOnOutsidePointer = (event: PointerEvent) => {
      if (!topicMenuRef.current?.contains(event.target as Node)) setTopicMenu(null)
    }
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') setTopicMenu(null) }
    document.addEventListener('pointerdown', closeOnOutsidePointer)
    document.addEventListener('keydown', closeOnEscape)
    return () => {
      document.removeEventListener('pointerdown', closeOnOutsidePointer)
      document.removeEventListener('keydown', closeOnEscape)
    }
  }, [topicMenu])

  useEffect(() => {
    if (!conversationMenuOpen) return
    const closeOnOutsidePointer = (event: PointerEvent) => {
      if (!conversationMenuRef.current?.contains(event.target as Node)) setConversationMenuOpen(false)
    }
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') setConversationMenuOpen(false) }
    document.addEventListener('pointerdown', closeOnOutsidePointer)
    document.addEventListener('keydown', closeOnEscape)
    return () => {
      document.removeEventListener('pointerdown', closeOnOutsidePointer)
      document.removeEventListener('keydown', closeOnEscape)
    }
  }, [conversationMenuOpen])

  useEffect(() => {
    if (!emojiPickerOpen) return
    const closeOnOutsidePointer = (event: PointerEvent) => {
      if (!composerEmojiRef.current?.contains(event.target as Node)) setEmojiPickerOpen(false)
    }
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') setEmojiPickerOpen(false) }
    document.addEventListener('pointerdown', closeOnOutsidePointer)
    document.addEventListener('keydown', closeOnEscape)
    return () => {
      document.removeEventListener('pointerdown', closeOnOutsidePointer)
      document.removeEventListener('keydown', closeOnEscape)
    }
  }, [emojiPickerOpen])

  useEffect(() => () => {
    if (longPressRef.current) window.clearTimeout(longPressRef.current.timer)
    if (highlightTimerRef.current !== null) window.clearTimeout(highlightTimerRef.current)
    if (recordingTimerRef.current !== null) window.clearInterval(recordingTimerRef.current)
    const recorder = mediaRecorderRef.current
    if (recorder && recorder.state !== 'inactive') recorder.stop()
    mediaStreamRef.current?.getTracks().forEach((track) => track.stop())
  }, [])

  useEffect(() => {
    if (!muteTopic) return
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape' && !mutePending) setMuteTopic(null) }
    window.addEventListener('keydown', closeOnEscape)
    return () => {
      document.body.style.overflow = previousOverflow
      window.removeEventListener('keydown', closeOnEscape)
    }
  }, [mutePending, muteTopic])

  const openTopic = (id: string) => {
    if (recording) cancelRecording()
    setCameraOpen(false)
    markItemViewed(classId, 'discussions', id)
    followLatestMessage.current = true
    setSelected(id)
    setPosts([])
    setReadReceipts([])
    setReply('')
    setAttachment(null)
    setEmojiPickerOpen(false)
    setReplyingTo(null)
    setError(null)
    setTopicMenu(null)
    setConversationMenuOpen(false)
    setPinnedMessagesOpen(false)
    setHighlightedMessageId(null)
    closeMessageMenu()
    closeReactionMenu()
  }

  const returnToTopics = () => {
    if (recording) cancelRecording()
    setCameraOpen(false)
    setSelected(null)
    setPosts([])
    setReadReceipts([])
    setReply('')
    setAttachment(null)
    setEmojiPickerOpen(false)
    setReplyingTo(null)
    setError(null)
    setTopicMenu(null)
    setConversationMenuOpen(false)
    setPinnedMessagesOpen(false)
    setHighlightedMessageId(null)
    closeMessageMenu()
    closeReactionMenu()
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
    if (!selected || (!reply.trim() && !attachment) || sending || recording || !currentUserUid) return
    setSending(true)
    setError(null)
    let attachmentPath = ''
    try {
      if (attachment) {
        attachmentPath = `${classId}/${selected}/${currentUserUid}/${crypto.randomUUID()}-${safeFileName(attachment.name)}`
        const { error: uploadError } = await supabase.storage.from('discussions').upload(attachmentPath, attachment)
        if (uploadError) throw uploadError
      }
      const { error: insertError } = await supabase.from('discussion_posts').insert({
        topic_id: selected,
        body: reply.trim(),
        attachment_path: attachmentPath || null,
        attachment_name: attachment?.name ?? null,
        attachment_mime: attachment?.type || null,
        attachment_size: attachment?.size ?? null,
        attachment_kind: attachment ? attachmentKind(attachment) : null,
        reply_to_id: replyingTo?.id ?? null,
      })
      if (insertError) throw insertError
      followLatestMessage.current = true
      setReply('')
      setAttachment(null)
      setEmojiPickerOpen(false)
      setReplyingTo(null)
      await fetchPosts(selected, true)
    } catch (caught) {
      if (attachmentPath) await supabase.storage.from('discussions').remove([attachmentPath])
      setError(messageFrom(caught))
    } finally {
      setSending(false)
    }
  }

  const hideTopic = async (id: string) => {
    setTopicMenu(null)
    const topic = topics.find((item) => item.id === id)
    if (!await confirm({ title: 'Delete conversation?', message: `This only removes ${topic ? `“${topic.title}”` : 'this discussion'} from your list. It will remain available to everyone else and will reappear for you if someone sends a new message.`, confirmLabel: 'Delete conversation', tone: 'danger', icon: 'delete' })) return
    const { error: deleteError } = await supabase.from('discussion_topics').delete().eq('id', id)
    if (deleteError) return setError(deleteError.message)
    if (selected === id) {
      setSelected(null)
      setPosts([])
    }
    await fetchTopics()
  }

  const joinDiscussion = async (topic: Topic) => {
    setTopicMenu(null)
    const { error: joinError } = await supabase.rpc('join_discussion', { target_topic_id: topic.id })
    if (joinError) return setError(joinError.message)
    setTopics((currentTopics) => currentTopics.map((item) => item.id === topic.id ? { ...item, is_joined: true } : item))
    followLatestMessage.current = true
    await fetchPosts(topic.id, true)
  }

  const leaveDiscussion = async (topic: Topic) => {
    setTopicMenu(null)
    if (!await confirm({ title: 'Leave discussion?', message: `You will stop participating in “${topic.title}”. The discussion stays in your list, and you can join it again later.`, confirmLabel: 'Leave discussion', tone: 'danger', icon: 'delete' })) return
    const { error: leaveError } = await supabase.rpc('leave_discussion', { target_topic_id: topic.id })
    if (leaveError) return setError(leaveError.message)
    setTopics((currentTopics) => currentTopics.map((item) => item.id === topic.id ? { ...item, is_joined: false } : item))
    if (selected === topic.id) {
      if (recording) cancelRecording()
      setCameraOpen(false)
      setPosts([])
      setReply('')
      setAttachment(null)
      setReplyingTo(null)
    }
  }

  const openMuteDialog = (topic: Topic) => {
    setTopicMenu(null)
    setMuteDuration('one_hour')
    setMuteTopic(topic)
  }

  const saveMute = async () => {
    if (!muteTopic) return
    setMutePending(true)
    const { data, error: muteError } = await supabase.rpc('set_discussion_mute', { target_topic_id: muteTopic.id, duration: muteDuration })
    setMutePending(false)
    if (muteError) return setError(muteError.message)
    markItemViewed(classId, 'discussions', muteTopic.id)
    setTopics((currentTopics) => currentTopics.map((item) => item.id === muteTopic.id ? { ...item, muted_until: data.muted_until } : item))
    setMuteTopic(null)
    await reloadNotifications()
  }

  const unmuteDiscussion = async (topic: Topic) => {
    setTopicMenu(null)
    const { data, error: muteError } = await supabase.rpc('set_discussion_mute', { target_topic_id: topic.id, duration: 'unmute' })
    if (muteError) return setError(muteError.message)
    setTopics((currentTopics) => currentTopics.map((item) => item.id === topic.id ? { ...item, muted_until: data.muted_until } : item))
    await reloadNotifications()
  }

  const openVideoCall = (joinImmediately: boolean) => {
    if (!current || !currentUserUid) return
    const result = openDiscussionCall({
      classId,
      topicId: current.id,
      topicTitle: current.title,
      canStart: current.is_joined || canManage,
      currentUserId: currentUserUid,
      joinImmediately,
    })
    if (result.blocked) setError(result.message ?? `Leave or end your current call in “${joinedCallTitle ?? 'another discussion'}” first.`)
  }
  const menuPost = messageMenu ? posts.find((post) => post.id === messageMenu.postId) : undefined
  const reactionPost = reactionMenu ? posts.find((post) => post.id === reactionMenu.postId) : undefined

  const openMessageMenu = useCallback((postId: string, clientX: number, clientY: number, isOwnMessage: boolean) => {
    const menuWidth = 192
    const menuHeight = 112
    const side = isOwnMessage ? 'own' : 'other'
    const left = Math.min(Math.max(8, clientX - (isOwnMessage ? menuWidth - 38 : 38)), window.innerWidth - menuWidth - 8)
    const placement = clientY - menuHeight - 14 >= 8 ? 'above' : 'below'
    const top = placement === 'above' ? clientY - menuHeight - 14 : Math.min(window.innerHeight - menuHeight - 8, clientY + 14)
    setMessageMenu({ postId, left, top, side, placement })
  }, [])

  const clearLongPress = () => {
    if (!longPressRef.current) return
    window.clearTimeout(longPressRef.current.timer)
    longPressRef.current = null
  }

  const startLongPress = (event: ReactPointerEvent, post: Post) => {
    if (post.is_deleted || event.pointerType === 'mouse' || (!canManage && !current?.is_joined)) return
    clearLongPress()
    const { clientX, clientY } = event
    const timer = window.setTimeout(() => {
      window.getSelection()?.removeAllRanges()
      openMessageMenu(post.id, clientX, clientY, post.author_id === currentUserUid)
      longPressRef.current = null
    }, 550)
    longPressRef.current = { timer, postId: post.id, x: clientX, y: clientY }
  }

  const moveLongPress = (event: ReactPointerEvent) => {
    const active = longPressRef.current
    if (!active || Math.hypot(event.clientX - active.x, event.clientY - active.y) <= 10) return
    clearLongPress()
  }

  const unsendMessage = async (post: Post) => {
    closeMessageMenu()
    if (!await confirm({ title: 'Unsend this message?', message: 'Your message content will be removed for everyone and replaced with a deleted-message notice.', confirmLabel: 'Unsend', tone: 'danger', icon: 'delete' })) return
    setMessageActionPending(post.id)
    const { error: deleteError } = await supabase.from('discussion_posts').delete().eq('id', post.id)
    setMessageActionPending(null)
    if (deleteError) return setError(deleteError.message)
    setPosts((currentPosts) => currentPosts.map((item) => item.id === post.id ? { ...item, body: '', is_deleted: true, is_pinned: false, pinned_by: null, pinned_at: null, reactions: [] } : item))
    setReplyingTo((currentReply) => currentReply?.id === post.id ? null : currentReply)
  }

  const beginReply = (post: Post) => {
    if (post.is_deleted) return
    closeMessageMenu()
    closeReactionMenu()
    setReplyingTo(post)
    window.requestAnimationFrame(() => document.getElementById('discussion-reply-input')?.focus())
  }

  const insertComposerEmoji = (emoji: string) => {
    const input = replyInputRef.current
    const selectionStart = input?.selectionStart ?? reply.length
    const selectionEnd = input?.selectionEnd ?? selectionStart
    const nextReply = `${reply.slice(0, selectionStart)}${emoji}${reply.slice(selectionEnd)}`
    const nextCursor = selectionStart + emoji.length
    setReply(nextReply)
    setEmojiPickerOpen(false)
    window.requestAnimationFrame(() => {
      input?.focus()
      input?.setSelectionRange(nextCursor, nextCursor)
    })
  }

  const selectAttachment = (file: File | null) => {
    if (!file) return
    if (file.size > MAX_ATTACHMENT_BYTES) {
      setError('Discussion attachments must be 10 MB or smaller.')
      return
    }
    setError(null)
    setAttachment(file)
  }

  const finishRecordingResources = () => {
    if (recordingTimerRef.current !== null) window.clearInterval(recordingTimerRef.current)
    recordingTimerRef.current = null
    mediaStreamRef.current?.getTracks().forEach((track) => track.stop())
    mediaStreamRef.current = null
    mediaRecorderRef.current = null
    setRecording(false)
  }

  const startRecording = async () => {
    if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === 'undefined') {
      setError('Audio recording is not supported by this browser.')
      return
    }
    try {
      setError(null)
      setEmojiPickerOpen(false)
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      const mimeType = ['audio/webm;codecs=opus', 'audio/ogg;codecs=opus', 'audio/mp4'].find((type) => MediaRecorder.isTypeSupported(type))
      const recorder = mimeType ? new MediaRecorder(stream, { mimeType }) : new MediaRecorder(stream)
      discardRecordingRef.current = false
      recordingChunksRef.current = []
      mediaStreamRef.current = stream
      mediaRecorderRef.current = recorder
      recorder.ondataavailable = (event) => { if (event.data.size > 0) recordingChunksRef.current.push(event.data) }
      recorder.onerror = () => { finishRecordingResources(); setError('The audio recording could not be completed.') }
      recorder.onstop = () => {
        const chunks = recordingChunksRef.current
        const recordedType = recorder.mimeType || mimeType || 'audio/webm'
        finishRecordingResources()
        if (discardRecordingRef.current || chunks.length === 0) return
        const blob = new Blob(chunks, { type: recordedType })
        if (blob.size > MAX_ATTACHMENT_BYTES) {
          setError('The audio recording is larger than 10 MB. Record a shorter clip.')
          return
        }
        const extension = recordedType.includes('ogg') ? 'ogg' : recordedType.includes('mp4') ? 'm4a' : 'weba'
        setAttachment(new File([blob], `voice-message-${new Date().toISOString().replace(/[:.]/g, '-')}.${extension}`, { type: recordedType }))
      }
      recorder.start(250)
      setRecordingSeconds(0)
      setRecording(true)
      recordingTimerRef.current = window.setInterval(() => setRecordingSeconds((value) => value + 1), 1000)
    } catch (caught) {
      finishRecordingResources()
      setError(caught instanceof DOMException && caught.name === 'NotAllowedError' ? 'Microphone permission was denied. Allow microphone access to record audio.' : 'Unable to start audio recording.')
    }
  }

  const stopRecording = () => {
    const recorder = mediaRecorderRef.current
    if (recorder && recorder.state !== 'inactive') recorder.stop()
  }

  const cancelRecording = () => {
    discardRecordingRef.current = true
    const recorder = mediaRecorderRef.current
    if (recorder && recorder.state !== 'inactive') recorder.stop()
    else finishRecordingResources()
  }

  const openReactionMenu = (post: Post, element: HTMLElement) => {
    if (post.is_deleted) return
    const rect = element.getBoundingClientRect()
    const width = 276
    setReactionMenu({ postId: post.id, left: Math.min(Math.max(8, rect.left + rect.width / 2 - width / 2), window.innerWidth - width - 8), top: Math.max(8, rect.top - 58) })
  }

  const toggleReaction = async (post: Post, emoji: string) => {
    closeReactionMenu()
    setMessageActionPending(post.id)
    const { error: reactionError } = await supabase.rpc('toggle_discussion_reaction', { target_post_id: post.id, emoji })
    setMessageActionPending(null)
    if (reactionError) return setError(reactionError.message)
    if (selected) await fetchPosts(selected, true)
  }

  const togglePinnedMessage = async (post: Post) => {
    closeMessageMenu()
    setMessageActionPending(post.id)
    const { data, error: updateError } = await supabase.from('discussion_posts').update({ is_pinned: !post.is_pinned }).eq('id', post.id).select('*').single()
    setMessageActionPending(null)
    if (updateError) return setError(updateError.message)
    const updated = normalizePost({ ...post, ...data, author: post.author })
    setPosts((currentPosts) => currentPosts.map((item) => item.id === post.id ? updated : item))
  }

  const togglePinnedConversation = async (topic: Topic) => {
    if (!canManage && !topic.is_joined) return
    setTopicMenu(null)
    setConversationMenuOpen(false)
    const { data, error: updateError } = await supabase.from('discussion_topics').update({ is_pinned: !topic.is_pinned }).eq('id', topic.id).select('*').single()
    if (updateError) return setError(updateError.message)
    setTopics((currentTopics) => currentTopics
      .map((item) => item.id === topic.id ? { ...item, ...data, author: item.author, is_joined: item.is_joined, muted_until: item.muted_until } : item)
      .sort((left, right) => Number(right.is_pinned) - Number(left.is_pinned) || new Date(right.pinned_at ?? right.created_at).getTime() - new Date(left.pinned_at ?? left.created_at).getTime()))
  }

  const openPinnedMessages = () => {
    setConversationMenuOpen(false)
    setPinnedMessagesOpen(true)
  }

  const showPinnedMessage = (postId: string) => {
    setPinnedMessagesOpen(false)
    followLatestMessage.current = false
    window.requestAnimationFrame(() => {
      const message = messagesRef.current?.querySelector<HTMLElement>(`[data-discussion-message-id="${postId}"]`)
      if (!message) return
      message.scrollIntoView({ behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth', block: 'center' })
      setHighlightedMessageId(postId)
      if (highlightTimerRef.current !== null) window.clearTimeout(highlightTimerRef.current)
      highlightTimerRef.current = window.setTimeout(() => {
        setHighlightedMessageId(null)
        highlightTimerRef.current = null
      }, 2200)
    })
  }

  const pinnedMessages = posts.filter((post) => post.is_pinned && !post.is_deleted)

  return (
    <section>
      <div className={current ? 'hidden lg:block' : ''}>
        <TabHeading title="Discussions" description="Ask questions and exchange ideas with classmates. Messages update every second." action={canParticipate && <button className={open ? 'button-secondary' : 'button-primary'} onClick={() => setOpen((value) => !value)}>{open ? <><X size={17} /> Cancel</> : <><Plus size={17} /> New topic</>}</button>} />
      </div>

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
        <div className={`discussion-live-layout content-sized-selector-layout grid min-h-0 gap-4 lg:gap-5 ${current ? 'discussion-conversation-view' : ''}`}>
          <div className={`discussion-topic-list content-sized-selector-list min-h-0 pr-1 lg:overflow-y-auto lg:overscroll-contain ${current ? 'discussion-topic-list-mobile-hidden' : ''}`}>
            {topics.map((topic) => {
              const isSelected = selected === topic.id
              const unread = isUnread(classId, 'discussions', topic.id)
              const isMuted = topic.muted_until !== null
              const canUseTopicActions = canParticipate
              return <div key={topic.id} className={`discussion-topic-container group relative ${isSelected ? 'discussion-topic-container-active' : ''}`} ref={topicMenu === topic.id ? topicMenuRef : undefined}>
                <button type="button" className={`discussion-topic pr-12 ${isSelected ? 'discussion-topic-active' : ''} ${unread ? 'notification-content-unread' : ''}`} onClick={() => openTopic(topic.id)}>
                  <div className="flex min-w-0 items-center gap-2"><MessageCircle className="shrink-0" size={16} /><strong className="truncate">{topic.title}</strong>{topic.is_pinned && <Pin className="shrink-0 text-amber-600" size={14} fill="currentColor" aria-label="Pinned conversation" />}{isInDiscussionCall && joinedCallTopicId === topic.id && <span className="discussion-topic-call-indicator" role="status" aria-label="You are in this discussion call" title="You are in this discussion call"><Video size={13} /></span>}{topic.is_locked && <Lock className="shrink-0" size={13} />}{isMuted && <BellOff className="discussion-muted-icon" size={14} aria-label="Notifications muted" />}{unread && <span className="discussion-unread-badge">Unread</span>}</div>
                  <span>{topic.author?.full_name ?? 'Class member'} · {new Date(topic.created_at).toLocaleDateString()}</span>
                </button>
                {canUseTopicActions && <button type="button" className="discussion-topic-action-trigger" onClick={() => setTopicMenu((currentMenu) => currentMenu === topic.id ? null : topic.id)} aria-label={`Options for ${topic.title}`} aria-haspopup="menu" aria-expanded={topicMenu === topic.id}><EllipsisVertical size={19} /></button>}
                {topicMenu === topic.id && <div className="discussion-topic-actions-menu" role="menu" aria-label={`Actions for ${topic.title}`}>
                  {(canManage || topic.is_joined) && <button type="button" className="discussion-topic-menu-neutral" role="menuitem" onClick={() => void togglePinnedConversation(topic)}>{topic.is_pinned ? <><PinOff size={16} /> Unpin conversation</> : <><Pin size={16} /> Pin conversation</>}</button>}
                  {topic.is_joined && (isMuted ? <button type="button" className="discussion-topic-menu-neutral" role="menuitem" onClick={() => void unmuteDiscussion(topic)}><Bell size={16} /> Unmute notifications</button> : <button type="button" className="discussion-topic-menu-neutral" role="menuitem" onClick={() => openMuteDialog(topic)}><BellOff size={16} /> Mute notifications</button>)}
                  {topic.is_joined && <button type="button" className="discussion-topic-menu-neutral" role="menuitem" onClick={() => void leaveDiscussion(topic)}>Leave discussion</button>}
                  <button type="button" role="menuitem" onClick={() => void hideTopic(topic.id)}>Delete conversation</button>
                </div>}
              </div>
            })}
          </div>

          <div className={`min-h-0 flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white lg:flex ${current ? 'flex' : 'hidden'}`}>
            {!current ? <EmptyState title="Select a topic" description="Choose a discussion to read." /> : (
              <>
                <div className="discussion-conversation-header">
                  <div className="max-h-40 overflow-y-auto p-4 pr-24 sm:p-5 sm:pr-28"><div className="flex items-start gap-3"><button type="button" className="icon-action lg:hidden" onClick={returnToTopics} aria-label="Back to discussion topics" title="Back to topics"><ArrowLeft size={19} /></button><div className="min-w-0 flex-1"><h3 className="break-words text-lg font-extrabold text-slate-900">{current.title}</h3><p className="mt-2 whitespace-pre-wrap break-words text-sm text-slate-600">{current.body}</p></div></div></div>
                  {(canManage || current.is_joined) && <div className="discussion-conversation-call-control"><button type="button" className={`discussion-conversation-menu-trigger ${isInDiscussionCall && joinedCallTopicId !== current.id ? 'discussion-call-trigger-blocked' : ''}`} onClick={() => openVideoCall(false)} aria-label="Open discussion video call" title={isInDiscussionCall && joinedCallTopicId !== current.id ? `Leave or end the call in ${joinedCallTitle ?? 'the current discussion'} first` : 'Video call'}><Video size={21} /></button></div>}
                  <div ref={conversationMenuRef} className="discussion-conversation-menu-control">
                    <button type="button" className="discussion-conversation-menu-trigger" onClick={() => setConversationMenuOpen((value) => !value)} aria-label="Conversation options" title="Conversation options" aria-haspopup="menu" aria-expanded={conversationMenuOpen}><EllipsisVertical size={21} /></button>
                    {conversationMenuOpen && <div className="discussion-conversation-menu" role="menu" aria-label="Conversation options"><button type="button" role="menuitem" onClick={openPinnedMessages}><Pin size={17} /> View Pinned Messages{pinnedMessages.length > 0 && <span className="discussion-menu-count">{pinnedMessages.length}</span>}</button><button type="button" role="menuitem" onClick={() => { setConversationMenuOpen(false); setRosterOpen(true) }}><UsersRound size={17} /> View Enrolled Students</button>{(canManage || canParticipate) && <button type="button" role="menuitem" onClick={() => { setConversationMenuOpen(false); setLiveHistoryOpen(true) }}><History size={17} /> Live Sessions History</button>}</div>}
                  </div>
                </div>
                {activeCall?.topic_id === current.id && !activeCall.is_host && current.is_joined && <div className="discussion-active-call-banner"><div className="discussion-active-call-host"><ProfileAvatar name={activeCall.host_name} avatarPath={activeCall.host_avatar_path} className="size-10 text-xs" clickable={false} /><div><strong><Video size={17} /> Live call in progress</strong><span>{activeCall.host_name} started a call · {activeCall.participant_count} participant{activeCall.participant_count === 1 ? '' : 's'}</span></div></div><button type="button" className="button-primary" onClick={() => openVideoCall(true)}><Video size={17} /> Join Call</button></div>}
                {!current.is_joined && canParticipate ? <div className="flex min-h-0 flex-1 items-center justify-center p-6"><div className="max-w-sm text-center"><div className="mx-auto grid size-14 place-items-center rounded-full bg-blue-50 text-brand-700"><MessageCircle size={26} /></div><h4 className="mt-4 text-lg font-extrabold text-slate-900">Join Discussion</h4><p className="mt-2 text-sm text-slate-500">Join this conversation to read messages, reply, and react.</p><button type="button" className="button-primary mt-5" onClick={() => void joinDiscussion(current)}>Join Discussion</button></div></div> : <><div
                  ref={messagesRef}
                  className="discussion-messages min-h-0 flex-1 space-y-3 overflow-y-auto p-4 sm:p-5"
                  onScroll={(event) => {
                    const messages = event.currentTarget
                    followLatestMessage.current = messages.scrollHeight - messages.scrollTop - messages.clientHeight < 80
                  }}
                >
                  {posts.map((post) => {
                    const isOwnMessage = post.author_id === currentUserUid
                    const hasMenuActions = !post.is_deleted
                    const canInteract = canParticipate && !current.is_locked && !post.is_deleted
                    const replyAuthor = post.reply_to_author_id === currentUserUid ? 'You' : post.reply_to_author_name ?? 'Class member'
                    const controls = canInteract || hasMenuActions
                    const postReadReceipts = readReceipts.filter((receipt) => receipt.post_id === post.id)
                    return (
                      <div data-discussion-message-id={post.id} className={`group flex w-full items-end gap-2 rounded-2xl transition duration-500 ${isOwnMessage ? 'justify-end' : 'justify-start'} ${highlightedMessageId === post.id ? 'discussion-message-highlighted' : ''}`} key={post.id}>
                        {!isOwnMessage && !post.is_deleted && <ProfileAvatar name={post.author?.full_name ?? 'Class member'} avatarPath={post.author?.avatar_path} className="size-9 text-[10px]" />}
                        {controls && isOwnMessage && <div className="discussion-message-controls order-1">
                          {hasMenuActions && <button type="button" className="discussion-message-action-trigger" onClick={(event) => { const rect = event.currentTarget.getBoundingClientRect(); openMessageMenu(post.id, rect.left + rect.width / 2, rect.top + rect.height / 2, true) }} aria-label="More message actions" aria-haspopup="menu" aria-expanded={messageMenu?.postId === post.id}><EllipsisVertical size={18} /></button>}
                          {canInteract && <button type="button" className="discussion-message-action-trigger" onClick={(event) => openReactionMenu(post, event.currentTarget)} aria-label="React to message" title="React"><Smile size={17} /></button>}
                          {canInteract && <button type="button" className="discussion-message-action-trigger" onClick={() => beginReply(post)} aria-label="Reply to message" title="Reply"><Reply size={17} /></button>}
                        </div>}
                        <div
                          className={`relative max-w-[85%] sm:max-w-[75%] ${isOwnMessage ? 'order-2' : 'order-1'} ${controls ? 'select-none lg:select-text' : ''}`}
                          onPointerDown={(event) => startLongPress(event, post)}
                          onPointerMove={moveLongPress}
                          onPointerUp={clearLongPress}
                          onPointerCancel={clearLongPress}
                          onContextMenu={(event) => { if (controls) event.preventDefault() }}
                        >
                          <article className={`${post.is_deleted ? 'discussion-message-deleted' : `rounded-2xl px-4 py-3 ${post.is_pinned ? 'ring-2 ring-amber-300 ring-offset-2' : ''} ${isOwnMessage ? 'rounded-br-md bg-brand-700 text-white shadow-sm shadow-blue-900/15' : 'rounded-bl-md bg-slate-50 text-slate-700'}`}`}>
                            {post.is_deleted ? <p>{isOwnMessage ? 'You deleted a message' : `${post.author?.full_name ?? 'Class member'} deleted a message`}</p> : <>
                            <div className="flex items-center gap-2"><p className={`text-xs font-bold ${isOwnMessage ? 'text-blue-100' : 'text-brand-700'}`}>{isOwnMessage ? 'You' : post.author?.full_name ?? 'Class member'}</p>{post.is_pinned && <span className={`inline-flex items-center gap-1 text-[10px] font-extrabold uppercase tracking-wide ${isOwnMessage ? 'text-amber-200' : 'text-amber-700'}`} title="Pinned message"><Pin size={11} fill="currentColor" /> Pinned</span>}</div>
                            {post.reply_to_id && <div className={`mt-2 rounded-xl border-l-4 px-3 py-2 text-xs ${isOwnMessage ? 'border-blue-200 bg-white/10 text-blue-50' : 'border-brand-600 bg-white text-slate-600'}`}><strong className="block">{replyAuthor}</strong><span className="block max-w-72 truncate opacity-80">{post.reply_to_is_deleted ? 'Deleted message' : post.reply_to_body || post.reply_to_attachment_name || 'Attachment'}</span></div>}
                            {post.body && <p className={`mt-1 whitespace-pre-wrap break-words text-sm ${isOwnMessage ? 'text-white' : 'text-slate-700'}`}>{post.body}</p>}
                            {post.attachment_path && post.attachment_name && post.attachment_kind && <DiscussionAttachment post={post} isOwnMessage={isOwnMessage} onPreview={() => setPreviewDocument({ bucket: 'discussions', path: post.attachment_path!, name: post.attachment_name! })} />}
                            {messageActionPending === post.id && <p className={`mt-1 text-[10px] font-semibold ${isOwnMessage ? 'text-blue-100' : 'text-slate-400'}`}>Updating…</p>}
                            </>}
                          </article>
                          {!post.is_deleted && post.reactions.length > 0 && <div className={`mt-1 flex flex-wrap gap-1 ${isOwnMessage ? 'justify-end' : 'justify-start'}`}>{post.reactions.map((reaction) => {
                            const reactorNames = reaction.users.map((reactor) => reactor.id === currentUserUid ? 'You' : reactor.full_name)
                            const reactionLabel = `${reaction.emoji} reacted by ${reactorNames.join(', ')}`
                            return <button key={reaction.emoji} type="button" className={`discussion-reaction-badge ${reaction.reacted_by_me ? 'discussion-reaction-badge-active' : ''}`} data-tooltip={reactorNames.join('\n')} title={reactorNames.join(', ')} aria-label={reactionLabel} onClick={() => canInteract && void toggleReaction(post, reaction.emoji)} disabled={!canInteract}>{reaction.emoji}<span>{reaction.count}</span></button>
                          })}</div>}
                          {postReadReceipts.length > 0 && <div className={`discussion-seen-row ${isOwnMessage ? 'justify-end' : 'justify-start'}`} aria-label={`Seen by ${postReadReceipts.map((receipt) => receipt.full_name).join(', ')}`}>
                            <span>Seen</span>
                            <div className="discussion-seen-avatars">{postReadReceipts.slice(0, 8).map((receipt) => <span key={receipt.user_id} title={`${receipt.full_name} · ${new Date(receipt.last_read_at).toLocaleString()}`}><ProfileAvatar name={receipt.full_name} avatarPath={receipt.avatar_path} className="size-5 text-[7px]" clickable={false} /></span>)}{postReadReceipts.length > 8 && <small title={postReadReceipts.slice(8).map((receipt) => receipt.full_name).join(', ')}>+{postReadReceipts.length - 8}</small>}</div>
                          </div>}
                        </div>
                        {controls && !isOwnMessage && <div className="discussion-message-controls order-2">
                          {canInteract && <button type="button" className="discussion-message-action-trigger" onClick={() => beginReply(post)} aria-label="Reply to message" title="Reply"><Reply size={17} /></button>}
                          {canInteract && <button type="button" className="discussion-message-action-trigger" onClick={(event) => openReactionMenu(post, event.currentTarget)} aria-label="React to message" title="React"><Smile size={17} /></button>}
                          {hasMenuActions && <button type="button" className="discussion-message-action-trigger" onClick={(event) => { const rect = event.currentTarget.getBoundingClientRect(); openMessageMenu(post.id, rect.left + rect.width / 2, rect.top + rect.height / 2, false) }} aria-label="More message actions" aria-haspopup="menu" aria-expanded={messageMenu?.postId === post.id}><EllipsisVertical size={18} /></button>}
                        </div>}
                        {isOwnMessage && !post.is_deleted && <ProfileAvatar name={post.author?.full_name ?? profile?.full_name ?? 'You'} avatarPath={post.author?.avatar_path ?? profile?.avatar_path} className="order-3 size-9 text-[10px]" />}
                      </div>
                    )
                  })}
                  {posts.length === 0 && <p className="text-sm text-slate-400">No replies yet.</p>}
                </div>
                {canParticipate && !current.is_locked && <form className="shrink-0 border-t border-slate-100 bg-white" onSubmit={sendReply}>
                  {replyingTo && <div className="flex items-start justify-between gap-3 border-b border-slate-100 bg-slate-50 px-4 py-3"><div className="min-w-0"><strong className="text-sm text-slate-700">Replying to {replyingTo.author_id === currentUserUid ? 'yourself' : replyingTo.author?.full_name ?? 'Class member'}</strong><p className="truncate text-xs text-slate-500">{replyingTo.body || replyingTo.attachment_name || 'Attachment'}</p></div><button type="button" className="grid size-8 shrink-0 place-items-center rounded-full text-slate-500 hover:bg-slate-200" onClick={() => setReplyingTo(null)} aria-label="Cancel reply"><X size={18} /></button></div>}
                  {attachment && <div className="discussion-composer-attachment"><div className="discussion-composer-attachment-icon">{attachmentIcon(attachmentKind(attachment), 20)}</div><div className="min-w-0 flex-1"><strong>{attachmentKind(attachment) === 'audio' ? 'Voice message' : attachment.name}</strong><span>{attachmentKindLabel(attachmentKind(attachment))} · {formatFileSize(attachment.size)}</span></div><button type="button" onClick={() => setAttachment(null)} aria-label="Remove attachment" title="Remove attachment"><X size={18} /></button></div>}
                  {recording && <div className="discussion-recording-bar"><span className="discussion-recording-dot" /><strong>Recording {formatRecordingTime(recordingSeconds)}</strong><span className="ml-auto text-xs font-semibold text-slate-500">Tap stop when finished</span><button type="button" onClick={cancelRecording} aria-label="Cancel recording" title="Cancel recording"><X size={18} /></button></div>}
                  <div className="discussion-composer">
                    <div className="discussion-composer-tools">
                      <button type="button" onClick={() => fileInputRef.current?.click()} aria-label="Attach a file" title="Attach a file" disabled={recording || sending}><Paperclip size={20} /></button>
                      <button type="button" onClick={() => mediaInputRef.current?.click()} aria-label="Attach an image or video" title="Attach an image or video" disabled={recording || sending}><ImagePlus size={20} /></button>
                      <button type="button" className={recording ? 'discussion-composer-tool-recording' : ''} onClick={() => recording ? stopRecording() : void startRecording()} aria-label={recording ? 'Stop audio recording' : 'Record audio'} title={recording ? 'Stop recording' : 'Record audio'} disabled={sending}>{recording ? <Square size={17} fill="currentColor" /> : <Mic size={20} />}</button>
                      <button type="button" onClick={() => { setEmojiPickerOpen(false); setCameraOpen(true) }} aria-label="Open camera" title="Open camera" disabled={recording || sending}><Camera size={20} /></button>
                      <input ref={fileInputRef} className="sr-only" type="file" onChange={(event) => { selectAttachment(event.target.files?.[0] ?? null); event.currentTarget.value = '' }} />
                      <input ref={mediaInputRef} className="sr-only" type="file" accept="image/*,video/*" onChange={(event) => { selectAttachment(event.target.files?.[0] ?? null); event.currentTarget.value = '' }} />
                    </div>
                    <div className="discussion-composer-input-wrap">
                      <input ref={replyInputRef} id="discussion-reply-input" className="discussion-composer-input" placeholder="Aa" value={reply} onChange={(event) => setReply(event.target.value)} autoComplete="off" aria-label="Write a reply" disabled={recording || sending} />
                      <div ref={composerEmojiRef} className="discussion-composer-emoji-control">
                        <button type="button" className="discussion-composer-smile" onClick={() => setEmojiPickerOpen((value) => !value)} aria-label="Choose an emoji" title="Choose an emoji" aria-haspopup="menu" aria-expanded={emojiPickerOpen} disabled={recording || sending}><Smile size={21} /></button>
                        {emojiPickerOpen && <div className="discussion-composer-emoji-picker" role="menu" aria-label="Choose an emoji">{COMPOSER_EMOJIS.map((emoji) => <button key={emoji} type="button" role="menuitem" onClick={() => insertComposerEmoji(emoji)} aria-label={`Insert ${emoji}`}>{emoji}</button>)}</div>}
                      </div>
                    </div>
                    {(reply.trim() || attachment) && !recording && <button type="submit" className="discussion-composer-send" aria-label="Send reply" title="Send reply" disabled={sending}>{sending ? <span className="size-4 animate-spin rounded-full border-2 border-white/40 border-t-white" /> : <Send size={20} />}</button>}
                  </div>
                </form>}</>}
              </>
            )}
          </div>
        </div>
      )}
      {messageMenu && menuPost && (
        <div ref={messageMenuRef} className={`discussion-message-actions-menu discussion-message-actions-menu-${messageMenu.side} discussion-message-actions-menu-${messageMenu.placement}`} style={{ left: messageMenu.left, top: messageMenu.top }} role="menu" aria-label="Message actions">
          <button type="button" role="menuitem" onClick={() => beginReply(menuPost)}><Reply size={16} /> Reply</button>
          {menuPost.author_id === currentUserUid && <button type="button" role="menuitem" onClick={() => void unsendMessage(menuPost)}>Unsend</button>}
          {(canManage || current?.is_joined) && <button type="button" role="menuitem" onClick={() => void togglePinnedMessage(menuPost)}>{menuPost.is_pinned ? <><PinOff size={16} /> Unpin</> : <><Pin size={16} /> Pin</>}</button>}
        </div>
      )}
      {reactionMenu && reactionPost && (
        <div ref={reactionMenuRef} className="discussion-reaction-picker" style={{ left: reactionMenu.left, top: reactionMenu.top }} role="menu" aria-label="Choose a reaction">
          {['👍','❤️','😂','😮','😢','😡'].map((emoji) => <button key={emoji} type="button" role="menuitem" onClick={() => void toggleReaction(reactionPost, emoji)} aria-label={`React ${emoji}`}>{emoji}</button>)}
        </div>
      )}
      {muteTopic && <div className="modal-backdrop print-hidden" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget && !mutePending) setMuteTopic(null) }}>
        <section className="modal-card max-w-lg p-0 sm:p-0" role="dialog" aria-modal="true" aria-labelledby="mute-conversation-title" aria-describedby="mute-conversation-description">
          <header className="flex items-center justify-between gap-4 border-b border-slate-200 px-5 py-5 sm:px-6"><div className="flex min-w-0 items-center gap-3"><div className="grid size-11 shrink-0 place-items-center rounded-full bg-blue-100 text-brand-700"><BellOff size={22} /></div><h2 id="mute-conversation-title" className="truncate text-xl font-black text-slate-900">Mute notifications</h2></div><button type="button" className="icon-action" onClick={() => setMuteTopic(null)} disabled={mutePending} aria-label="Close mute notifications"><X size={19} /></button></header>
          <div className="px-5 py-5 sm:px-6"><p id="mute-conversation-description" className="text-sm leading-6 text-slate-600">You won’t receive unread notifications for “{muteTopic.title}” during the selected time. You can still open and use the conversation.</p><fieldset className="mt-5 space-y-2"><legend className="sr-only">Mute duration</legend>{([['one_hour','For 1 hour'],['eight_hours','For 8 hours'],['one_day','For 24 hours'],['until_unmuted','Until I turn notifications back on']] as const).map(([value,label]) => <label key={value} className={`flex cursor-pointer items-center gap-3 rounded-xl border px-4 py-3 transition ${muteDuration === value ? 'border-blue-500 bg-blue-50' : 'border-slate-200 hover:bg-slate-50'}`}><input className="size-4 accent-blue-600" type="radio" name="discussion-mute-duration" value={value} checked={muteDuration === value} onChange={() => setMuteDuration(value)} /><span className="font-bold text-slate-700">{label}</span></label>)}</fieldset></div>
          <footer className="flex flex-col-reverse gap-2 border-t border-slate-200 bg-slate-50 px-5 py-4 sm:flex-row sm:justify-end sm:px-6"><button type="button" className="button-secondary" onClick={() => setMuteTopic(null)} disabled={mutePending}>Cancel</button><button type="button" className="button-primary" onClick={() => void saveMute()} disabled={mutePending}><BellOff size={17} /> {mutePending ? 'Muting…' : 'Mute notifications'}</button></footer>
        </section>
      </div>}
      {rosterOpen && <DiscussionRosterDialog classId={classId} expectedCount={expectedRosterCount} onClose={() => setRosterOpen(false)} />}
      {liveHistoryOpen && <DiscussionLiveHistoryDialog classId={classId} onClose={closeLiveHistory} />}
      {pinnedMessagesOpen && <PinnedMessagesDialog messages={pinnedMessages} currentUserUid={currentUserUid} onSelect={showPinnedMessage} onClose={() => setPinnedMessagesOpen(false)} />}
      {cameraOpen && <CameraCaptureDialog onClose={() => setCameraOpen(false)} onCapture={(file) => { selectAttachment(file); setCameraOpen(false) }} />}
      <DocumentPreviewModal document={previewDocument} onClose={() => setPreviewDocument(null)} />
    </section>
  )
}

function DiscussionLiveHistoryDialog({ classId, onClose }: { classId: string; onClose: () => void }) {
  const [sessions, setSessions] = useState<DiscussionLiveSessionHistory[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [historyError, setHistoryError] = useState<string | null>(null)
  const [previewDocument, setPreviewDocument] = useState<PreviewDocument | null>(null)

  const loadHistory = useCallback(async () => {
    setLoading(true)
    const { data, error } = await supabase.rpc('discussion_live_session_history', { target_class_id: classId })
    if (error) {
      setHistoryError(error.message)
    } else {
      setSessions(data)
      setSelectedId((currentId) => currentId && data.some((session) => session.id === currentId) ? currentId : data[0]?.id ?? null)
      setHistoryError(null)
    }
    setLoading(false)
  }, [classId])

  useEffect(() => {
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    queueMicrotask(() => void loadHistory())
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') onClose() }
    window.addEventListener('keydown', closeOnEscape)
    return () => {
      document.body.style.overflow = previousOverflow
      window.removeEventListener('keydown', closeOnEscape)
    }
  }, [loadHistory, onClose])

  const selectedSession = sessions.find((session) => session.id === selectedId) ?? null
  const canManageHistory = selectedSession?.can_manage ?? sessions[0]?.can_manage ?? false
  const myAttendance = selectedSession?.attendance[0] ?? null
  const totalStudents = selectedSession ? selectedSession.active_count + selectedSession.inactive_count + selectedSession.not_joined_count : 0

  return <div className="modal-backdrop print-hidden" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
    <section className="modal-card flex max-h-[90dvh] max-w-6xl flex-col overflow-hidden p-0 sm:p-0" role="dialog" aria-modal="true" aria-labelledby="live-session-history-title">
      <header className="flex items-center justify-between gap-3 border-b border-slate-200 px-4 py-4 sm:px-6"><div className="flex min-w-0 items-center gap-3"><div className="grid size-11 shrink-0 place-items-center rounded-full bg-blue-100 text-brand-700"><History size={21} /></div><div className="min-w-0"><p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">{canManageHistory ? 'Final attendance records' : 'My final attendance'}</p><h2 id="live-session-history-title" className="truncate text-lg font-black text-slate-900">Live Sessions History</h2></div></div><button type="button" className="icon-action" onClick={onClose} aria-label="Close live sessions history"><X size={19} /></button></header>
      <div className="min-h-0 flex-1 overflow-y-auto p-3 sm:p-5">
        {loading && <LoadingState label="Loading live session history…" />}
        {historyError && <ErrorState message={historyError} onRetry={() => void loadHistory()} />}
        {!loading && !historyError && sessions.length === 0 && <EmptyState title="No completed live sessions" description="Attendance history will appear after a call host ends a discussion live call." />}
        {!loading && !historyError && sessions.length > 0 && <div className="content-sized-selector-layout grid gap-4">
          <div className="content-sized-selector-list">{sessions.map((session) => { const ownRecord = session.attendance[0]; return <button type="button" key={session.id} className={`discussion-topic ${selectedId === session.id ? 'discussion-topic-active' : ''}`} onClick={() => setSelectedId(session.id)}><div className="flex min-w-0 items-center gap-2"><CalendarClock className="shrink-0" size={16} /><strong className="truncate">{session.topic_title}</strong></div><span>{new Date(session.ended_at).toLocaleString()}</span><span>{formatSessionDuration(session.started_at, session.ended_at)} · {session.events.length} interaction{session.events.length === 1 ? '' : 's'}</span>{session.can_manage ? <span>{session.active_count} active · {session.inactive_count} inactive · {session.not_joined_count} did not join</span> : ownRecord && <span className="inline-flex items-center gap-2 font-bold"><i className={`discussion-call-attendance-dot discussion-call-status-${ownRecord.attendance_status === 'not_joined' ? 'not-joined' : ownRecord.attendance_status}`} />My status: {historyAttendanceLabel(ownRecord.attendance_status)}</span>}</button> })}</div>
          {selectedSession && <div className="classroom-outline min-w-0 rounded-2xl border border-slate-200 bg-white p-4 sm:p-5">
            <div className="flex flex-col gap-4 border-b border-slate-200 pb-4 sm:flex-row sm:items-start sm:justify-between"><div><p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">Completed discussion call</p><h3 className="mt-1 text-xl font-black text-slate-900">{selectedSession.topic_title}</h3><p className="mt-1 text-sm text-slate-500">Hosted by {selectedSession.host_name}</p><p className="mt-1 text-xs text-slate-400">{new Date(selectedSession.started_at).toLocaleString()} – {new Date(selectedSession.ended_at).toLocaleString()}</p><p className="mt-2 inline-flex items-center gap-2 rounded-lg bg-blue-50 px-3 py-2 text-sm font-black text-brand-700"><Clock3 size={16} /> Duration: {formatSessionDuration(selectedSession.started_at, selectedSession.ended_at)}</p></div>{selectedSession.can_manage ? <div className="grid grid-cols-3 gap-2 text-center"><HistoryCount label="Active" count={selectedSession.active_count} tone="active" /><HistoryCount label="Inactive" count={selectedSession.inactive_count} tone="inactive" /><HistoryCount label="Didn't join" count={selectedSession.not_joined_count} tone="not-joined" /></div> : myAttendance && <div className={`min-w-48 rounded-xl border p-4 ${historyAttendanceTone(myAttendance.attendance_status)}`}><p className="text-[10px] font-extrabold uppercase tracking-wider">My final status</p><p className="mt-2 inline-flex items-center gap-2 text-lg font-black"><i className={`discussion-call-attendance-dot discussion-call-status-${myAttendance.attendance_status === 'not_joined' ? 'not-joined' : myAttendance.attendance_status}`} />{historyAttendanceLabel(myAttendance.attendance_status)}</p></div>}</div>
            {selectedSession.can_manage ? <><div className="mt-4 flex flex-wrap items-center justify-between gap-2"><h4 className="font-black text-slate-900">Student attendance ({totalStudents})</h4><p className="text-xs text-slate-500">Recorded when the host ended the call</p></div><div className="mt-3 overflow-hidden rounded-xl border border-slate-200"><div className="overflow-x-auto"><table className="admin-table min-w-[720px]"><thead><tr><th>Student</th><th>Final status</th><th>Joined</th><th>Last activity</th></tr></thead><tbody>{selectedSession.attendance.map((student) => <tr key={student.student_id}><td data-label="Student"><div className="flex min-w-0 items-center gap-3"><ProfileAvatar name={student.full_name} avatarPath={student.avatar_path} className="size-9 text-[10px]" clickable={false} /><div className="min-w-0"><p className="truncate font-bold text-slate-900">{student.full_name}</p><p className="text-xs text-slate-500">{student.school_id}</p></div></div></td><td data-label="Final status"><span className="inline-flex items-center gap-2 font-bold"><i className={`discussion-call-attendance-dot discussion-call-status-${student.attendance_status === 'not_joined' ? 'not-joined' : student.attendance_status}`} />{historyAttendanceLabel(student.attendance_status)}</span></td><td data-label="Joined" className="whitespace-nowrap">{student.joined_at ? new Date(student.joined_at).toLocaleString() : '—'}</td><td data-label="Last activity" className="whitespace-nowrap">{student.last_seen_at ? new Date(student.last_seen_at).toLocaleString() : '—'}</td></tr>)}</tbody></table></div></div></> : myAttendance && <div className="mt-4 grid gap-3 rounded-xl border border-slate-200 bg-slate-50 p-4 sm:grid-cols-2"><div><p className="text-[10px] font-extrabold uppercase tracking-wider text-slate-500">Joined</p><p className="mt-1 text-sm font-bold text-slate-800">{myAttendance.joined_at ? new Date(myAttendance.joined_at).toLocaleString() : 'Did not join'}</p></div><div><p className="text-[10px] font-extrabold uppercase tracking-wider text-slate-500">Last recorded activity</p><p className="mt-1 text-sm font-bold text-slate-800">{myAttendance.last_seen_at ? new Date(myAttendance.last_seen_at).toLocaleString() : 'No activity recorded'}</p></div></div>}
            <div className="mt-6 flex flex-wrap items-center justify-between gap-2"><h4 className="inline-flex items-center gap-2 font-black text-slate-900"><MessageCircle size={18} /> Live interactions ({selectedSession.events.length})</h4><p className="text-xs text-slate-500">Comments and reactions saved during the call</p></div>
            {selectedSession.events.length === 0 ? <div className="mt-3 rounded-xl border border-dashed border-slate-300 bg-slate-50 p-5 text-center text-sm font-semibold text-slate-500">No comments or reactions were posted during this call.</div> : <div className="mt-3 max-h-[28rem] space-y-2 overflow-y-auto rounded-xl border border-slate-200 bg-slate-50 p-3">{selectedSession.events.map((event) => <article key={event.id} className="flex items-start gap-3 rounded-xl bg-white p-3 shadow-sm"><ProfileAvatar name={event.full_name} avatarPath={event.avatar_path} className="size-9 text-[10px]" clickable={false} /><div className="min-w-0 flex-1"><div className="flex flex-wrap items-baseline justify-between gap-x-3 gap-y-1"><strong className="text-sm text-slate-900">{event.full_name}</strong><time className="text-[11px] font-semibold text-slate-400" dateTime={event.created_at}>{new Date(event.created_at).toLocaleString()}</time></div>{event.event_type === 'reaction' ? <p className="mt-1 text-2xl" aria-label={`Reacted ${event.content}`}>{event.content}</p> : <>{event.content && <p className="mt-1 whitespace-pre-wrap break-words text-sm text-slate-700">{event.content}</p>}{event.attachment_path && <button type="button" className="mt-2 flex w-full min-w-0 items-center gap-3 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-left transition hover:border-blue-300 hover:bg-blue-50" onClick={() => setPreviewDocument({ bucket: 'discussions', path: event.attachment_path!, name: event.attachment_name ?? 'Attachment' })}><FileText className="shrink-0 text-brand-700" size={19} /><span className="min-w-0 flex-1"><b className="block truncate text-xs text-slate-800">{event.attachment_name ?? 'Attachment'}</b><small className="text-[10px] font-semibold text-slate-500">{event.attachment_kind === 'image' ? 'Image' : 'File'} · {formatFileSize(event.attachment_size ?? 0)}</small></span><Eye className="shrink-0 text-slate-500" size={17} /></button>}</>}</div></article>)}</div>}
          </div>}
        </div>}
      </div>
      <DocumentPreviewModal document={previewDocument} onClose={() => setPreviewDocument(null)} />
    </section>
  </div>
}

function HistoryCount({ label, count, tone }: { label: string; count: number; tone: 'active' | 'inactive' | 'not-joined' }) {
  return <div className="min-w-20 rounded-xl bg-slate-50 px-3 py-2"><span className="inline-flex items-center gap-1.5 text-[10px] font-extrabold uppercase tracking-wide text-slate-500"><i className={`discussion-call-attendance-dot discussion-call-status-${tone}`} />{label}</span><strong className="mt-1 block text-xl font-black text-slate-900">{count}</strong></div>
}

function historyAttendanceLabel(status: 'active' | 'inactive' | 'not_joined') {
  if (status === 'active') return 'Active'
  if (status === 'inactive') return 'Joined, inactive'
  return "Didn't join"
}

function historyAttendanceTone(status: 'active' | 'inactive' | 'not_joined') {
  if (status === 'active') return 'border-emerald-200 bg-emerald-50 text-emerald-800'
  if (status === 'inactive') return 'border-orange-200 bg-orange-50 text-orange-800'
  return 'border-red-200 bg-red-50 text-red-800'
}

function formatSessionDuration(startedAt: string, endedAt: string) {
  const totalSeconds = Math.max(0, Math.floor((new Date(endedAt).getTime() - new Date(startedAt).getTime()) / 1000))
  const hours = Math.floor(totalSeconds / 3600)
  const minutes = Math.floor((totalSeconds % 3600) / 60)
  const seconds = totalSeconds % 60
  if (hours > 0) return `${hours} hr ${minutes} min ${seconds} sec`
  if (minutes > 0) return `${minutes} min ${seconds} sec`
  return `${seconds} sec`
}

function PinnedMessagesDialog({ messages, currentUserUid, onSelect, onClose }: { messages: Post[]; currentUserUid?: string; onSelect: (postId: string) => void; onClose: () => void }) {
  useEffect(() => {
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') onClose() }
    window.addEventListener('keydown', closeOnEscape)
    return () => {
      document.body.style.overflow = previousOverflow
      window.removeEventListener('keydown', closeOnEscape)
    }
  }, [onClose])

  return <div className="modal-backdrop print-hidden" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
    <section className="modal-card flex max-h-[80dvh] max-w-2xl flex-col overflow-hidden p-0 sm:p-0" role="dialog" aria-modal="true" aria-labelledby="pinned-messages-title">
      <header className="flex items-center justify-between gap-3 border-b border-slate-200 px-4 py-4 sm:px-6"><div className="flex min-w-0 items-center gap-3"><div className="grid size-11 shrink-0 place-items-center rounded-full bg-amber-100 text-amber-700"><Pin size={21} fill="currentColor" /></div><div className="min-w-0"><p className="text-xs font-extrabold uppercase tracking-[0.14em] text-amber-700">Discussion</p><h2 id="pinned-messages-title" className="truncate text-lg font-black text-slate-900">View Pinned Messages</h2></div></div><button type="button" className="icon-action" onClick={onClose} aria-label="Close pinned messages"><X size={19} /></button></header>
      <div className="min-h-0 flex-1 overflow-y-auto p-3 sm:p-5">{messages.length === 0 ? <div className="grid min-h-52 place-items-center px-6 text-center"><div><Pin className="mx-auto text-slate-300" size={38} /><h3 className="mt-3 font-black text-slate-800">No pinned messages</h3><p className="mt-1 text-sm text-slate-500">Messages pinned by discussion participants will appear here.</p></div></div> : <div className="space-y-2">{messages.map((post) => {
        const author = post.author_id === currentUserUid ? 'You' : post.author?.full_name ?? 'Class member'
        const preview = post.body || post.attachment_name || 'Attachment'
        return <button type="button" className="discussion-pinned-message" key={post.id} onClick={() => onSelect(post.id)}><span className="discussion-pinned-message-icon"><Pin size={16} fill="currentColor" /></span><span className="min-w-0 flex-1 text-left"><span className="flex items-center justify-between gap-3"><strong className="truncate">{author}</strong><time>{new Date(post.pinned_at ?? post.created_at).toLocaleString()}</time></span><span className="mt-1 line-clamp-2 whitespace-pre-wrap break-words text-sm text-slate-600">{preview}</span>{post.attachment_name && <small><Paperclip size={12} /> {post.attachment_name}</small>}</span></button>
      })}</div>}</div>
    </section>
  </div>
}

function DiscussionRosterDialog({ classId, expectedCount, onClose }: { classId: string; expectedCount: number; onClose: () => void }) {
  useEffect(() => {
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') onClose() }
    window.addEventListener('keydown', closeOnEscape)
    return () => {
      document.body.style.overflow = previousOverflow
      window.removeEventListener('keydown', closeOnEscape)
    }
  }, [onClose])

  return <div className="modal-backdrop print-hidden" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}><section className="modal-card max-w-3xl p-0 sm:p-0" role="dialog" aria-modal="true" aria-labelledby="discussion-roster-title"><header className="flex items-center justify-between gap-3 border-b border-slate-200 px-4 py-4 sm:px-6"><div><p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">Class roster</p><h2 id="discussion-roster-title" className="mt-0.5 text-lg font-black text-slate-900">View Enrolled Students</h2></div><button type="button" className="icon-action" onClick={onClose} aria-label="Close enrolled students"><X size={19} /></button></header><div className="p-3 sm:p-5"><EnrolledStudentsPanel classId={classId} expectedCount={expectedCount} fullWidth /></div></section></div>
}

function CameraCaptureDialog({ onClose, onCapture }: { onClose: () => void; onCapture: (file: File) => void }) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const mountedRef = useRef(true)
  const onCloseRef = useRef(onClose)
  const [devices, setDevices] = useState<MediaDeviceInfo[]>([])
  const [activeDeviceId, setActiveDeviceId] = useState('')
  const [starting, setStarting] = useState(true)
  const [capturing, setCapturing] = useState(false)
  const [cameraError, setCameraError] = useState<string | null>(null)

  const stopCamera = useCallback(() => {
    streamRef.current?.getTracks().forEach((track) => track.stop())
    streamRef.current = null
    if (videoRef.current) videoRef.current.srcObject = null
  }, [])

  const startCamera = useCallback(async (deviceId?: string) => {
    if (!navigator.mediaDevices?.getUserMedia) {
      setCameraError('Camera access is not supported by this browser.')
      setStarting(false)
      return
    }
    setStarting(true)
    setCameraError(null)
    stopCamera()
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: deviceId ? { deviceId: { exact: deviceId } } : { facingMode: { ideal: 'environment' } },
      })
      if (!mountedRef.current) {
        stream.getTracks().forEach((track) => track.stop())
        return
      }
      streamRef.current = stream
      const video = videoRef.current
      if (video) {
        video.srcObject = stream
        await video.play()
      }
      const cameraDevices = (await navigator.mediaDevices.enumerateDevices()).filter((device) => device.kind === 'videoinput')
      const currentDeviceId = stream.getVideoTracks()[0]?.getSettings().deviceId ?? deviceId ?? ''
      if (mountedRef.current) {
        setDevices(cameraDevices)
        setActiveDeviceId(currentDeviceId)
        setStarting(false)
      }
    } catch (caught) {
      if (!mountedRef.current) return
      const denied = caught instanceof DOMException && (caught.name === 'NotAllowedError' || caught.name === 'SecurityError')
      const unavailable = caught instanceof DOMException && (caught.name === 'NotFoundError' || caught.name === 'DevicesNotFoundError')
      setCameraError(denied ? 'Camera permission was denied. Allow camera access in your browser settings.' : unavailable ? 'No camera was found on this device.' : 'Unable to open the camera. Camera access requires HTTPS or localhost and an available webcam.')
      setStarting(false)
    }
  }, [stopCamera])

  useEffect(() => {
    onCloseRef.current = onClose
  }, [onClose])

  useEffect(() => {
    mountedRef.current = true
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    queueMicrotask(() => { if (mountedRef.current) void startCamera() })
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') onCloseRef.current() }
    window.addEventListener('keydown', closeOnEscape)
    return () => {
      mountedRef.current = false
      document.body.style.overflow = previousOverflow
      window.removeEventListener('keydown', closeOnEscape)
      stopCamera()
    }
  }, [startCamera, stopCamera])

  const switchCamera = () => {
    if (devices.length < 2) return
    const currentIndex = devices.findIndex((device) => device.deviceId === activeDeviceId)
    const nextDevice = devices[(currentIndex + 1 + devices.length) % devices.length]
    void startCamera(nextDevice.deviceId)
  }

  const capturePhoto = async () => {
    const video = videoRef.current
    if (!video || video.videoWidth === 0 || video.videoHeight === 0) return setCameraError('The camera is still preparing. Try again in a moment.')
    setCapturing(true)
    const canvas = document.createElement('canvas')
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    const context = canvas.getContext('2d')
    if (!context) {
      setCapturing(false)
      return setCameraError('Unable to capture the camera image.')
    }
    context.drawImage(video, 0, 0, canvas.width, canvas.height)
    const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, 'image/jpeg', 0.9))
    setCapturing(false)
    if (!blob) return setCameraError('Unable to create the captured image.')
    if (blob.size > MAX_ATTACHMENT_BYTES) return setCameraError('The captured photo is larger than 10 MB. Try a lower-resolution camera.')
    const file = new File([blob], `camera-photo-${new Date().toISOString().replace(/[:.]/g, '-')}.jpg`, { type: 'image/jpeg' })
    stopCamera()
    onCapture(file)
  }

  return <div className="modal-backdrop print-hidden" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
    <section className="modal-card flex max-w-3xl flex-col overflow-hidden p-0 sm:p-0" role="dialog" aria-modal="true" aria-labelledby="camera-capture-title">
      <header className="flex items-center justify-between gap-3 border-b border-slate-200 px-4 py-3 sm:px-5"><div><p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">Discussion camera</p><h2 id="camera-capture-title" className="text-lg font-black text-slate-900">Take a photo</h2></div><button type="button" className="icon-action" onClick={onClose} aria-label="Close camera"><X size={19} /></button></header>
      <div className="relative grid min-h-72 place-items-center overflow-hidden bg-black sm:min-h-[440px]">
        <video ref={videoRef} className="max-h-[70vh] w-full object-contain" autoPlay muted playsInline aria-label="Live camera preview" />
        {starting && !cameraError && <div className="absolute inset-0 grid place-items-center bg-black/70 text-sm font-bold text-white">Opening camera…</div>}
        {cameraError && <div className="absolute inset-0 grid place-items-center bg-slate-950 p-6 text-center text-sm font-semibold leading-6 text-white"><div><Camera className="mx-auto mb-3 text-slate-400" size={42} /><p>{cameraError}</p><button type="button" className="button-secondary mt-5" onClick={() => void startCamera()}>Try again</button></div></div>}
      </div>
      <footer className="flex flex-col-reverse gap-2 border-t border-slate-200 bg-white px-4 py-3 sm:flex-row sm:items-center sm:justify-between sm:px-5">
        <div>{devices.length > 1 && <button type="button" className="button-secondary w-full sm:w-auto" onClick={switchCamera} disabled={starting || capturing}><SwitchCamera size={18} /> Switch camera</button>}</div>
        <div className="flex gap-2"><button type="button" className="button-secondary flex-1 sm:flex-none" onClick={onClose}>Cancel</button><button type="button" className="button-primary flex-1 sm:flex-none" onClick={() => void capturePhoto()} disabled={starting || capturing || Boolean(cameraError)}><Camera size={18} /> {capturing ? 'Capturing…' : 'Capture photo'}</button></div>
      </footer>
    </section>
  </div>
}

function DiscussionAttachment({ post, isOwnMessage, onPreview }: { post: Post; isOwnMessage: boolean; onPreview: () => void }) {
  const [previewUrl, setPreviewUrl] = useState('')
  const [downloadUrl, setDownloadUrl] = useState('')
  const kind = post.attachment_kind

  useEffect(() => {
    if (!post.attachment_path) return
    let active = true
    void Promise.all([
      kind !== 'file' ? supabase.storage.from('discussions').createSignedUrl(post.attachment_path, 300, 'preview') : Promise.resolve(null),
      supabase.storage.from('discussions').createSignedUrl(post.attachment_path, 300, 'download'),
    ]).then(([previewResult, downloadResult]) => {
      if (!active) return
      if (previewResult?.error || downloadResult.error) return
      setPreviewUrl(previewResult?.data.signedUrl ?? '')
      setDownloadUrl(downloadResult.data.signedUrl)
    })
    return () => { active = false }
  }, [kind, post.attachment_path])

  const name = post.attachment_name ?? 'Attachment'
  const labelColor = isOwnMessage ? 'text-blue-50' : 'text-slate-700'
  return <div className="discussion-message-attachment">
    {kind === 'image' && previewUrl && <button type="button" className="discussion-message-image" onClick={onPreview} aria-label={`Preview ${name}`}><img src={previewUrl} alt={name} loading="lazy" /></button>}
    {kind === 'video' && previewUrl && <video className="discussion-message-video" src={previewUrl} controls preload="metadata">Your browser does not support video playback.</video>}
    {kind === 'audio' && <div className={`discussion-message-audio ${isOwnMessage ? 'discussion-message-audio-own' : ''}`}><AudioLines size={22} /><div className="min-w-0 flex-1"><strong>Voice message</strong>{previewUrl ? <audio src={previewUrl} controls preload="metadata">Your browser does not support audio playback.</audio> : <span>Preparing audio…</span>}</div></div>}
    {(kind === 'file' || (kind !== 'audio' && !previewUrl)) && <button type="button" className={`discussion-message-file ${isOwnMessage ? 'discussion-message-file-own' : ''}`} onClick={onPreview}><span>{attachmentIcon(kind ?? 'file', 22)}</span><span className="min-w-0 flex-1"><strong className={labelColor}>{name}</strong><small>{attachmentKindLabel(kind ?? 'file')} · {formatFileSize(post.attachment_size ?? 0)}</small></span></button>}
    <div className="discussion-message-attachment-footer"><span className="min-w-0 truncate">{name}</span><div className="discussion-message-attachment-actions"><button type="button" onClick={onPreview} aria-label={`Preview ${name}`} title="Preview attachment"><Eye size={15} /></button>{downloadUrl && <a href={downloadUrl} aria-label={`Download ${name}`} title="Download attachment"><Download size={15} /></a>}</div></div>
  </div>
}

function attachmentKind(file: File): NonNullable<Post['attachment_kind']> {
  if (file.type.startsWith('image/')) return 'image'
  if (file.type.startsWith('video/')) return 'video'
  if (file.type.startsWith('audio/')) return 'audio'
  return 'file'
}

function attachmentKindLabel(kind: NonNullable<Post['attachment_kind']>) {
  return kind === 'image' ? 'Image' : kind === 'video' ? 'Video' : kind === 'audio' ? 'Audio recording' : 'File'
}

function attachmentIcon(kind: NonNullable<Post['attachment_kind']>, size: number) {
  if (kind === 'image') return <ImagePlus size={size} />
  if (kind === 'video') return <Video size={size} />
  if (kind === 'audio') return <AudioLines size={size} />
  return <FileText size={size} />
}

function formatFileSize(bytes: number) {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

function formatRecordingTime(seconds: number) {
  const minutes = Math.floor(seconds / 60).toString().padStart(2, '0')
  const remaining = (seconds % 60).toString().padStart(2, '0')
  return `${minutes}:${remaining}`
}

function normalizeTopic(value: unknown): Topic {
  const item = value as Topic & { author: Topic['author'] | Topic['author'][] }
  return { ...item, author: Array.isArray(item.author) ? item.author[0] ?? null : item.author, is_joined: Boolean(item.is_joined), muted_until: item.muted_until ?? null }
}

function normalizePost(value: unknown): Post {
  const item = value as Post & { author: Post['author'] | Post['author'][] }
  return {
    ...item,
    author: Array.isArray(item.author) ? item.author[0] ?? null : item.author,
    reactions: Array.isArray(item.reactions) ? item.reactions.map((reaction) => ({ ...reaction, users: Array.isArray(reaction.users) ? reaction.users : [] })) : [],
  }
}