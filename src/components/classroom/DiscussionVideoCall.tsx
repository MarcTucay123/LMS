import { useCallback, useEffect, useRef, useState, type FormEvent } from 'react'
import { createPortal } from 'react-dom'
import { Camera, CameraOff, Clock3, Eye, FileText, ImagePlus, Maximize2, MessageCircle, Mic, MicOff, Minimize2, MonitorUp, Paperclip, PhoneOff, Send, Users, Video, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import type { DiscussionLiveEvent, DiscussionLiveParticipant, DiscussionLiveState, Json } from '../../types/database'
import { ProfileAvatar } from '../ProfileAvatar'
import { DocumentPreviewModal, type PreviewDocument } from './DocumentPreviewModal'
import { safeFileName } from './workspace'

const CALL_REFRESH_MS = 1000
const MAX_LIVE_ATTACHMENT_BYTES = 10 * 1024 * 1024
const CALL_REACTIONS = ['👍', '❤️', '😂', '👏', '🎉', '😮']
const RTC_CONFIG: RTCConfiguration = { iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] }

export type DiscussionVideoCallShutdown = () => Promise<void>

export function DiscussionVideoCall({ topicId, topicTitle, canStart, currentUserId, joinImmediately = false, restoreSignal = 0, onJoinedChange, onShutdownReady, onClose }: { topicId: string; topicTitle: string; canStart: boolean; currentUserId: string; joinImmediately?: boolean; restoreSignal?: number; onJoinedChange?: (joined: boolean) => void; onShutdownReady?: (shutdown: DiscussionVideoCallShutdown | null) => void; onClose: () => void }) {
  const [state, setState] = useState<DiscussionLiveState | null>(null)
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [micMuted, setMicMuted] = useState(true)
  const [cameraEnabled, setCameraEnabled] = useState(false)
  const [screenSharing, setScreenSharing] = useState(false)
  const [screenSharePending, setScreenSharePending] = useState(false)
  const [comment, setComment] = useState('')
  const [attachment, setAttachment] = useState<File | null>(null)
  const [postingComment, setPostingComment] = useState(false)
  const [previewDocument, setPreviewDocument] = useState<PreviewDocument | null>(null)
  const [minimized, setMinimized] = useState(false)
  const [expandedPresenterId, setExpandedPresenterId] = useState<string | null>(null)
  const [tabVisible, setTabVisible] = useState(() => document.visibilityState === 'visible')
  const [windowFocused, setWindowFocused] = useState(() => document.hasFocus())
  const [localStream, setLocalStream] = useState<MediaStream | null>(null)
  const [screenStream, setScreenStream] = useState<MediaStream | null>(null)
  const [remoteStreams, setRemoteStreams] = useState<Record<string, MediaStream>>({})
  const [currentTimeMs, setCurrentTimeMs] = useState(() => Date.now())
  const localStreamRef = useRef<MediaStream | null>(null)
  const screenStreamRef = useRef<MediaStream | null>(null)
  const peersRef = useRef(new Map<string, RTCPeerConnection>())
  const lastSignalIdRef = useRef(0)
  const stateRef = useRef<DiscussionLiveState | null>(null)
  const closingRef = useRef(false)
  const automaticJoinAttemptedRef = useRef(false)
  const photoInputRef = useRef<HTMLInputElement>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const lastCallActivityAtRef = useRef(0)

  useEffect(() => {
    if (!state?.session?.started_at) return
    const timer = window.setInterval(() => setCurrentTimeMs(Date.now()), 1000)
    return () => window.clearInterval(timer)
  }, [state?.session?.started_at])

  const markCallActivity = useCallback(() => {
    if (!minimized && document.visibilityState === 'visible' && document.hasFocus()) lastCallActivityAtRef.current = Date.now()
  }, [minimized])

  const restoreCall = useCallback(() => {
    lastCallActivityAtRef.current = Date.now()
    setMinimized(false)
  }, [])

  const sendSignal = useCallback(async (recipientId: string, signalType: 'offer' | 'answer' | 'ice', payload: Json) => {
    const sessionId = stateRef.current?.session?.id
    if (!sessionId) return
    const { error: signalError } = await supabase.rpc('send_discussion_live_signal', { target_session_id: sessionId, recipient_id: recipientId, signal_type: signalType, payload })
    if (signalError && !closingRef.current) setError(signalError.message)
  }, [])

  const closePeer = useCallback((userId: string) => {
    peersRef.current.get(userId)?.close()
    peersRef.current.delete(userId)
    setRemoteStreams((streams) => { const next = { ...streams }; delete next[userId]; return next })
  }, [])

  const createPeer = useCallback((remoteUserId: string) => {
    const existing = peersRef.current.get(remoteUserId)
    if (existing) return existing
    const peer = new RTCPeerConnection(RTC_CONFIG)
    peersRef.current.set(remoteUserId, peer)
    const mediaStream = localStreamRef.current
    mediaStream?.getAudioTracks().forEach((track) => peer.addTrack(track, mediaStream))
    const outgoingVideoTrack = screenStreamRef.current?.getVideoTracks()[0] ?? mediaStream?.getVideoTracks()[0]
    if (outgoingVideoTrack) peer.addTrack(outgoingVideoTrack, screenStreamRef.current ?? mediaStream!)
    else peer.addTransceiver('video', { direction: 'sendrecv' })
    peer.onicecandidate = (event) => { if (event.candidate) void sendSignal(remoteUserId, 'ice', event.candidate.toJSON() as unknown as Json) }
    peer.ontrack = (event) => setRemoteStreams((streams) => ({ ...streams, [remoteUserId]: event.streams[0] ?? new MediaStream([event.track]) }))
    peer.onconnectionstatechange = () => { if (['failed', 'closed'].includes(peer.connectionState)) closePeer(remoteUserId) }
    return peer
  }, [closePeer, sendSignal])

  const createOffer = useCallback(async (remoteUserId: string) => {
    const peer = createPeer(remoteUserId)
    if (peer.signalingState !== 'stable') return
    const offer = await peer.createOffer()
    await peer.setLocalDescription(offer)
    await sendSignal(remoteUserId, 'offer', offer as unknown as Json)
  }, [createPeer, sendSignal])

  const processSignals = useCallback(async (nextState: DiscussionLiveState) => {
    for (const signal of nextState.signals) {
      lastSignalIdRef.current = Math.max(lastSignalIdRef.current, signal.id)
      const peer = createPeer(signal.sender_id)
      try {
        if (signal.signal_type === 'offer') {
          await peer.setRemoteDescription(signal.payload as unknown as RTCSessionDescriptionInit)
          const answer = await peer.createAnswer()
          await peer.setLocalDescription(answer)
          await sendSignal(signal.sender_id, 'answer', answer as unknown as Json)
        } else if (signal.signal_type === 'answer') {
          if (peer.signalingState === 'have-local-offer') await peer.setRemoteDescription(signal.payload as unknown as RTCSessionDescriptionInit)
        } else if (signal.signal_type === 'ice' && signal.payload) {
          await peer.addIceCandidate(signal.payload as unknown as RTCIceCandidateInit)
        }
      } catch {
        closePeer(signal.sender_id)
      }
    }
  }, [closePeer, createPeer, sendSignal])

  const syncPeers = useCallback(async (nextState: DiscussionLiveState) => {
    const activeIds = new Set(nextState.participants.map((participant) => participant.user_id))
    for (const remoteId of peersRef.current.keys()) if (!activeIds.has(remoteId)) closePeer(remoteId)
    if (!nextState.joined) return
    for (const participant of nextState.participants) {
      if (participant.user_id !== currentUserId && currentUserId.localeCompare(participant.user_id) < 0 && !peersRef.current.has(participant.user_id)) {
        await createOffer(participant.user_id)
      }
    }
  }, [closePeer, createOffer, currentUserId])

  const applyState = useCallback(async (nextState: DiscussionLiveState) => {
    stateRef.current = nextState
    setState(nextState)
    setExpandedPresenterId((currentPresenterId) => {
      if (!currentPresenterId || currentPresenterId === currentUserId) return currentPresenterId
      return nextState.participants.some((participant) => participant.user_id === currentPresenterId && participant.screen_sharing) ? currentPresenterId : null
    })
    await processSignals(nextState)
    await syncPeers(nextState)
  }, [currentUserId, processSignals, syncPeers])

  const prepareMedia = useCallback(async () => {
    if (localStreamRef.current) return
    if (!navigator.mediaDevices?.getUserMedia) throw new Error('Video calls are not supported by this browser.')
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true, video: true })
      stream.getAudioTracks().forEach((track) => { track.enabled = false })
      stream.getVideoTracks().forEach((track) => { track.enabled = false })
      localStreamRef.current = stream
      setLocalStream(stream)
    } catch {
      const stream = new MediaStream()
      localStreamRef.current = stream
      setLocalStream(stream)
      setError('Camera or microphone permission was denied. You can still join, comment, react, and receive the call.')
    }
  }, [])

  const loadState = useCallback(async (showLoading = false) => {
    if (showLoading) setLoading(true)
    const result = await supabase.rpc('discussion_live_state', { target_topic_id: topicId, after_signal_id: lastSignalIdRef.current })
    const { data, error: stateError } = result
    if (stateError) setError(stateError.message)
    else {
      if (data.joined) await prepareMedia()
      await applyState(data)
    }
    if (showLoading) setLoading(false)
  }, [applyState, prepareMedia, topicId])

  useEffect(() => {
    const initial = window.setTimeout(() => void loadState(true), 0)
    const timer = window.setInterval(() => { if (!stateRef.current?.joined) void loadState() }, CALL_REFRESH_MS)
    return () => { window.clearTimeout(initial); window.clearInterval(timer) }
  }, [loadState])

  useEffect(() => {
    if (minimized) return
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => { document.body.style.overflow = previousOverflow }
  }, [minimized])

  useEffect(() => {
    if (restoreSignal <= 0) return
    queueMicrotask(restoreCall)
  }, [restoreCall, restoreSignal])

  useEffect(() => {
    onJoinedChange?.(Boolean(state?.joined))
  }, [onJoinedChange, state?.joined])

  useEffect(() => {
    const updateVisibility = () => {
      setTabVisible(document.visibilityState === 'visible')
      setWindowFocused(document.hasFocus())
    }
    document.addEventListener('visibilitychange', updateVisibility)
    window.addEventListener('focus', updateVisibility)
    window.addEventListener('blur', updateVisibility)
    return () => {
      document.removeEventListener('visibilitychange', updateVisibility)
      window.removeEventListener('focus', updateVisibility)
      window.removeEventListener('blur', updateVisibility)
    }
  }, [])

  useEffect(() => {
    const sessionId = state?.session?.id
    if (!sessionId || !state.joined) return
    let running = false
    const heartbeat = async () => {
      if (running) return
      running = true
      const attendanceSettings = stateRef.current?.attendance_settings
      const inactivityMs = (attendanceSettings?.live_attendance_inactivity_seconds ?? 30) * 1000
      const isAttending =
        (!attendanceSettings?.live_attendance_minimized_enabled || !minimized) &&
        (!attendanceSettings?.live_attendance_tab_hidden_enabled || tabVisible) &&
        (!attendanceSettings?.live_attendance_window_blur_enabled || windowFocused) &&
        (!attendanceSettings?.live_attendance_inactivity_enabled || Date.now() - lastCallActivityAtRef.current < inactivityMs)
      const { data, error: presenceError } = await supabase.rpc('update_discussion_live_presence', { target_session_id: sessionId, mic_muted: micMuted, camera_enabled: cameraEnabled, screen_sharing: screenSharing, is_attending: isAttending, after_signal_id: lastSignalIdRef.current })
      running = false
      if (presenceError) {
        if (/call has ended/i.test(presenceError.message)) {
          closingRef.current = true
          onClose()
        } else setError(presenceError.message)
      } else await applyState(data)
    }
    void heartbeat()
    const timer = window.setInterval(() => void heartbeat(), CALL_REFRESH_MS)
    return () => window.clearInterval(timer)
  }, [applyState, cameraEnabled, micMuted, minimized, onClose, screenSharing, state?.joined, state?.session?.id, tabVisible, windowFocused])

  useEffect(() => () => {
    const sessionId = stateRef.current?.session?.id
    const shouldLeaveSession = !closingRef.current && Boolean(sessionId && stateRef.current?.joined)
    closingRef.current = true
    for (const peer of peersRef.current.values()) peer.close()
    peersRef.current.clear()
    screenStreamRef.current?.getTracks().forEach((track) => track.stop())
    localStreamRef.current?.getTracks().forEach((track) => track.stop())
    if (shouldLeaveSession && sessionId) void supabase.rpc('leave_discussion_live_session', { target_session_id: sessionId })
  }, [])

  const enterCall = useCallback(async (start: boolean) => {
    setBusy(true); setError(null)
    try {
      await prepareMedia()
      const result = start
        ? await supabase.rpc('start_discussion_live_session', { target_topic_id: topicId })
        : await supabase.rpc('join_discussion_live_session', { target_session_id: stateRef.current!.session!.id })
      if (result.error) return setError(result.error.message)
      lastCallActivityAtRef.current = Date.now()
      await applyState(result.data)
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Unable to enter the video call.')
    } finally {
      setBusy(false)
    }
  }, [applyState, prepareMedia, topicId])

  useEffect(() => {
    if (!joinImmediately || automaticJoinAttemptedRef.current || loading || busy || !state?.session || state.joined) return
    automaticJoinAttemptedRef.current = true
    void enterCall(false)
  }, [busy, enterCall, joinImmediately, loading, state?.joined, state?.session])

  useEffect(() => {
    if (!expandedPresenterId) return
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') setExpandedPresenterId(null) }
    window.addEventListener('keydown', closeOnEscape)
    return () => window.removeEventListener('keydown', closeOnEscape)
  }, [expandedPresenterId])

  const toggleMicrophone = () => {
    const nextMuted = !micMuted
    localStreamRef.current?.getAudioTracks().forEach((track) => { track.enabled = !nextMuted })
    setMicMuted(nextMuted)
  }

  const toggleCamera = () => {
    const nextEnabled = !cameraEnabled
    localStreamRef.current?.getVideoTracks().forEach((track) => { track.enabled = nextEnabled })
    setCameraEnabled(nextEnabled)
  }

  const replaceOutgoingVideo = useCallback(async (track: MediaStreamTrack | null, sourceStream?: MediaStream) => {
    for (const [userId, peer] of peersRef.current.entries()) {
      let sender = peer.getSenders().find((candidate) => candidate.track?.kind === 'video')
      if (!sender) sender = peer.getTransceivers().find((transceiver) => transceiver.receiver.track.kind === 'video')?.sender
      if (sender) await sender.replaceTrack(track)
      else if (track && sourceStream) {
        peer.addTrack(track, sourceStream)
        await createOffer(userId)
      }
    }
  }, [createOffer])

  const stopScreenShare = useCallback(async () => {
    const screenStream = screenStreamRef.current
    if (!screenStream) return
    screenStreamRef.current = null
    setScreenStream(null)
    screenStream.getTracks().forEach((track) => { track.onended = null; track.stop() })
    const cameraTrack = localStreamRef.current?.getVideoTracks()[0] ?? null
    if (cameraTrack) cameraTrack.enabled = cameraEnabled
    await replaceOutgoingVideo(cameraTrack, localStreamRef.current ?? undefined)
    setScreenSharing(false)
    setExpandedPresenterId((currentPresenterId) => currentPresenterId === currentUserId ? null : currentPresenterId)
  }, [cameraEnabled, currentUserId, replaceOutgoingVideo])

  const startScreenShare = async () => {
    if (!navigator.mediaDevices?.getDisplayMedia) return setError('Screen sharing is not supported by this browser.')
    setError(null)
    setScreenSharePending(true)
    try {
      const stream = await navigator.mediaDevices.getDisplayMedia({ video: true, audio: false })
      const screenTrack = stream.getVideoTracks()[0]
      if (!screenTrack) { stream.getTracks().forEach((track) => track.stop()); return }
      screenStreamRef.current?.getTracks().forEach((track) => track.stop())
      screenStreamRef.current = stream
      setScreenStream(stream)
      screenTrack.onended = () => { void stopScreenShare() }
      await replaceOutgoingVideo(screenTrack, stream)
      setScreenSharing(true)
    } catch (caught) {
      const failedStream = screenStreamRef.current
      screenStreamRef.current = null
      setScreenStream(null)
      failedStream?.getTracks().forEach((track) => { track.onended = null; track.stop() })
      setScreenSharing(false)
      if (caught instanceof DOMException && caught.name === 'NotAllowedError') return
      setError(caught instanceof Error ? caught.message : 'Unable to share your screen.')
    } finally {
      setScreenSharePending(false)
    }
  }

  const leaveCall = async () => {
    const sessionId = stateRef.current?.session?.id
    if (sessionId && stateRef.current?.joined) await supabase.rpc('leave_discussion_live_session', { target_session_id: sessionId })
    closingRef.current = true
    onClose()
  }

  const endCall = async () => {
    const sessionId = stateRef.current?.session?.id
    if (!sessionId) return
    setBusy(true)
    const { error: endError } = await supabase.rpc('end_discussion_live_session', { target_session_id: sessionId })
    setBusy(false)
    if (endError) return setError(endError.message)
    closingRef.current = true
    onClose()
  }

  const shutdownForLogout = useCallback(async () => {
    const currentState = stateRef.current
    const sessionId = currentState?.session?.id
    closingRef.current = true
    if (sessionId) {
      if (currentState?.is_host) await supabase.rpc('end_discussion_live_session', { target_session_id: sessionId })
      else if (currentState?.joined) await supabase.rpc('leave_discussion_live_session', { target_session_id: sessionId })
    }
    onClose()
  }, [onClose])

  useEffect(() => {
    onShutdownReady?.(shutdownForLogout)
    return () => onShutdownReady?.(null)
  }, [onShutdownReady, shutdownForLogout])

  const postEvent = async (eventType: 'comment' | 'reaction', content: string) => {
    const sessionId = stateRef.current?.session?.id
    if (!sessionId || !content.trim()) return
    const { error: postError } = await supabase.rpc('post_discussion_live_event', { target_session_id: sessionId, event_type: eventType, content: content.trim() })
    if (postError) setError(postError.message); else { setComment(''); await loadState() }
  }

  const selectAttachment = (file: File | null, imageOnly = false) => {
    if (!file) return
    if (file.size > MAX_LIVE_ATTACHMENT_BYTES) return setError('Live-comment attachments must be 10 MB or smaller.')
    if (imageOnly && !file.type.startsWith('image/')) return setError('Choose an image file for the photo attachment.')
    setError(null)
    setAttachment(file)
  }

  const submitComment = async (event: FormEvent) => {
    event.preventDefault()
    const session = stateRef.current?.session
    if (!session || (!comment.trim() && !attachment) || postingComment) return
    setPostingComment(true)
    setError(null)
    let attachmentPath = ''
    try {
      if (attachment) {
        attachmentPath = `${session.class_id}/${topicId}/${currentUserId}/${crypto.randomUUID()}-${safeFileName(attachment.name)}`
        const { error: uploadError } = await supabase.storage.from('discussions').upload(attachmentPath, attachment)
        if (uploadError) throw uploadError
      }
      const { error: postError } = await supabase.rpc('post_discussion_live_event', {
        target_session_id: session.id,
        event_type: 'comment',
        content: comment.trim(),
        attachment_path: attachmentPath,
        attachment_name: attachment?.name ?? '',
        attachment_mime: attachment?.type ?? '',
        attachment_size: attachment?.size ?? 0,
        attachment_kind: attachment?.type.startsWith('image/') ? 'image' : 'file',
      })
      if (postError) throw postError
      setComment('')
      setAttachment(null)
      await loadState()
    } catch (caught) {
      if (attachmentPath) await supabase.storage.from('discussions').remove([attachmentPath])
      setError(caught instanceof Error ? caught.message : 'Unable to post the live comment.')
    } finally {
      setPostingComment(false)
    }
  }
  const remoteParticipants = state?.participants.filter((participant) => participant.user_id !== currentUserId) ?? []
  const presentingParticipants = state?.participants.filter((participant) => participant.screen_sharing) ?? []
  const activeAttendanceCount = state?.attendance_roster.filter((participant) => participant.attendance_status === 'active').length ?? 0
  const expandedParticipant = expandedPresenterId ? state?.participants.find((participant) => participant.user_id === expandedPresenterId) : undefined
  const expandedStream = expandedPresenterId === currentUserId ? screenStream : expandedPresenterId ? remoteStreams[expandedPresenterId] : null
  const expandedPresenterName = expandedPresenterId === currentUserId ? 'You' : expandedParticipant?.full_name ?? 'Presenter'
  const elapsedSeconds = state?.session?.started_at ? Math.max(0, Math.floor((currentTimeMs - new Date(state.session.started_at).getTime()) / 1000)) : 0

  const closeCall = () => void (state?.is_host ? endCall() : leaveCall())
  const callUi = minimized ? <aside className="discussion-call-minimized" role="dialog" aria-label={`Minimized video call for ${topicTitle}`}>
    <button type="button" className="discussion-call-minimized-main" onClick={restoreCall} aria-label="Restore video call">
      <span className="discussion-call-minimized-icon"><Video size={19} /></span>
      <span><small>Discussion live call · {formatCallDuration(elapsedSeconds)}</small><strong>{topicTitle}</strong></span>
    </button>
    <button type="button" className="discussion-call-minimized-action" onClick={restoreCall} aria-label="Restore video call" title="Restore"><Maximize2 size={18} /></button>
    <button type="button" className="discussion-call-minimized-action discussion-call-minimized-close" onClick={closeCall} aria-label={state?.is_host ? 'End video call' : 'Leave video call'} title={state?.is_host ? 'End call' : 'Leave call'}><X size={19} /></button>
  </aside> : <div className="discussion-call-backdrop" role="presentation">
    <section className="discussion-call-modal" role="dialog" aria-modal="true" aria-label={`Video call for ${topicTitle}`} onPointerMove={markCallActivity} onPointerDown={markCallActivity} onKeyDown={markCallActivity} onWheel={markCallActivity}>
      <header className="discussion-call-header"><div><p><Video size={16} /> Discussion live call</p><h2>{topicTitle}</h2></div>{state?.session && <div className="discussion-call-duration" aria-label={`Call duration ${formatCallDuration(elapsedSeconds)}`}><Clock3 size={17} /><span>Duration</span><strong>{formatCallDuration(elapsedSeconds)}</strong></div>}<div className="discussion-call-header-actions"><button type="button" onClick={() => { setExpandedPresenterId(null); setMinimized(true) }} aria-label="Minimize video call" title="Minimize"><Minimize2 size={21} /></button><button type="button" onClick={closeCall} aria-label={state?.is_host ? 'End and close video call' : 'Leave and close video call'} title={state?.is_host ? 'End call' : 'Leave call'}><X size={21} /></button></div></header>
      {error && <div className="mx-4 mt-3 rounded-xl border border-red-300 bg-red-50 p-3 text-sm font-semibold text-red-800">{error}</div>}
      {loading ? <div className="grid flex-1 place-items-center text-sm text-slate-400">Checking live call…</div> : !state?.session ? <div className="grid flex-1 place-items-center p-6 text-center"><div><Video className="mx-auto text-brand-700" size={44} /><h3 className="mt-4 text-xl font-black text-slate-900">No active call</h3><p className="mt-2 text-sm text-slate-500">Any member who joined this discussion can start its call.</p>{canStart && <button className="button-primary mt-5" disabled={busy} onClick={() => void enterCall(true)}><Video size={17} /> {busy ? 'Starting…' : 'Start video call'}</button>}</div></div> : !state.joined ? <div className="grid flex-1 place-items-center p-6 text-center"><div><Users className="mx-auto text-brand-700" size={44} /><h3 className="mt-4 text-xl font-black text-slate-900">Live call in progress</h3><p className="mt-2 text-sm text-slate-500">Enter with your camera off and microphone muted.</p><button className="button-primary mt-5" disabled={busy} onClick={() => void enterCall(false)}><Video size={17} /> {busy ? 'Joining…' : 'Join call'}</button></div></div> : <div className="discussion-call-body">
        <main className="discussion-call-stage">
          {presentingParticipants.length > 0 && <div className="discussion-call-presentation-actions" aria-label="Active presentations">
            <span><MonitorUp size={17} /> {presentingParticipants.length === 1 ? 'A screen is being presented' : `${presentingParticipants.length} screens are being presented`}</span>
            {presentingParticipants.map((participant) => <button type="button" key={participant.user_id} onClick={() => setExpandedPresenterId(participant.user_id)}><Maximize2 size={16} /> View {participant.user_id === currentUserId ? 'your presentation' : `${participant.full_name}'s screen`}</button>)}
          </div>}
          <div className="discussion-call-grid">
            <VideoTile participant={state.participants.find((participant) => participant.user_id === currentUserId)} stream={screenStream ?? localStream} muted label="You" screenSharing={screenSharing} onExpand={() => setExpandedPresenterId(currentUserId)} />
            {remoteParticipants.map((participant) => <VideoTile key={participant.user_id} participant={participant} stream={remoteStreams[participant.user_id]} onExpand={() => setExpandedPresenterId(participant.user_id)} />)}
          </div>
          <div className="discussion-call-controls">
            <button type="button" className={micMuted ? 'discussion-call-control-off' : ''} onClick={toggleMicrophone}>{micMuted ? <MicOff /> : <Mic />}<span>{micMuted ? 'Unmute' : 'Mute'}</span></button>
            <button type="button" className={!cameraEnabled ? 'discussion-call-control-off' : ''} onClick={toggleCamera}>{cameraEnabled ? <Camera /> : <CameraOff />}<span>{cameraEnabled ? 'Camera off' : 'Camera on'}</span></button>
            <button type="button" className={screenSharing ? 'discussion-call-control-presenting' : ''} disabled={screenSharePending} onClick={() => void (screenSharing ? stopScreenShare() : startScreenShare())}><MonitorUp /><span>{screenSharePending ? 'Choose screen…' : screenSharing ? 'Stop presenting' : 'Share screen'}</span></button>
            {state.is_host ? <button type="button" className="discussion-call-control-end" disabled={busy} onClick={() => void endCall()}><PhoneOff /><span>End call</span></button> : <button type="button" className="discussion-call-control-end" onClick={() => void leaveCall()}><PhoneOff /><span>Leave</span></button>}
          </div>
        </main>
        <aside className="discussion-call-sidebar">
          <div className="discussion-call-participants"><strong><Users size={16} /> {state.can_manage ? `Student attendance (${activeAttendanceCount}/${state.attendance_roster.length})` : `Participants (${state.participants.length})`}</strong>{state.can_manage && <div className="discussion-call-attendance-legend" aria-label="Attendance status legend"><span><i className="discussion-call-status-active" /> Active</span><span><i className="discussion-call-status-inactive" /> Joined, inactive</span><span><i className="discussion-call-status-not-joined" /> Didn't join</span></div>}<div>{state.can_manage ? state.attendance_roster.map((participant) => <div key={participant.user_id} className="discussion-call-attendance-row"><span className={`discussion-call-attendance-dot discussion-call-status-${participant.attendance_status === 'not_joined' ? 'not-joined' : participant.attendance_status}`} title={attendanceLabel(participant.attendance_status)} aria-label={attendanceLabel(participant.attendance_status)} /><ProfileAvatar name={participant.full_name} avatarPath={participant.avatar_path} className="size-8 text-[9px]" /><span><b>{participant.full_name}</b><small>{participant.school_id} · {attendanceLabel(participant.attendance_status)}{participant.screen_sharing ? ' · Presenting' : ''}</small></span>{participant.screen_sharing && <button type="button" className="discussion-call-list-expand" onClick={() => setExpandedPresenterId(participant.user_id)} aria-label={`Expand ${participant.full_name}'s presentation`} title="Expand presentation"><Maximize2 size={14} /></button>}</div>) : state.participants.map((participant) => <div key={participant.user_id}><ProfileAvatar name={participant.full_name} avatarPath={participant.avatar_path} className="size-8 text-[9px]" /><span>{participant.full_name}{participant.is_host ? ' (Host)' : ''}{participant.screen_sharing ? ' · Presenting' : ''}</span>{participant.screen_sharing ? <button type="button" className="discussion-call-list-expand" onClick={() => setExpandedPresenterId(participant.user_id)} aria-label={`Expand ${participant.full_name}'s presentation`} title="Expand presentation"><Maximize2 size={14} /></button> : participant.camera_enabled ? <Camera size={14} /> : <CameraOff size={14} />}{participant.mic_muted ? <MicOff size={14} /> : <Mic size={14} />}</div>)}</div></div>
          <div className="discussion-call-chat"><strong><MessageCircle size={16} /> Live comments</strong><div className="discussion-call-events">{state.events.map((item) => item.event_type === 'reaction' ? <div className="discussion-call-reaction" key={item.id}><span>{item.content}</span><small>{item.full_name}</small></div> : <div className="discussion-call-comment" key={item.id}><ProfileAvatar name={item.full_name} avatarPath={item.avatar_path} className="size-7 text-[8px]" /><div className="discussion-call-comment-bubble"><strong>{item.full_name}</strong>{item.content && <span>{item.content}</span>}{item.attachment_path && <LiveCommentAttachment event={item} onPreview={() => setPreviewDocument({ bucket: 'discussions', path: item.attachment_path!, name: item.attachment_name ?? 'Attachment' })} />}</div></div>)}</div><div className="discussion-call-reactions">{CALL_REACTIONS.map((emoji) => <button type="button" key={emoji} onClick={() => void postEvent('reaction', emoji)}>{emoji}</button>)}</div>{attachment && <div className="discussion-call-selected-attachment"><span>{attachment.type.startsWith('image/') ? <ImagePlus size={17} /> : <FileText size={17} />}<b>{attachment.name}</b><small>{formatFileSize(attachment.size)}</small></span><button type="button" onClick={() => setAttachment(null)} aria-label="Remove selected attachment"><X size={15} /></button></div>}<form onSubmit={(event) => void submitComment(event)}><input ref={photoInputRef} className="hidden" type="file" accept="image/*" onChange={(event) => { selectAttachment(event.target.files?.[0] ?? null, true); event.currentTarget.value = '' }} /><input ref={fileInputRef} className="hidden" type="file" onChange={(event) => { selectAttachment(event.target.files?.[0] ?? null); event.currentTarget.value = '' }} /><button type="button" className="discussion-call-attach" onClick={() => photoInputRef.current?.click()} disabled={postingComment} aria-label="Attach photo" title="Attach photo"><ImagePlus size={18} /></button><button type="button" className="discussion-call-attach" onClick={() => fileInputRef.current?.click()} disabled={postingComment} aria-label="Attach file" title="Attach file"><Paperclip size={18} /></button><input value={comment} onChange={(event) => setComment(event.target.value)} maxLength={1000} placeholder="Comment in the call" /><button className="discussion-call-send" disabled={(!comment.trim() && !attachment) || postingComment} aria-label="Send comment"><Send size={17} /></button></form></div>
        </aside>
      </div>}
      {expandedPresenterId && <ExpandedPresentation stream={expandedStream} presenterName={expandedPresenterName} onClose={() => setExpandedPresenterId(null)} />}
      <DocumentPreviewModal document={previewDocument} onClose={() => setPreviewDocument(null)} />
    </section>
  </div>

  return createPortal(callUi, document.body)
}

function LiveCommentAttachment({ event, onPreview }: { event: DiscussionLiveEvent; onPreview: () => void }) {
  const [previewUrl, setPreviewUrl] = useState('')
  useEffect(() => {
    if (!event.attachment_path || event.attachment_kind !== 'image') return
    let active = true
    void supabase.storage.from('discussions').createSignedUrl(event.attachment_path, 300, 'preview').then((previewResult) => {
      if (!active || previewResult.error) return
      setPreviewUrl(previewResult.data.signedUrl)
    })
    return () => { active = false }
  }, [event.attachment_kind, event.attachment_path])
  const name = event.attachment_name ?? 'Attachment'
  return <div className="discussion-call-event-attachment">{event.attachment_kind === 'image' && previewUrl ? <button type="button" className="discussion-call-event-image" onClick={onPreview} title={`Preview ${name}`} aria-label={`Preview ${name}`}><img src={previewUrl} alt={name} loading="lazy" /></button> : <span><FileText size={20} /><b>{name}</b><small>{formatFileSize(event.attachment_size ?? 0)}</small></span>}<div className="discussion-call-event-actions"><button type="button" onClick={onPreview} title={`Preview ${name}`} aria-label={`Preview ${name}`}><Eye size={16} /></button></div></div>
}

function formatFileSize(bytes: number) {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

function formatCallDuration(seconds: number) {
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const remainder = seconds % 60
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(remainder).padStart(2, '0')}`
}

function attendanceLabel(status: 'active' | 'inactive' | 'not_joined') {
  if (status === 'active') return 'Active'
  if (status === 'inactive') return 'Joined, inactive'
  return "Didn't join"
}

function VideoTile({ participant, stream, muted = false, label, screenSharing = false, onExpand }: { participant?: DiscussionLiveParticipant; stream: MediaStream | null | undefined; muted?: boolean; label?: string; screenSharing?: boolean; onExpand?: () => void }) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const audioRef = useRef<HTMLAudioElement>(null)
  const presenting = screenSharing || Boolean(participant?.screen_sharing)
  const cameraOn = Boolean((presenting || participant?.camera_enabled) && stream?.getVideoTracks().length)
  useEffect(() => {
    if (videoRef.current) videoRef.current.srcObject = stream ?? null
    if (audioRef.current) audioRef.current.srcObject = stream ?? null
  }, [cameraOn, stream])
  const participantName = label ?? participant?.full_name ?? 'Participant'
  return <article className={`discussion-call-tile ${presenting ? 'discussion-call-tile-presenting' : ''}`}>{cameraOn ? <video ref={videoRef} autoPlay playsInline muted={muted} /> : <><div className="discussion-call-avatar"><ProfileAvatar name={participantName} avatarPath={participant?.avatar_path} className="size-24 text-xl" /><CameraOff size={20} /></div>{!muted && <audio ref={audioRef} autoPlay />}</>}{presenting && <><span className="discussion-call-presenting-badge"><MonitorUp size={14} /> Presenting</span>{onExpand && <button type="button" className="discussion-call-presentation-expand" onClick={onExpand} aria-label={`Expand ${participantName}'s presentation`} title="Expand presentation"><Maximize2 size={18} /></button>}</>}<footer><span>{participantName}{participant?.is_host ? ' · Host' : ''}</span>{participant?.mic_muted ? <MicOff size={15} /> : <Mic size={15} />}</footer></article>
}

function ExpandedPresentation({ stream, presenterName, onClose }: { stream: MediaStream | null | undefined; presenterName: string; onClose: () => void }) {
  const videoRef = useRef<HTMLVideoElement>(null)
  useEffect(() => {
    if (videoRef.current) videoRef.current.srcObject = stream ?? null
  }, [stream])
  return <div className="discussion-call-presentation-viewer" role="dialog" aria-modal="true" aria-label={`${presenterName}'s expanded presentation`}>
    <header><div><span><MonitorUp size={16} /> Presenting</span><strong>{presenterName === 'You' ? 'Your screen' : `${presenterName}'s screen`}</strong></div><button type="button" onClick={onClose} aria-label="Close expanded presentation" title="Close expanded presentation"><X size={22} /></button></header>
    <div className="discussion-call-presentation-canvas">{stream?.getVideoTracks().length ? <video ref={videoRef} autoPlay playsInline muted /> : <div><MonitorUp size={42} /><strong>Waiting for the shared screen…</strong></div>}</div>
  </div>
}