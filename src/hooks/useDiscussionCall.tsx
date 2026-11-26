/* eslint-disable react-refresh/only-export-components -- provider and paired hook intentionally share this module */
import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from 'react'
import { DiscussionVideoCall, type DiscussionVideoCallShutdown } from '../components/classroom/DiscussionVideoCall'
import { useAuth } from './useAuth'

interface OpenDiscussionCallOptions {
  classId: string
  topicId: string
  topicTitle: string
  canStart: boolean
  currentUserId: string
  joinImmediately?: boolean
}

interface DiscussionCallContextValue {
  activeTopicId: string | null
  activeClassId: string | null
  activeTopicTitle: string | null
  isJoined: boolean
  openCall: (options: OpenDiscussionCallOptions) => { blocked: boolean; message?: string }
  restoreCall: () => void
}

const DiscussionCallContext = createContext<DiscussionCallContextValue | undefined>(undefined)

export function DiscussionCallProvider({ children }: { children: ReactNode }) {
  const { registerBeforeSignOut } = useAuth()
  const [activeCall, setActiveCall] = useState<OpenDiscussionCallOptions | null>(null)
  const [isJoined, setIsJoined] = useState(false)
  const [restoreSignal, setRestoreSignal] = useState(0)
  const activeCallRef = useRef<OpenDiscussionCallOptions | null>(null)
  const shutdownRef = useRef<DiscussionVideoCallShutdown | null>(null)

  const setShutdownHandler = useCallback((shutdown: DiscussionVideoCallShutdown | null) => {
    shutdownRef.current = shutdown
  }, [])

  const closeCall = useCallback(() => {
    activeCallRef.current = null
    shutdownRef.current = null
    setActiveCall(null)
    setIsJoined(false)
  }, [])

  const restoreCall = useCallback(() => {
    if (activeCallRef.current) setRestoreSignal((signal) => signal + 1)
  }, [])

  const openCall = useCallback((options: OpenDiscussionCallOptions) => {
    const currentCall = activeCallRef.current
    if (currentCall) {
      if (currentCall.topicId !== options.topicId && isJoined) {
        setRestoreSignal((signal) => signal + 1)
        return { blocked: true, message: `Leave or end your current call in “${currentCall.topicTitle}” before joining or starting another call.` }
      }
      if (currentCall.topicId === options.topicId && options.joinImmediately && !currentCall.joinImmediately) {
        const updatedCall = { ...currentCall, joinImmediately: true }
        activeCallRef.current = updatedCall
        setActiveCall(updatedCall)
      }
      if (currentCall.topicId === options.topicId) {
        setRestoreSignal((signal) => signal + 1)
        return { blocked: false }
      }
    }
    activeCallRef.current = options
    setActiveCall(options)
    setIsJoined(false)
    return { blocked: false }
  }, [isJoined])

  useEffect(() => registerBeforeSignOut(async () => {
    await shutdownRef.current?.()
  }), [registerBeforeSignOut])

  return <DiscussionCallContext.Provider value={{ activeTopicId: activeCall?.topicId ?? null, activeClassId: activeCall?.classId ?? null, activeTopicTitle: activeCall?.topicTitle ?? null, isJoined, openCall, restoreCall }}>
    {children}
    {activeCall && <DiscussionVideoCall
      key={activeCall.topicId}
      topicId={activeCall.topicId}
      topicTitle={activeCall.topicTitle}
      canStart={activeCall.canStart}
      currentUserId={activeCall.currentUserId}
      joinImmediately={activeCall.joinImmediately}
      restoreSignal={restoreSignal}
      onJoinedChange={setIsJoined}
      onShutdownReady={setShutdownHandler}
      onClose={closeCall}
    />}
  </DiscussionCallContext.Provider>
}

export function useDiscussionCall() {
  const context = useContext(DiscussionCallContext)
  if (!context) throw new Error('useDiscussionCall must be used within DiscussionCallProvider')
  return context
}