import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { BarChart3, Clock3, Pause, Play, RadioTower, Square, Users, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import type { AssessmentKind, ClassSummary, Database, LiveQuizLobbyStatus, LiveQuizState } from '../../types/database'
import { EmptyState, ErrorState, LoadingState } from '../ScreenState'
import { ScoreBar } from '../ScoreBar'
import { DateTimeField } from '../DateTimeField'
import { formatDate } from './workspace'
import { ProfileAvatar } from '../ProfileAvatar'

type Quiz = Database['public']['Tables']['quizzes']['Row']
type Session = Database['public']['Tables']['quiz_live_sessions']['Row']
const showsLiveRoster = (status: Session['status']) => ['lobby', 'active', 'paused'].includes(status)

export function LiveQuizSessions({ classId, canManage, isStudent, assessmentKind, onLobbyStatusChange }: { classId: string; canManage: boolean; isStudent: boolean; assessmentKind: AssessmentKind; onLobbyStatusChange?: (status: LiveQuizLobbyStatus | null) => void }) {
  const isExam = assessmentKind === 'exam'
  const noun = isExam ? 'exam' : 'quiz'
  const titleNoun = isExam ? 'Exam' : 'Quiz'
  const [sessions, setSessions] = useState<Session[]>([])
  const [quizzes, setQuizzes] = useState<Quiz[]>([])
  const [classItem, setClassItem] = useState<ClassSummary | null>(null)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [state, setState] = useState<LiveQuizState | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [createOpen, setCreateOpen] = useState(false)
  const [quizId, setQuizId] = useState('')
  const [meetingId, setMeetingId] = useState('')
  const [scheduledStart, setScheduledStart] = useState('')
  const [questionSeconds, setQuestionSeconds] = useState('30')
  const [showCorrect, setShowCorrect] = useState(true)
  const [showLeaderboard, setShowLeaderboard] = useState(true)
  const [randomizeChoices, setRandomizeChoices] = useState(false)
  const [answer, setAnswer] = useState('')
  const [now, setNow] = useState(0)

  const loadSessions = useCallback(async (showLoading = false) => {
    if (showLoading) setLoading(true)
    const [sessionResult, quizResult, classResult] = await Promise.all([
      supabase.rpc('list_live_quiz_sessions', { target_class_id: classId, assessment_kind: assessmentKind }),
      canManage ? supabase.from('quizzes').select('*').eq('class_id', classId).eq('assessment_kind', assessmentKind).order('created_at', { ascending: false }) : Promise.resolve({ data: [], error: null }),
      canManage ? supabase.from('classes').select('*').eq('id', classId).maybeSingle() : Promise.resolve({ data: null, error: null }),
    ])
    const firstError = sessionResult.error ?? quizResult.error ?? classResult.error
    if (firstError) setError(firstError.message)
    else {
      const rows = sessionResult.data ?? []
      const loadedClass = classResult.data as ClassSummary | null
      setSessions(rows)
      setQuizzes(quizResult.data ?? [])
      setClassItem(loadedClass)
      setSelectedId((current) => current && rows.some((item) => item.id === current) ? current : rows[0]?.id ?? null)
      if (quizResult.data?.[0]) setQuizId((current) => current || quizResult.data[0].id)
      if (loadedClass?.schedule[0]) setMeetingId((current) => current || String(loadedClass.schedule[0].meeting_id))
    }
    if (showLoading) setLoading(false)
  }, [assessmentKind, canManage, classId])

  const loadState = useCallback(async (sessionId: string) => {
    const { data, error: stateError } = await supabase.rpc('live_quiz_state', { target_session_id: sessionId })
    if (stateError) setError(stateError.message)
    else {
      setState(data)
      onLobbyStatusChange?.(showsLiveRoster(data.session.status) ? { session_id: data.session.id, joined_student_ids: data.joined_student_ids } : null)
    }
  }, [onLobbyStatusChange])

  useEffect(() => { const initial = window.setTimeout(() => void loadSessions(true), 0); return () => window.clearTimeout(initial) }, [loadSessions])
  useEffect(() => { if (!selectedId) return; const initial = window.setTimeout(() => void loadState(selectedId), 0); return () => window.clearTimeout(initial) }, [loadState, selectedId])
  useEffect(() => {
    const initial = window.setTimeout(() => setNow(Date.now()), 0)
    const timer = window.setInterval(() => {
      setNow(Date.now())
      void loadSessions(false)
      if (selectedId) void loadState(selectedId)
    }, 2000)
    return () => { window.clearTimeout(initial); window.clearInterval(timer) }
  }, [loadSessions, loadState, selectedId])

  const createSession = async (event: FormEvent) => {
    event.preventDefault(); setError(null)
    const seconds = Number(questionSeconds)
    if (!quizId) return setError(`Select an ${noun}.`)
    if (!Number.isInteger(seconds) || seconds < 5 || seconds > 600) return setError('Question time must be from 5 to 600 seconds.')
    setSaving(true)
    const { data, error: createError } = await supabase.rpc('create_live_quiz_session', {
      target_quiz_id: quizId,
      meeting_id: meetingId ? Number(meetingId) : null,
      scheduled_start: scheduledStart ? new Date(scheduledStart).toISOString() : null,
      question_time_seconds: seconds,
      show_correct_answer: showCorrect,
      show_leaderboard: showLeaderboard,
      randomize_choices: randomizeChoices,
    })
    setSaving(false)
    if (createError) return setError(createError.message)
    setCreateOpen(false); setState(null); setAnswer(''); setSelectedId(data.id); setMeetingId(classItem?.schedule[0] ? String(classItem.schedule[0].meeting_id) : ''); setScheduledStart(''); await loadSessions(false)
  }

  const control = async (sessionAction: 'open_lobby' | 'start' | 'pause' | 'resume' | 'complete' | 'cancel') => {
    if (!selectedId) return
    setSaving(true); setError(null)
    const { data, error: controlError } = await supabase.rpc('control_live_quiz_session', { target_session_id: selectedId, session_action: sessionAction })
    setSaving(false)
    if (controlError) setError(controlError.message); else {
      setState(data)
      onLobbyStatusChange?.(showsLiveRoster(data.session.status) ? { session_id: data.session.id, joined_student_ids: data.joined_student_ids } : null)
      await loadSessions(false)
    }
  }

  const join = async () => {
    if (!selectedId) return
    setSaving(true); setError(null)
    const { data, error: joinError } = await supabase.rpc('join_live_quiz_session', { target_session_id: selectedId })
    setSaving(false)
    if (joinError) setError(joinError.message); else setState(data)
  }

  const submitAnswer = async (event: FormEvent) => {
    event.preventDefault()
    if (!selectedId || !answer.trim()) return setError('Select or enter an answer.')
    setSaving(true); setError(null)
    const { data, error: answerError } = await supabase.rpc('submit_live_quiz_answer', { target_session_id: selectedId, submitted_answer: answer.trim() })
    setSaving(false)
    if (answerError) setError(answerError.message); else { setAnswer(''); setState(data) }
  }

  const currentQuestion = state?.questions.find((question) => question.id === state.session.current_question_id) ?? null
  const currentResponse = state?.my_responses.find((response) => response.question_id === state.session.current_question_id)
  const remainingSeconds = !state?.session.question_opened_at || !state.session.question_time_seconds || state.session.status !== 'active'
    ? null
    : Math.max(0, Math.ceil((new Date(state.session.question_opened_at).getTime() + state.session.question_time_seconds * 1000 - now) / 1000))

  return <section>
    <div className="mb-5 flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
      <div><h3 className="text-lg font-black text-slate-900">Live {noun} sessions</h3><p className="mt-1 text-sm text-slate-500">Instructor-controlled {noun}s for students already enrolled in this class. No join code is required.</p></div>
      {canManage && <button className={createOpen ? 'button-secondary' : 'button-primary'} onClick={() => setCreateOpen((value) => !value)}>{createOpen ? <><X size={17} /> Cancel</> : <><RadioTower size={17} /> New live session</>}</button>}
    </div>
    {createOpen && <form className="workspace-form mb-5" onSubmit={createSession}>
      <label className="field-label">{titleNoun}<select className="form-select" value={quizId} onChange={(event) => setQuizId(event.target.value)}><option value="">Select {noun}</option>{quizzes.map((quiz) => <option value={quiz.id} key={quiz.id}>{quiz.title}</option>)}</select></label>
      <div className="grid gap-3 md:grid-cols-2">
        <label className="field-label">Class meeting <span className="font-normal text-slate-400">(from class schedule)</span><select className="form-select" value={meetingId} disabled={(classItem?.schedule.length ?? 0) <= 1} onChange={(event) => setMeetingId(event.target.value)}>{!classItem?.schedule.length && <option value="">No published class meeting</option>}{classItem?.schedule.map((meeting) => <option value={meeting.meeting_id} key={meeting.meeting_id}>{meeting.day_of_week} · {meeting.start_time}–{meeting.end_time} · {meeting.room_code} · {meeting.class_type}</option>)}</select></label>
        <DateTimeField label="Scheduled start" value={scheduledStart} onChange={setScheduledStart} />
      </div>
      <label className="field-label">Seconds per question<input className="form-input" type="number" min="5" max="600" value={questionSeconds} onChange={(event) => setQuestionSeconds(event.target.value)} /></label>
      <div className="grid gap-2 sm:grid-cols-3"><Check label="Show correctness" checked={showCorrect} onChange={setShowCorrect} /><Check label="Show leaderboard" checked={showLeaderboard} onChange={setShowLeaderboard} /><Check label="Randomize choices" checked={randomizeChoices} onChange={setRandomizeChoices} /></div>
      <div className="flex justify-end"><button className="button-primary" disabled={saving}>{saving ? 'Creating…' : 'Create live session'}</button></div>
    </form>}
    {loading && <LoadingState label="Loading live sessions…" />}
    {error && <ErrorState message={error} onRetry={() => void loadSessions(true)} />}
    {!loading && sessions.length === 0 && <EmptyState title="No live sessions yet" description={canManage ? `Create a session from an existing objective ${noun}.` : `Your instructor has not created a live ${noun} for this class.`} />}
    {!loading && sessions.length > 0 && <div className="content-sized-selector-layout grid gap-4">
      <div className="content-sized-selector-list">{sessions.map((session) => <button type="button" key={session.id} className={`discussion-topic ${selectedId === session.id ? 'discussion-topic-active' : ''}`} onClick={() => { setState(null); setAnswer(''); setSelectedId(session.id) }}><div className="flex items-center gap-2"><RadioTower size={16} /><strong className="truncate">{session.quiz_title}</strong></div><span>{session.status} · {session.participant_count ?? 0} joined</span><span>{session.scheduled_start ? formatDate(session.scheduled_start) : 'Start when ready'}</span></button>)}</div>
      <div className="classroom-outline rounded-2xl border border-slate-200 bg-white p-4 sm:p-5">
        {!state ? <LoadingState label="Loading session…" /> : <>
          <div className="flex flex-wrap items-start justify-between gap-3"><div><div className="flex items-center gap-2"><RadioTower className={state.session.status === 'active' ? 'text-red-600' : 'text-brand-700'} size={20} /><h3 className="text-xl font-black text-slate-900">{state.session.quiz_title}</h3></div><p className="mt-1 text-sm text-slate-500">{state.session.quiz_description || `Instructor-paced live ${noun}`}</p><p className="mt-2 text-xs font-bold uppercase tracking-wide text-slate-400">{state.session.status} · {state.participant_count}/{state.enrolled_count} students connected</p></div>{remainingSeconds !== null && <span className={`rounded-full px-3 py-1.5 text-sm font-black ${remainingSeconds <= 5 ? 'bg-red-100 text-red-700' : 'bg-blue-50 text-brand-700'}`}><Clock3 className="mr-1 inline" size={15} />{remainingSeconds}s</span>}</div>
          {canManage && <InstructorControls state={state} saving={saving} onControl={control} />}
          {isStudent && !state.participant && !['completed','cancelled'].includes(state.session.status) && <div className="my-5 rounded-xl border border-blue-200 bg-blue-50 p-5 text-center"><Users className="mx-auto text-brand-700" /><p className="mt-2 font-extrabold text-slate-900">Enter your class lobby</p><p className="mt-1 text-sm text-slate-600">Your active class enrollment is your authorization. No session code is needed.</p><button className="button-primary mt-4" disabled={saving} onClick={() => void join()}>{saving ? 'Entering…' : 'Enter live session'}</button></div>}
          {isStudent && state.participant && ['scheduled','lobby'].includes(state.session.status) && <WaitingMessage text={`You are connected. Waiting for your instructor to start the ${noun}…`} />}
          {isStudent && state.participant && state.session.status === 'paused' && <WaitingMessage text={`The instructor paused the live ${noun}.`} />}
          {isStudent && state.participant && state.session.status === 'active' && currentQuestion && <StudentQuestion question={currentQuestion} response={currentResponse} answer={answer} remainingSeconds={remainingSeconds} saving={saving} onAnswer={setAnswer} onSubmit={submitAnswer} />}
          {state.session.status === 'completed' && <Results state={state} canManage={canManage} />}
          {state.session.status === 'cancelled' && <WaitingMessage text="This live session was cancelled." />}
          {canManage && state.session.status !== 'completed' && state.session.status !== 'cancelled' && currentQuestion && <div className="my-5 rounded-xl bg-slate-50 p-5"><p className="text-xs font-extrabold uppercase tracking-wide text-brand-700">Current question</p><h4 className="mt-2 text-lg font-black text-slate-900">{currentQuestion.prompt}</h4><p className="mt-2 text-sm text-slate-500">{state.response_count} of {state.participant_count} connected students answered.</p></div>}
        </>}
      </div>
    </div>}
  </section>
}

function InstructorControls({ state, saving, onControl }: { state: LiveQuizState; saving: boolean; onControl: (action: 'open_lobby' | 'start' | 'pause' | 'resume' | 'complete' | 'cancel') => Promise<void> }) {
  const status = state.session.status
  return <div className="my-5 flex flex-wrap gap-2 rounded-xl border border-slate-200 bg-slate-50 p-4">
    {status === 'scheduled' && <button className="button-secondary" disabled={saving} onClick={() => void onControl('open_lobby')}><Users size={16} /> Open lobby</button>}
    {['scheduled','lobby'].includes(status) && <button className="button-primary" disabled={saving} onClick={() => void onControl('start')}><Play size={16} /> Start session</button>}
    {status === 'active' && <button className="button-secondary" disabled={saving} onClick={() => void onControl('pause')}><Pause size={16} /> Pause</button>}
    {status === 'paused' && <button className="button-primary" disabled={saving} onClick={() => void onControl('resume')}><Play size={16} /> Resume</button>}
    {['active','paused'].includes(status) && <button className="button-secondary" disabled={saving} onClick={() => void onControl('complete')}><Square size={16} /> End session</button>}
    {!['completed','cancelled'].includes(status) && <button className="button-secondary text-red-600" disabled={saving} onClick={() => void onControl('cancel')}><X size={16} /> Cancel session</button>}
  </div>
}

function StudentQuestion({ question, response, answer, remainingSeconds, saving, onAnswer, onSubmit }: { question: Database['public']['Tables']['quiz_questions']['Row']; response: LiveQuizState['my_responses'][number] | undefined; answer: string; remainingSeconds: number | null; saving: boolean; onAnswer: (value: string) => void; onSubmit: (event: FormEvent) => Promise<void> }) {
  const options = Array.isArray(question.options) ? question.options.map(String) : []
  if (response) return <div className="my-5 rounded-xl border border-emerald-200 bg-emerald-50 p-5 text-center"><p className="font-extrabold text-emerald-800">Answer submitted</p><p className="mt-1 text-sm text-emerald-700">Waiting for the other connected students to answer…</p>{response.is_correct !== null && <p className="mt-3 text-sm font-black">{response.is_correct ? 'Correct' : 'Incorrect'}</p>}</div>
  return <form className="my-5 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm" onSubmit={(event) => void onSubmit(event)}><p className="text-xs font-extrabold uppercase tracking-wide text-brand-700">Live question</p><h4 className="mt-2 text-xl font-black text-slate-900">{question.prompt}</h4>{question.question_type === 'identification' ? <input className="form-input mt-5" value={answer} onChange={(event) => onAnswer(event.target.value)} placeholder="Enter your answer" /> : <div className="mt-5 grid gap-2">{options.map((option) => <label key={option} className={`cursor-pointer rounded-xl border p-3 text-sm font-semibold ${answer === option ? 'border-brand-500 bg-blue-50 text-brand-800' : 'border-slate-200 text-slate-700'}`}><input className="mr-2" type="radio" name={question.id} checked={answer === option} onChange={() => onAnswer(option)} />{option}</label>)}</div>}<button className="button-primary mt-5 w-full" disabled={saving || !answer.trim() || remainingSeconds === 0}>{saving ? 'Submitting…' : remainingSeconds === 0 ? 'Time expired' : 'Submit answer'}</button></form>
}

function Results({ state, canManage }: { state: LiveQuizState; canManage: boolean }) {
  return <section className="my-5 overflow-hidden rounded-2xl border border-slate-200"><div className="flex items-center gap-2 border-b border-slate-200 bg-slate-50 p-4"><BarChart3 size={18} className="text-brand-700" /><h4 className="font-extrabold text-slate-900">Final results</h4></div>{state.results.length ? <div className="overflow-x-auto"><table className="admin-table"><thead><tr>{canManage && <th>Student</th>}<th>Score</th><th>Answered</th></tr></thead><tbody>{state.results.map((result, index) => <tr key={`${result.student_id}-${index}`}>{canManage && <td data-label="Student"><div className="flex min-w-44 items-center gap-3"><ProfileAvatar name={result.student_name ?? 'Student'} avatarPath={result.avatar_path} className="size-10 text-xs" /><div><strong>{result.student_name}</strong><p className="text-xs text-slate-400">{result.student_number}</p></div></div></td>}<td data-label="Score"><div className="min-w-64"><ScoreBar earned={result.score} possible={result.max_score} /></div></td><td data-label="Answered">{result.answered_count}</td></tr>)}</tbody></table></div> : <div className="p-5"><EmptyState title="No submitted answers" description="No student responses were recorded for this session." /></div>}</section>
}

function WaitingMessage({ text }: { text: string }) { return <div className="my-5 rounded-xl border border-slate-200 bg-slate-50 p-6 text-center"><Clock3 className="mx-auto text-brand-700" /><p className="mt-3 font-extrabold text-slate-800">{text}</p></div> }
function Check({ label, checked, onChange }: { label: string; checked: boolean; onChange: (value: boolean) => void }) { return <label className="flex items-center gap-2 rounded-xl border border-slate-200 bg-white p-3 text-sm font-semibold text-slate-700"><input type="checkbox" checked={checked} onChange={(event) => onChange(event.target.checked)} />{label}</label> }