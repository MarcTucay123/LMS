import { useCallback, useEffect, useMemo, useRef, useState, type FormEvent } from 'react'
import { CircleHelp, Clock3, Eye, FileUp, Pencil, Plus, RadioTower, Trash2, X } from 'lucide-react'
import { EmptyState, ErrorState, LoadingState } from '../ScreenState'
import { ScoreBar } from '../ScoreBar'
import { DateTimeField } from '../DateTimeField'
import { useAuth } from '../../hooks/useAuth'
import { supabase } from '../../lib/supabase'
import type { AssessmentKind, Database, Json, LiveQuizLobbyStatus, PublishStatus } from '../../types/database'
import { TabHeading } from './MaterialsTab'
import { LiveQuizSessions } from './LiveQuizSessions'
import { useClassNotifications } from '../../hooks/useClassNotifications'
import { DocumentPreviewModal, type PreviewDocument } from './DocumentPreviewModal'
import { formatDate, messageFrom, safeFileName } from './workspace'
import { destructiveActionConfirmation } from '../../lib/confirmDestructiveAction'
import { useConfirmation } from '../../hooks/useConfirmation'
import { ProfileAvatar } from '../ProfileAvatar'

type Quiz = Database['public']['Tables']['quizzes']['Row']
type Question = Database['public']['Tables']['quiz_questions']['Row']
type ManagedQuestion = Question & { correct_answer?: string | null }
type QuestionType = Question['question_type']
type Attempt = Database['public']['Tables']['quiz_attempts']['Row']
interface Student { id: string; full_name: string; school_id: string; avatar_path: string | null }
const examTypes = ['Prelim Exam', 'Midterm Exam', 'Semi-Final Exam', 'Final-Exam'] as const
export function QuizzesTab({ classId, canManage, isStudent, onLobbyStatusChange }: { classId: string; canManage: boolean; isStudent: boolean; onLobbyStatusChange?: (status: LiveQuizLobbyStatus | null) => void }) {
  return <AssessmentSessionsTab classId={classId} canManage={canManage} isStudent={isStudent} assessmentKind="quiz" onLobbyStatusChange={onLobbyStatusChange} />
}

export function ExamsTab({ classId, canManage, isStudent, onLobbyStatusChange }: { classId: string; canManage: boolean; isStudent: boolean; onLobbyStatusChange?: (status: LiveQuizLobbyStatus | null) => void }) {
  return <AssessmentSessionsTab classId={classId} canManage={canManage} isStudent={isStudent} assessmentKind="exam" onLobbyStatusChange={onLobbyStatusChange} />
}

function AssessmentSessionsTab({ classId, canManage, isStudent, assessmentKind, onLobbyStatusChange }: { classId: string; canManage: boolean; isStudent: boolean; assessmentKind: AssessmentKind; onLobbyStatusChange?: (status: LiveQuizLobbyStatus | null) => void }) {
  const noun = assessmentKind === 'exam' ? 'exam' : 'quiz'
  const plural = assessmentKind === 'exam' ? 'exams' : 'quizzes'
  const [view, setView] = useState<'regular' | 'live'>('regular')
  const [liveCount, setLiveCount] = useState(0)
  const checkLive = useCallback(async () => {
    const { data } = await supabase.rpc('list_live_quiz_sessions', { target_class_id: classId, assessment_kind: assessmentKind })
    setLiveCount((data ?? []).filter((session) => ['lobby', 'active', 'paused'].includes(session.status)).length)
  }, [assessmentKind, classId])
  useEffect(() => {
    const initial = window.setTimeout(() => void checkLive(), 0)
    const timer = window.setInterval(() => void checkLive(), 4000)
    return () => { window.clearTimeout(initial); window.clearInterval(timer) }
  }, [checkLive])
  const showRegular = () => { setView('regular'); onLobbyStatusChange?.(null) }
  return <div>{liveCount > 0 && view !== 'live' && <button type="button" onClick={() => setView('live')} className="mb-5 flex w-full items-center justify-between rounded-xl border border-red-200 bg-red-50 p-4 text-left text-red-800"><span><strong className="block"><RadioTower className="mr-2 inline animate-pulse" size={18} />Live {noun} available</strong><span className="mt-1 block text-sm">{liveCount} session{liveCount === 1 ? '' : 's'} currently open for this class.</span></span><span className="rounded-lg bg-white px-3 py-1.5 text-xs font-black uppercase tracking-wide">Open</span></button>}<div className="mb-6 inline-flex rounded-xl border border-slate-200 bg-slate-50 p-1"><button type="button" className={`rounded-lg px-4 py-2 text-sm font-extrabold ${view === 'regular' ? 'bg-white text-brand-700 shadow-sm' : 'text-slate-500'}`} onClick={showRegular}><CircleHelp className="mr-1 inline" size={16} /> Regular {plural}</button><button type="button" className={`rounded-lg px-4 py-2 text-sm font-extrabold ${view === 'live' ? 'bg-white text-brand-700 shadow-sm' : 'text-slate-500'}`} onClick={() => setView('live')}><RadioTower className="mr-1 inline" size={16} /> Live sessions{liveCount > 0 && <span className="ml-2 rounded-full bg-red-600 px-1.5 py-0.5 text-[10px] text-white">{liveCount}</span>}</button></div>{view === 'regular' ? <AssessmentsTab classId={classId} canManage={canManage} isStudent={isStudent} assessmentKind={assessmentKind} /> : <LiveQuizSessions classId={classId} canManage={canManage} isStudent={isStudent} assessmentKind={assessmentKind} onLobbyStatusChange={onLobbyStatusChange} />}</div>
}

function AssessmentsTab({ classId, canManage, isStudent, assessmentKind }: { classId: string; canManage: boolean; isStudent: boolean; assessmentKind: AssessmentKind }) {
  const { confirm } = useConfirmation()
  const { profile } = useAuth()
  const { isUnread, markItemViewed } = useClassNotifications()
  const isExam = assessmentKind === 'exam'
  const noun = isExam ? 'exam' : 'quiz'
  const plural = isExam ? 'Exams' : 'Quizzes'
  const notificationSection = isExam ? 'exams' : 'quizzes'
  const [quizzes, setQuizzes] = useState<Quiz[]>([])
  const [questions, setQuestions] = useState<Record<string, ManagedQuestion[]>>({})
  const [attempts, setAttempts] = useState<Attempt[]>([])
  const [students, setStudents] = useState<Student[]>([])
  const [selected, setSelected] = useState<string | null>(null)
  const [answers, setAnswers] = useState<Record<string, string>>({})
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [open, setOpen] = useState(false)
  const [saving, setSaving] = useState(false)
  const [questionFormOpen, setQuestionFormOpen] = useState(false)
  const [submissionFiles, setSubmissionFiles] = useState<Record<string, File | null>>({})
  const [previewDocument, setPreviewDocument] = useState<PreviewDocument | null>(null)
  const [now, setNow] = useState(0)
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [status, setStatus] = useState<PublishStatus>('draft')
  const [opensAt, setOpensAt] = useState('')
  const [closesAt, setClosesAt] = useState('')
  const [timeLimit, setTimeLimit] = useState('')
  const [fileSubmissionPoints, setFileSubmissionPoints] = useState('100')
  const [examType, setExamType] = useState<string>('Prelim Exam')
  const [customExamType, setCustomExamType] = useState('')
  const [prompt, setPrompt] = useState('')
  const [questionType, setQuestionType] = useState<QuestionType>('multiple_choice')
  const [options, setOptions] = useState('')
  const [correct, setCorrect] = useState('')
  const [questionPoints, setQuestionPoints] = useState('1')
  const [editingQuestionId, setEditingQuestionId] = useState<string | null>(null)
  const [editQuestionPrompt, setEditQuestionPrompt] = useState('')
  const [editQuestionType, setEditQuestionType] = useState<QuestionType>('multiple_choice')
  const [editQuestionOptions, setEditQuestionOptions] = useState('')
  const [editQuestionCorrect, setEditQuestionCorrect] = useState('')
  const [editQuestionPoints, setEditQuestionPoints] = useState('1')
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editTitle, setEditTitle] = useState('')
  const [editDescription, setEditDescription] = useState('')
  const [editStatus, setEditStatus] = useState<PublishStatus>('draft')
  const [editOpensAt, setEditOpensAt] = useState('')
  const [editClosesAt, setEditClosesAt] = useState('')
  const [editTimeLimit, setEditTimeLimit] = useState('')
  const [editFileSubmissionPoints, setEditFileSubmissionPoints] = useState('100')
  const [editExamType, setEditExamType] = useState<string>('Prelim Exam')
  const [editCustomExamType, setEditCustomExamType] = useState('')
  const autoSubmitting = useRef<string | null>(null)
  const attachmentInput = useRef<HTMLInputElement | null>(null)

  const load = useCallback(async (showLoading = true) => {
    if (showLoading) setLoading(true)
    setError(null)
    const [quizResult, enrollmentResult] = await Promise.all([
      supabase.from('quizzes').select('*').eq('class_id', classId).eq('assessment_kind', assessmentKind).order('created_at', { ascending: false }),
      canManage ? supabase.from('enrollments').select('student:profiles!enrollments_student_id_fkey(id, full_name, school_id, avatar_path)').eq('class_id', classId).eq('status', 'enrolled') : Promise.resolve({ data: [], error: null }),
    ])
    if (quizResult.error || enrollmentResult.error) { setError((quizResult.error ?? enrollmentResult.error)?.message ?? `Unable to load ${noun}s.`); setLoading(false); return }
    const rows = quizResult.data ?? []
    setQuizzes(rows)
    setStudents((enrollmentResult.data ?? []).map(normalizeStudent).filter((student): student is Student => Boolean(student)).sort((a, b) => a.full_name.localeCompare(b.full_name)))
    if (!rows.length) { setQuestions({}); setAttempts([]); setLoading(false); return }
    const ids = rows.map((item) => item.id)
    const [questionResult, attemptResult] = await Promise.all([
      supabase.from('quiz_questions').select('*').in('quiz_id', ids).order('position'),
      supabase.from('quiz_attempts').select('*').in('quiz_id', ids),
    ])
    if (questionResult.error || attemptResult.error) setError((questionResult.error ?? attemptResult.error)?.message ?? `Unable to load ${noun}s.`)
    else { setQuestions(groupQuestions(questionResult.data ?? [])); setAttempts(attemptResult.data ?? []) }
    setLoading(false)
  }, [assessmentKind, canManage, classId, noun])

  useEffect(() => { const timer = window.setTimeout(() => void load(), 0); return () => window.clearTimeout(timer) }, [load])
  useEffect(() => {
    const updateClock = () => setNow(Date.now())
    const initial = window.setTimeout(updateClock, 0)
    const timer = window.setInterval(updateClock, 1000)
    return () => { window.clearTimeout(initial); window.clearInterval(timer) }
  }, [])

  const createQuiz = async (event: FormEvent) => {
    event.preventDefault(); setError(null)
    const limit = timeLimit.trim() ? Number(timeLimit) : null
    const filePoints = Number(fileSubmissionPoints)
    const selectedExamType = examType === 'Others' ? customExamType.trim() : examType
    if (!title.trim()) return setError(`Enter an ${noun} title.`)
    if (isExam && !selectedExamType) return setError('Enter the custom exam type.')
    if (opensAt && new Date(opensAt).getTime() < Date.now()) return setError('Opening date and time must be the current time or a future time. Past dates are not allowed.')
    if (opensAt && closesAt && new Date(closesAt).getTime() <= new Date(opensAt).getTime()) return setError('Closing date must be after the opening date.')
    if (limit !== null && (!Number.isInteger(limit) || limit < 1)) return setError('Time limit must be a whole number of minutes.')
    if (!Number.isFinite(filePoints) || filePoints <= 0) return setError('File submission points must be greater than zero.')
    setSaving(true)
    const { error: insertError } = await supabase.from('quizzes').insert({ class_id: classId, title: title.trim(), description: description.trim() || null, file_submission_points: filePoints, assessment_kind: assessmentKind, exam_type: isExam ? selectedExamType : null, opens_at: opensAt ? new Date(opensAt).toISOString() : null, closes_at: closesAt ? new Date(closesAt).toISOString() : null, time_limit_minutes: limit, status })
    setSaving(false)
    if (insertError) return setError(insertError.message)
    setTitle(''); setDescription(''); setStatus('draft'); setOpensAt(''); setClosesAt(''); setTimeLimit(''); setFileSubmissionPoints('100'); setExamType('Prelim Exam'); setCustomExamType(''); setOpen(false)
    await load()
  }

  const addQuestion = async (event: FormEvent) => {
    event.preventDefault(); setError(null)
    if (!selected || !prompt.trim()) return setError('Enter the question.')
    if (questionType !== 'essay' && !correct.trim()) return setError('Enter the correct answer.')
    const questionOptions: Json = questionType === 'true_false' ? ['True', 'False'] : questionType === 'multiple_choice' ? options.split(',').map((item) => item.trim()).filter(Boolean) : []
    if (questionType === 'multiple_choice' && (questionOptions as string[]).length < 2) return setError('Enter at least two choices.')
    if (['multiple_choice', 'true_false'].includes(questionType) && !(questionOptions as string[]).includes(correct.trim())) return setError('The correct answer must match one of the choices.')
    setSaving(true)
    const { data, error: questionError } = await supabase.from('quiz_questions').insert({ quiz_id: selected, prompt: prompt.trim(), question_type: questionType, options: questionOptions, points: Number(questionPoints) || 1, position: (questions[selected]?.length ?? 0) + 1 }).select().single()
    if (!questionError && data) {
      const { error: keyError } = await supabase.from('quiz_answer_keys').insert({ question_id: data.id, correct_answer: correct.trim(), case_sensitive: false })
      if (keyError) setError(keyError.message); else { setPrompt(''); setOptions(''); setCorrect(''); setQuestionPoints('1'); setQuestionFormOpen(false); await load(false) }
    } else setError(questionError?.message ?? 'Unable to add question.')
    setSaving(false)
  }

  const beginQuestionEdit = (question: ManagedQuestion) => {
    setError(null)
    setEditingQuestionId(question.id)
    setEditQuestionPrompt(question.prompt)
    setEditQuestionType(question.question_type)
    setEditQuestionOptions(Array.isArray(question.options) ? question.options.map(String).join(', ') : '')
    setEditQuestionCorrect(question.correct_answer ?? '')
    setEditQuestionPoints(String(question.points))
  }

  const cancelQuestionEdit = () => {
    setEditingQuestionId(null)
    setError(null)
  }

  const saveQuestion = async (event: FormEvent, question: ManagedQuestion) => {
    event.preventDefault(); setError(null)
    const pointsValue = Number(editQuestionPoints)
    const questionOptions: Json = editQuestionType === 'true_false' ? ['True', 'False'] : editQuestionType === 'multiple_choice' ? editQuestionOptions.split(',').map((item) => item.trim()).filter(Boolean) : []
    if (!editQuestionPrompt.trim()) return setError('Enter the question.')
    if (editQuestionType !== 'essay' && !editQuestionCorrect.trim()) return setError('Enter the correct answer.')
    if (!Number.isFinite(pointsValue) || pointsValue <= 0) return setError('Points must be greater than zero.')
    if (editQuestionType === 'multiple_choice' && (questionOptions as string[]).length < 2) return setError('Enter at least two choices.')
    if (['multiple_choice', 'true_false'].includes(editQuestionType) && !(questionOptions as string[]).includes(editQuestionCorrect.trim())) return setError('The correct answer must match one of the choices.')
    setSaving(true)
    const { error: updateError } = await supabase.rpc('update_quiz_question', {
      target_question_id: question.id,
      question_prompt: editQuestionPrompt.trim(),
      question_type: editQuestionType,
      question_options: questionOptions,
      question_points: pointsValue,
      correct_answer: editQuestionCorrect.trim(),
    })
    setSaving(false)
    if (updateError) return setError(updateError.message)
    setEditingQuestionId(null)
    await load(false)
  }

  const publish = async (quiz: Quiz) => {
    const next = quiz.status === 'published' ? 'closed' : 'published'
    const { error: updateError } = await supabase.from('quizzes').update({ status: next }).eq('id', quiz.id)
    if (updateError) setError(updateError.message); else await load(false)
  }

  const beginEdit = (quiz: Quiz) => {
    setError(null)
    setEditingId(quiz.id)
    setEditTitle(quiz.title)
    setEditDescription(quiz.description ?? '')
    setEditStatus(quiz.status)
    setEditOpensAt(toLocalDateTimeInput(quiz.opens_at))
    setEditClosesAt(toLocalDateTimeInput(quiz.closes_at))
    setEditTimeLimit(quiz.time_limit_minutes?.toString() ?? '')
    setEditFileSubmissionPoints(String(quiz.file_submission_points))
    const standardExamType = examTypes.find((item) => item === quiz.exam_type)
    setEditExamType(standardExamType ?? 'Others')
    setEditCustomExamType(standardExamType ? '' : quiz.exam_type ?? '')
  }

  const cancelEdit = () => { setEditingId(null); setError(null) }

  const saveQuiz = async (event: FormEvent, quiz: Quiz) => {
    event.preventDefault(); setError(null)
    const limit = editTimeLimit.trim() ? Number(editTimeLimit) : null
    const filePoints = Number(editFileSubmissionPoints)
    const selectedExamType = editExamType === 'Others' ? editCustomExamType.trim() : editExamType
    if (!editTitle.trim()) return setError(`Enter an ${noun} title.`)
    if (isExam && !selectedExamType) return setError('Enter the custom exam type.')
    const openingChanged = editOpensAt !== toLocalDateTimeInput(quiz.opens_at)
    if (openingChanged && editOpensAt && new Date(editOpensAt).getTime() < Date.now()) return setError('Opening date and time must be the current time or a future time. Past dates are not allowed.')
    if (editOpensAt && editClosesAt && new Date(editClosesAt).getTime() <= new Date(editOpensAt).getTime()) return setError('Closing date must be after the opening date.')
    if (limit !== null && (!Number.isInteger(limit) || limit < 1)) return setError('Time limit must be a whole number of minutes.')
    if (!Number.isFinite(filePoints) || filePoints <= 0) return setError('File submission points must be greater than zero.')
    setSaving(true)
    const { error: updateError } = await supabase.from('quizzes').update({
      title: editTitle.trim(),
      description: editDescription.trim() || null,
      file_submission_points: filePoints,
      assessment_kind: assessmentKind,
      exam_type: isExam ? selectedExamType : null,
      opens_at: editOpensAt ? new Date(editOpensAt).toISOString() : null,
      closes_at: editClosesAt ? new Date(editClosesAt).toISOString() : null,
      time_limit_minutes: limit,
      status: editStatus,
    }).eq('id', quiz.id)
    setSaving(false)
    if (updateError) return setError(updateError.message)
    setEditingId(null)
    await load(false)
  }

  const remove = async (id: string) => {
    const quiz = quizzes.find((item) => item.id === id)
    if (!await confirm(destructiveActionConfirmation({ action: 'delete', item: quiz ? `the ${noun} “${quiz.title}”` : `this ${noun}`, detail: `The ${noun}, its questions, and all student attempts will be permanently deleted. This action cannot be undone.` }))) return
    const { error: deleteError } = await supabase.from('quizzes').delete().eq('id', id)
    if (deleteError) setError(deleteError.message); else { if (selected === id) setSelected(null); await load(false) }
  }

  const attachAssessmentFile = async (quiz: Quiz, file: File | null) => {
    if (!file) return
    setSaving(true); setError(null)
    const path = `${classId}/quiz-attachments/${quiz.id}/${crypto.randomUUID()}-${safeFileName(file.name)}`
    try {
      const { error: uploadError } = await supabase.storage.from('materials').upload(path, file)
      if (uploadError) throw uploadError
      const { error: saveError } = await supabase.rpc('set_quiz_attachment', { target_quiz_id: quiz.id, attachment_path: path, attachment_name: file.name })
      if (saveError) throw saveError
      await load(false)
    } catch (caught) {
      await supabase.storage.from('materials').remove([path])
      setError(messageFrom(caught))
    } finally {
      setSaving(false)
      if (attachmentInput.current) attachmentInput.current.value = ''
    }
  }

  const removeAssessmentAttachment = async (quiz: Quiz) => {
    if (!await confirm(destructiveActionConfirmation({ action: 'remove', item: `the attached file “${quiz.attachment_name ?? 'attachment'}”`, detail: `The file will be permanently removed from this ${noun}. This action cannot be undone.` }))) return
    setSaving(true); setError(null)
    const { error: removeError } = await supabase.rpc('set_quiz_attachment', { target_quiz_id: quiz.id, attachment_path: '', attachment_name: '' })
    setSaving(false)
    if (removeError) setError(removeError.message); else { setPreviewDocument(null); await load(false) }
  }

  const startQuiz = async (quiz: Quiz) => {
    setSaving(true); setError(null)
    const { error: startError } = await supabase.rpc('start_quiz', { target_quiz_id: quiz.id })
    setSaving(false)
    if (startError) setError(startError.message); else await load(false)
  }

  const submitQuiz = useCallback(async (quiz: Quiz) => {
    setSaving(true); setError(null)
    let uploadedPath = ''
    const quizAnswers: Record<string, string> = {}
    for (const question of questions[quiz.id] ?? []) quizAnswers[question.id] = answers[question.id] ?? ''
    try {
      const file = submissionFiles[quiz.id]
      if (file && profile) {
        uploadedPath = `${classId}/${profile.id}/quiz-attempts/${quiz.id}/${crypto.randomUUID()}-${safeFileName(file.name)}`
        const { error: uploadError } = await supabase.storage.from('submissions').upload(uploadedPath, file)
        if (uploadError) throw uploadError
      }
      const { error: submitError } = await supabase.rpc('submit_quiz', { target_quiz_id: quiz.id, submitted_answers: quizAnswers as Json, submission_file_path: uploadedPath, submission_file_name: file?.name ?? '' })
      if (submitError) throw submitError
      setSubmissionFiles((existing) => ({ ...existing, [quiz.id]: null }))
      autoSubmitting.current = null
      await load(false)
    } catch (caught) {
      if (uploadedPath) await supabase.storage.from('submissions').remove([uploadedPath])
      setError(messageFrom(caught))
    } finally { setSaving(false) }
  }, [answers, classId, load, profile, questions, submissionFiles])

  const removeSubmissionFile = async (attempt: Attempt) => {
    if (!await confirm(destructiveActionConfirmation({ action: 'remove', item: `your submitted file “${attempt.submission_file_name ?? 'submission'}”`, detail: `The file will be permanently removed from this ${noun}. This action cannot be undone.` }))) return
    setSaving(true); setError(null)
    const { error: removeError } = await supabase.rpc('remove_quiz_submission_file', { target_attempt_id: attempt.id })
    setSaving(false)
    if (removeError) setError(removeError.message); else { setPreviewDocument(null); await load(false) }
  }

  const current = quizzes.find((item) => item.id === selected)
  const currentAttempt = attempts.find((item) => item.quiz_id === selected && item.student_id === profile?.id)
  const currentAvailability = current ? quizAvailability(current, now) : null
  const currentClosed = currentAvailability?.label === 'closed'
  const remainingSeconds = current && currentAttempt?.status === 'in_progress' ? quizRemainingSeconds(current, currentAttempt, now) : null

  useEffect(() => {
    if (!current || currentAttempt?.status !== 'in_progress' || remainingSeconds === null || remainingSeconds > 0 || saving || autoSubmitting.current === current.id) return
    autoSubmitting.current = current.id
    void submitQuiz(current)
  }, [current, currentAttempt?.status, remainingSeconds, saving, submitQuiz])

  useEffect(() => {
    if (!canManage || !currentClosed || !current || !attempts.some((attempt) => attempt.quiz_id === current.id && attempt.status === 'in_progress')) return
    const timer = window.setTimeout(() => void load(false), 31_000)
    return () => window.clearTimeout(timer)
  }, [attempts, canManage, current, currentClosed, load])

  const cards = useMemo(() => quizzes.map((quiz) => {
    const attempt = attempts.find((item) => item.quiz_id === quiz.id && item.student_id === profile?.id)
    const availability = quizAvailability(quiz, now)
    return { quiz, attempt, availability }
  }), [attempts, now, profile?.id, quizzes])
  const minimumOpeningTime = now > 0 ? nextLocalMinute(now) : undefined

  return <section>
    <TabHeading title={plural} description={isExam ? 'Major class examinations with scheduling, timers, automatic scoring, and results.' : 'Online checks for understanding with automatic scoring.'} action={canManage && <button className={open ? 'button-secondary' : 'button-primary'} onClick={() => setOpen((value) => !value)}>{open ? <><X size={17} /> Cancel</> : <><Plus size={17} /> New {noun}</>}</button>} />
    {open && <form className="workspace-form mb-5" onSubmit={createQuiz}>
      <input className="form-input" placeholder={`${isExam ? 'Exam' : 'Quiz'} title`} value={title} onChange={(event) => setTitle(event.target.value)} />
      <textarea className="form-textarea" placeholder="Description or instructions" value={description} onChange={(event) => setDescription(event.target.value)} />
      {isExam && <ExamTypeField value={examType} customValue={customExamType} onChange={setExamType} onCustomChange={setCustomExamType} />}
      <div className="grid gap-3 md:grid-cols-2"><DateTimeField label="Opens at" value={opensAt} min={minimumOpeningTime} minimumError="Opening date and time must be the current time or a future time. Past dates are not allowed." onChange={setOpensAt} /><DateTimeField label="Closes at" value={closesAt} min={opensAt || undefined} minimumError="The closing date and time cannot be earlier than the opening date and time." onChange={setClosesAt} /></div>
      <div className="grid gap-3 md:grid-cols-3"><label className="text-sm font-semibold text-slate-700">Time limit (minutes)<input className="form-input mt-1" type="number" min="1" step="1" placeholder="No time limit" value={timeLimit} onChange={(event) => setTimeLimit(event.target.value)} /></label><label className="text-sm font-semibold text-slate-700">File submission points<input className="form-input mt-1" type="number" min="0.1" step="0.1" value={fileSubmissionPoints} onChange={(event) => setFileSubmissionPoints(event.target.value)} /></label><label className="text-sm font-semibold text-slate-700">Initial status<select className="form-select mt-1" value={status} onChange={(event) => setStatus(event.target.value as PublishStatus)}><option value="draft">Draft</option><option value="published">Published</option></select></label></div>
      <p className="text-xs text-slate-500">The timer begins when a student clicks Start {noun}. The closing time still ends access even when time remains.</p>
      <div className="flex justify-end gap-2"><button type="button" className="button-secondary" onClick={() => setOpen(false)}>Cancel</button><button className="button-primary" disabled={saving}>{saving ? 'Creating…' : `Create ${noun}`}</button></div>
    </form>}
    {loading && <LoadingState label={`Loading ${noun}s…`} />}
    {error && <ErrorState message={error} onRetry={() => void load()} />}
    {!loading && !error && quizzes.length === 0 && <EmptyState title={`No ${noun}s yet`} description={canManage ? `Create the first ${noun} for this class.` : `No ${noun}s have been assigned.`} />}
    {!loading && quizzes.length > 0 && <div className="content-sized-selector-layout grid gap-4">
      <div className="content-sized-selector-list">{cards.map(({ quiz, attempt, availability }) => <button type="button" className={`discussion-topic ${selected === quiz.id ? 'discussion-topic-active' : ''} ${isUnread(classId, notificationSection, quiz.id) ? 'notification-content-unread' : ''}`} key={quiz.id} onClick={() => { setSelected(quiz.id); setQuestionFormOpen(false); markItemViewed(classId, notificationSection, quiz.id) }}><div className="flex min-w-0 items-center gap-2"><CircleHelp className="shrink-0" size={16} /><strong className="truncate">{quiz.title}</strong></div><span>{attempt?.status === 'submitted' ? 'submitted' : availability.label} · {(questions[quiz.id] ?? []).length} questions</span>{!availability.available && <span>{availability.reason}</span>}</button>)}</div>
      <div className="classroom-outline rounded-2xl border border-slate-200 bg-white p-4 sm:p-5">
        {!current ? <EmptyState title={`Select an ${noun}`} description={`Choose an available ${noun} to view its details.`} /> : <>
          <div className="flex flex-wrap items-start justify-between gap-3"><div><div className="flex flex-wrap items-center gap-2"><h3 className="text-xl font-black text-slate-900">{current.title}</h3>{isExam && <span className="status-pill status-pill-active">{current.exam_type}</span>}</div>{current.description && <p className="mt-1 text-sm text-slate-600">{current.description}</p>}<p className="mt-2 text-xs text-slate-400">{current.status} · Opens {formatDate(current.opens_at)} · Closes {formatDate(current.closes_at)} · {current.time_limit_minutes ? `${current.time_limit_minutes} minute limit` : 'No time limit'}</p></div>{canManage && <div className="flex gap-2"><button className="button-secondary" onClick={() => void publish(current)}>{current.status === 'published' ? 'Close' : 'Publish'}</button><button className="icon-action text-brand-700" title={editingId === current.id ? 'Cancel editing' : `Edit ${noun}`} onClick={() => editingId === current.id ? cancelEdit() : beginEdit(current)}>{editingId === current.id ? <X size={17} /> : <Pencil size={17} />}</button><button className="icon-action text-red-600" title={`Delete ${noun}`} onClick={() => void remove(current.id)}><Trash2 size={17} /></button></div>}</div>
          {current.attachment_path && current.attachment_name && <div className="my-4 rounded-xl border border-blue-100 bg-blue-50 p-4"><p className="text-xs font-extrabold uppercase tracking-wide text-brand-700">Attached {noun} file</p><p className="mt-1 break-words text-sm font-bold text-slate-800">{current.attachment_name}</p><div className="mt-3 flex flex-wrap gap-2"><button type="button" className="button-secondary" onClick={() => setPreviewDocument({ bucket: 'materials', path: current.attachment_path!, name: current.attachment_name! })}><Eye size={16} /> Preview</button>{canManage && <button type="button" className="button-secondary text-red-600" disabled={saving} onClick={() => void removeAssessmentAttachment(current)}><Trash2 size={16} /> Remove</button>}</div></div>}
          {canManage && editingId === current.id && <form className="workspace-form my-4" onSubmit={(event) => void saveQuiz(event, current)}>
            <h4 className="font-extrabold text-slate-800">Edit {noun}</h4>
            <input className="form-input" placeholder={`${isExam ? 'Exam' : 'Quiz'} title`} value={editTitle} onChange={(event) => setEditTitle(event.target.value)} />
            <textarea className="form-textarea" placeholder="Description or instructions" value={editDescription} onChange={(event) => setEditDescription(event.target.value)} />
            {isExam && <ExamTypeField value={editExamType} customValue={editCustomExamType} onChange={setEditExamType} onCustomChange={setEditCustomExamType} />}
            <div className="grid gap-3 md:grid-cols-2"><DateTimeField label="Opens at" value={editOpensAt} min={minimumOpeningTime} allowCurrentBeforeMin minimumError="Opening date and time must be the current time or a future time. Past dates are not allowed." onChange={setEditOpensAt} /><DateTimeField label="Closes at" value={editClosesAt} min={editOpensAt || undefined} minimumError="The closing date and time cannot be earlier than the opening date and time." onChange={setEditClosesAt} /></div>
            <div className="grid gap-3 md:grid-cols-3"><label className="text-sm font-semibold text-slate-700">Time limit (minutes)<input className="form-input mt-1" type="number" min="1" step="1" placeholder="No time limit" value={editTimeLimit} onChange={(event) => setEditTimeLimit(event.target.value)} /></label><label className="text-sm font-semibold text-slate-700">File submission points<input className="form-input mt-1" type="number" min="0.1" step="0.1" value={editFileSubmissionPoints} onChange={(event) => setEditFileSubmissionPoints(event.target.value)} /></label><label className="text-sm font-semibold text-slate-700">Status<select className="form-select mt-1" value={editStatus} onChange={(event) => setEditStatus(event.target.value as PublishStatus)}><option value="draft">Draft</option><option value="published">Published</option><option value="closed">Closed</option></select></label></div>
            <div className="flex justify-end gap-2"><button type="button" className="button-secondary" onClick={cancelEdit}>Cancel</button><button className="button-primary" disabled={saving}>{saving ? 'Saving…' : 'Save changes'}</button></div>
          </form>}
          {isStudent && !currentAttempt && <div className="my-5 rounded-xl border border-slate-200 bg-slate-50 p-5 text-center"><Clock3 className="mx-auto text-brand-600" /><p className="mt-2 font-bold text-slate-800">{currentAvailability?.available ? 'Ready to begin?' : currentAvailability?.reason}</p><p className="mt-1 text-sm text-slate-500">{current.time_limit_minutes ? `You will have ${current.time_limit_minutes} minutes after starting.` : `This ${noun} has no countdown time limit.`}</p><button className="button-primary mt-4" disabled={saving || !currentAvailability?.available} onClick={() => void startQuiz(current)}>{saving ? 'Starting…' : `Start ${noun}`}</button></div>}
          {isStudent && currentAttempt?.status === 'in_progress' && remainingSeconds !== null && <div className={`my-4 flex items-center justify-between rounded-xl px-4 py-3 font-bold ${remainingSeconds <= 60 ? 'bg-red-50 text-red-700' : 'bg-blue-50 text-blue-800'}`}><span>Time remaining</span><span>{formatDuration(remainingSeconds)}</span></div>}
          {(!isStudent || currentAttempt?.status === 'in_progress') && <div className="my-4 space-y-4">{(questions[current.id] ?? []).map((question, index) => <article className="rounded-xl bg-slate-50 p-4" key={question.id}>
            <div className="flex items-start justify-between gap-3"><p className="font-bold text-slate-800">{index + 1}. {question.prompt} <span className="text-xs text-slate-400">({question.points} pts)</span></p>{canManage && !currentClosed && <button type="button" className="icon-action text-brand-700" title={`Edit question ${index + 1}`} aria-label={`Edit question ${index + 1}`} onClick={() => editingQuestionId === question.id ? cancelQuestionEdit() : beginQuestionEdit(question)}>{editingQuestionId === question.id ? <X size={17} /> : <Pencil size={17} />}</button>}</div>
            {canManage && editingQuestionId === question.id && <QuestionEditForm question={question} questionNumber={index + 1} prompt={editQuestionPrompt} type={editQuestionType} options={editQuestionOptions} correct={editQuestionCorrect} points={editQuestionPoints} saving={saving} onPromptChange={setEditQuestionPrompt} onTypeChange={setEditQuestionType} onOptionsChange={setEditQuestionOptions} onCorrectChange={setEditQuestionCorrect} onPointsChange={setEditQuestionPoints} onCancel={cancelQuestionEdit} onSubmit={saveQuestion} />}
            {isStudent && <QuestionInput question={question} value={answers[question.id] ?? ''} onChange={(value) => setAnswers((existing) => ({ ...existing, [question.id]: value }))} />}
          </article>)}</div>}
          {canManage ? currentClosed ? <QuizResults quiz={current} questions={questions[current.id] ?? []} attempts={attempts} students={students} onGraded={() => load(false)} onPreview={setPreviewDocument} /> : <div className="space-y-4"><div className="flex flex-wrap gap-2"><button type="button" className="button-primary" onClick={() => setQuestionFormOpen(true)}><Plus size={17} /> Add Question</button><button type="button" className="button-secondary" disabled={saving} onClick={() => attachmentInput.current?.click()}><FileUp size={17} /> {current.attachment_path ? 'Replace File' : 'Attach File'}</button><input ref={attachmentInput} className="hidden" type="file" onChange={(event) => void attachAssessmentFile(current, event.target.files?.[0] ?? null)} /></div>{questionFormOpen && <form className="workspace-form" onSubmit={addQuestion}><h4 className="font-extrabold text-slate-800">Add question</h4><input className="form-input" placeholder="Question prompt" value={prompt} onChange={(event) => setPrompt(event.target.value)} /><div className="grid gap-3 sm:grid-cols-3"><select className="form-select" value={questionType} onChange={(event) => setQuestionType(event.target.value as QuestionType)}><option value="multiple_choice">Multiple choice</option><option value="true_false">True / false</option><option value="identification">Identification</option><option value="essay">Essay</option></select><input className="form-input" type="number" min="0.1" step="0.1" value={questionPoints} onChange={(event) => setQuestionPoints(event.target.value)} placeholder="Points" />{questionType === 'true_false' ? <select className="form-select" value={correct} onChange={(event) => setCorrect(event.target.value)}><option value="">Select correct answer</option><option value="True">True</option><option value="False">False</option></select> : <input className="form-input" placeholder={questionType === 'essay' ? 'Correct answer (optional)' : 'Correct answer'} value={correct} onChange={(event) => setCorrect(event.target.value)} />}</div>{questionType === 'multiple_choice' && <input className="form-input" placeholder="Options separated by commas" value={options} onChange={(event) => setOptions(event.target.value)} />}{questionType === 'essay' && <p className="text-xs text-slate-500">Essay questions require manual grading. The instructor can award any score from 0 to the question point value.</p>}<div className="flex justify-end gap-2"><button type="button" className="button-secondary" onClick={() => { setQuestionFormOpen(false); setError(null) }}>Cancel</button><button className="button-primary" disabled={saving}>Add question</button></div></form>}</div> : isStudent && currentAttempt?.status === 'submitted' ? <div className="rounded-xl bg-slate-50 p-5"><ScoreBar earned={currentAttempt.score} possible={currentAttempt.max_score} label={`${isExam ? 'Exam' : 'Quiz'} score`} />{(questions[current.id] ?? []).some((question) => question.question_type === 'essay' && !hasEssayGrade(currentAttempt, question.id)) && <p className="mt-3 rounded-lg bg-amber-50 px-3 py-2 text-sm font-semibold text-amber-800">Essay response is awaiting instructor grading. Your score may still change.</p>}<p className="mt-3 text-sm text-slate-600">Submitted {formatDate(currentAttempt.submitted_at)}</p>{currentAttempt.submission_file_path && currentAttempt.submission_file_name && <div className="mt-4 rounded-xl border border-slate-200 bg-white p-3"><p className="break-words text-sm font-bold text-slate-800">{currentAttempt.submission_file_name}</p><div className="mt-3 flex flex-wrap gap-2"><button type="button" className="button-secondary" onClick={() => setPreviewDocument({ bucket: 'submissions', path: currentAttempt.submission_file_path!, name: currentAttempt.submission_file_name! })}><Eye size={16} /> Preview</button><button type="button" className="button-secondary text-red-600" disabled={saving} onClick={() => void removeSubmissionFile(currentAttempt)}><Trash2 size={16} /> Remove</button></div></div>}</div> : isStudent && currentAttempt?.status === 'in_progress' ? <div className="space-y-3"><label className="file-picker"><FileUp size={18} /><span>{submissionFiles[current.id]?.name ?? `Attach your ${noun} answer file (optional)`}</span><input type="file" onChange={(event) => setSubmissionFiles((existing) => ({ ...existing, [current.id]: event.target.files?.[0] ?? null }))} /></label><p className="text-xs text-slate-500">Any file type is accepted; maximum 10 MB. Browser-supported formats can be viewed in the LMS, while other formats can be downloaded.</p><button className="button-primary w-full" disabled={saving || (!(questions[current.id]?.length) && !submissionFiles[current.id])} onClick={() => void submitQuiz(current)}>{saving ? 'Submitting…' : `Submit ${noun}`}</button></div> : !isStudent && <div className="rounded-xl bg-slate-50 p-4 text-sm text-slate-600">{isExam ? 'Exam' : 'Quiz'} content is available for administrative review. Attempts and scores appear after students submit.</div>}
        </>}
      </div>
    </div>}
    <DocumentPreviewModal document={previewDocument} onClose={() => setPreviewDocument(null)} />
  </section>
}

function quizAvailability(quiz: Quiz, now: number) {
  const noun = quiz.assessment_kind === 'exam' ? 'exam' : 'quiz'
  if (quiz.status === 'draft') return { available: false, label: 'draft', reason: `This ${noun} has not been published.` }
  if (quiz.status === 'closed') return { available: false, label: 'closed', reason: `This ${noun} is closed.` }
  if (quiz.opens_at && new Date(quiz.opens_at).getTime() > now) return { available: false, label: 'scheduled', reason: `Opens ${formatDate(quiz.opens_at)}.` }
  if (quiz.closes_at && new Date(quiz.closes_at).getTime() <= now) return { available: false, label: 'closed', reason: `Closed ${formatDate(quiz.closes_at)}.` }
  return { available: true, label: 'open', reason: `${noun === 'exam' ? 'Exam' : 'Quiz'} is available.` }
}

function quizRemainingSeconds(quiz: Quiz, attempt: Attempt, now: number) {
  const deadlines: number[] = []
  if (quiz.time_limit_minutes) deadlines.push(new Date(attempt.started_at).getTime() + quiz.time_limit_minutes * 60_000)
  if (quiz.closes_at) deadlines.push(new Date(quiz.closes_at).getTime())
  if (!deadlines.length) return null
  return Math.max(0, Math.ceil((Math.min(...deadlines) - now) / 1000))
}

function formatDuration(seconds: number) {
  const hours = Math.floor(seconds / 3600), minutes = Math.floor((seconds % 3600) / 60), remainder = seconds % 60
  return hours > 0 ? `${hours}:${String(minutes).padStart(2, '0')}:${String(remainder).padStart(2, '0')}` : `${minutes}:${String(remainder).padStart(2, '0')}`
}

function toLocalDateTimeInput(value: string | null) {
  if (!value) return ''
  const date = new Date(value)
  const offset = date.getTimezoneOffset() * 60_000
  return new Date(date.getTime() - offset).toISOString().slice(0, 16)
}

function nextLocalMinute(timestamp: number) {
  const date = new Date(timestamp)
  date.setSeconds(0, 0)
  if (date.getTime() < timestamp) date.setMinutes(date.getMinutes() + 1)
  const offset = date.getTimezoneOffset() * 60_000
  return new Date(date.getTime() - offset).toISOString().slice(0, 16)
}

function ExamTypeField({ value, customValue, onChange, onCustomChange }: { value: string; customValue: string; onChange: (value: string) => void; onCustomChange: (value: string) => void }) {
  return <div className="grid gap-3 md:grid-cols-2">
    <label className="text-sm font-semibold text-slate-700">Exam type
      <select className="form-select mt-1" value={value} onChange={(event) => onChange(event.target.value)}>
        {examTypes.map((type) => <option key={type} value={type}>{type}</option>)}
        <option value="Others">Others</option>
      </select>
    </label>
    {value === 'Others' && <label className="text-sm font-semibold text-slate-700">Custom exam type
      <input className="form-input mt-1" maxLength={100} value={customValue} onChange={(event) => onCustomChange(event.target.value)} placeholder="Enter exam type" />
    </label>}
  </div>
}

function QuizResults({ quiz, questions, attempts, students, onGraded, onPreview }: { quiz: Quiz; questions: ManagedQuestion[]; attempts: Attempt[]; students: Student[]; onGraded: () => Promise<void>; onPreview: (document: PreviewDocument) => void }) {
  const quizAttempts = attempts.filter((attempt) => attempt.quiz_id === quiz.id)
  const attemptsByStudent = new Map(quizAttempts.map((attempt) => [attempt.student_id, attempt]))
  const submitted = quizAttempts.filter((attempt) => attempt.status === 'submitted')
  const average = submitted.length ? submitted.reduce((sum, attempt) => sum + (Number(attempt.max_score) > 0 ? Number(attempt.score ?? 0) / Number(attempt.max_score) * 100 : 0), 0) / submitted.length : 0

  return <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
    <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-200 px-4 py-4 sm:px-5">
      <div><h4 className="font-extrabold text-slate-900">Student scores</h4><p className="mt-1 text-xs text-slate-500">{submitted.length} submitted · {students.length} enrolled</p></div>
      <span className="rounded-full bg-blue-50 px-3 py-1.5 text-xs font-extrabold text-brand-700">Class average: {average.toFixed(1)}%</span>
    </div>
    {students.length > 0 ? <div className="overflow-x-auto"><table className="admin-table"><thead><tr><th>Student</th><th>Score</th><th>Status</th><th>Submitted</th></tr></thead><tbody>{students.map((student) => {
      const attempt = attemptsByStudent.get(student.id)
      return <tr key={student.id}>
        <td data-label="Student"><div className="flex min-w-44 items-center gap-3"><ProfileAvatar name={student.full_name} avatarPath={student.avatar_path} className="size-10 text-xs" /><div><p className="font-bold text-slate-800">{student.full_name}</p><p className="text-xs text-slate-400">{student.school_id}</p></div></div></td>
        <td data-label="Score">{attempt?.status === 'submitted' ? <div className="min-w-52 space-y-3"><ScoreBar earned={attempt.score} possible={attempt.max_score} label="Score" compact />{attempt.submission_file_path && attempt.submission_file_name && <><button type="button" className="button-secondary" onClick={() => onPreview({ bucket: 'submissions', path: attempt.submission_file_path!, name: attempt.submission_file_name! })}><Eye size={16} /> Preview</button><FileGradeControl attempt={attempt} maximum={quiz.file_submission_points} onGraded={onGraded} /></>}{questions.filter((question) => question.question_type === 'essay').map((question) => <EssayGradeControl key={question.id} attempt={attempt} question={question} onGraded={onGraded} />)}</div> : <span className="text-sm font-semibold text-slate-400">—</span>}</td>
        <td data-label="Status"><span className={`status-pill ${attempt?.status === 'submitted' ? 'status-pill-active' : 'status-pill-inactive'}`}>{attempt?.status === 'submitted' ? 'Submitted' : attempt ? 'Finalizing' : 'Not attempted'}</span></td>
        <td data-label="Submitted" className="text-sm text-slate-500">{attempt?.submitted_at ? formatDate(attempt.submitted_at) : '—'}</td>
      </tr>
    })}</tbody></table></div> : <div className="p-4 sm:p-6"><EmptyState title="No enrolled students" description="Scores will appear after enrollment data is available." /></div>}
  </section>
}

function FileGradeControl({ attempt, maximum, onGraded }: { attempt: Attempt; maximum: number; onGraded: () => Promise<void> }) {
  const [points, setPoints] = useState(attempt.submission_file_score === null ? '' : String(attempt.submission_file_score))
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const save = async () => {
    const awarded = Number(points)
    if (!Number.isFinite(awarded) || awarded < 0 || awarded > Number(maximum)) return setError(`Enter 0 to ${maximum} points.`)
    setSaving(true); setError(null)
    const { error: gradeError } = await supabase.rpc('grade_quiz_file', { target_attempt_id: attempt.id, awarded_points: awarded })
    setSaving(false)
    if (gradeError) return setError(gradeError.message)
    await onGraded()
  }

  return <div className="rounded-lg border border-slate-200 bg-slate-50 p-3 text-left">
    <p className="text-xs font-extrabold text-slate-700">Submitted file score</p>
    <div className="mt-3 flex items-center gap-2"><input className="form-input min-w-0" type="number" min="0" max={maximum} step="0.1" value={points} onChange={(event) => setPoints(event.target.value)} placeholder="Score" /><span className="shrink-0 text-xs font-bold text-slate-500">/ {maximum}</span><button type="button" className="button-secondary shrink-0" disabled={saving} onClick={() => void save()}>{saving ? 'Saving…' : 'Save'}</button></div>
    {error && <p className="mt-2 text-xs font-semibold text-red-600">{error}</p>}
  </div>
}

function EssayGradeControl({ attempt, question, onGraded }: { attempt: Attempt; question: ManagedQuestion; onGraded: () => Promise<void> }) {
  const answers = jsonRecord(attempt.answers)
  const essayScores = jsonRecord(attempt.essay_scores)
  const [points, setPoints] = useState(String(essayScores[question.id] ?? ''))
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const save = async () => {
    const awarded = Number(points)
    if (!Number.isFinite(awarded) || awarded < 0 || awarded > Number(question.points)) return setError(`Enter 0 to ${question.points} points.`)
    setSaving(true); setError(null)
    const { error: gradeError } = await supabase.rpc('grade_quiz_essay', { target_attempt_id: attempt.id, target_question_id: question.id, awarded_points: awarded })
    setSaving(false)
    if (gradeError) return setError(gradeError.message)
    await onGraded()
  }

  return <div className="rounded-lg border border-slate-200 bg-slate-50 p-3 text-left">
    <p className="text-xs font-extrabold text-slate-700">Essay: {question.prompt}</p>
    <p className="mt-2 whitespace-pre-wrap text-sm text-slate-600">{String(answers[question.id] ?? '').trim() || 'No response'}</p>
    <div className="mt-3 flex items-center gap-2"><input className="form-input min-w-0" type="number" min="0" max={question.points} step="0.1" value={points} onChange={(event) => setPoints(event.target.value)} placeholder="Score" /><span className="shrink-0 text-xs font-bold text-slate-500">/ {question.points}</span><button type="button" className="button-secondary shrink-0" disabled={saving} onClick={() => void save()}>{saving ? 'Saving…' : 'Save'}</button></div>
    {error && <p className="mt-2 text-xs font-semibold text-red-600">{error}</p>}
  </div>
}

function jsonRecord(value: Json): Record<string, Json> {
  return value && typeof value === 'object' && !Array.isArray(value) ? value as Record<string, Json> : {}
}

function hasEssayGrade(attempt: Attempt, questionId: string) {
  return Object.prototype.hasOwnProperty.call(jsonRecord(attempt.essay_scores), questionId)
}

function normalizeStudent(value: unknown): Student | null {
  const relation = (value as { student: Student | Student[] | null }).student
  return Array.isArray(relation) ? relation[0] ?? null : relation
}

function QuestionEditForm({ question, questionNumber, prompt, type, options, correct, points, saving, onPromptChange, onTypeChange, onOptionsChange, onCorrectChange, onPointsChange, onCancel, onSubmit }: {
  question: ManagedQuestion
  questionNumber: number
  prompt: string
  type: QuestionType
  options: string
  correct: string
  points: string
  saving: boolean
  onPromptChange: (value: string) => void
  onTypeChange: (value: QuestionType) => void
  onOptionsChange: (value: string) => void
  onCorrectChange: (value: string) => void
  onPointsChange: (value: string) => void
  onCancel: () => void
  onSubmit: (event: FormEvent, question: ManagedQuestion) => Promise<void>
}) {
  return <form className="workspace-form mt-4" onSubmit={(event) => void onSubmit(event, question)}>
    <h4 className="font-extrabold text-slate-800">Edit question {questionNumber}</h4>
    <textarea className="form-textarea" placeholder="Question prompt" value={prompt} onChange={(event) => onPromptChange(event.target.value)} />
    <div className="grid gap-3 sm:grid-cols-3">
      <label className="field-label">Question type<select className="form-select" value={type} onChange={(event) => onTypeChange(event.target.value as QuestionType)}><option value="multiple_choice">Multiple choice</option><option value="true_false">True / false</option><option value="identification">Identification</option><option value="essay">Essay</option></select></label>
      <label className="field-label">Points<input className="form-input" type="number" min="0.1" step="0.1" value={points} onChange={(event) => onPointsChange(event.target.value)} /></label>
      {type === 'true_false' ? <label className="field-label">Correct answer<select className="form-select" value={correct} onChange={(event) => onCorrectChange(event.target.value)}><option value="">Select answer</option><option value="True">True</option><option value="False">False</option></select></label> : <label className="field-label">{type === 'essay' ? 'Correct answer (optional)' : 'Correct answer'}<input className="form-input" value={correct} onChange={(event) => onCorrectChange(event.target.value)} placeholder={type === 'essay' ? 'Optional grading reference' : 'Correct answer'} /></label>}
    </div>
    {type === 'multiple_choice' && <label className="field-label">Choices<input className="form-input" value={options} onChange={(event) => onOptionsChange(event.target.value)} placeholder="Choices separated by commas" /></label>}
    {type === 'essay' && <p className="text-sm text-slate-500">Essay responses are manually graded from 0 to {points || 'the configured'} points.</p>}
    <div className="flex justify-end gap-2"><button type="button" className="button-secondary" onClick={onCancel}>Cancel</button><button className="button-primary" disabled={saving}>{saving ? 'Saving…' : 'Save question'}</button></div>
  </form>
}

function QuestionInput({ question, value, onChange }: { question: Question; value: string; onChange: (value: string) => void }) {
  const options = Array.isArray(question.options) ? question.options.map(String) : []
  if (question.question_type === 'essay') return <textarea className="form-textarea mt-3 min-h-40" value={value} onChange={(event) => onChange(event.target.value)} placeholder="Write your essay response" />
  if (question.question_type === 'identification') return <input className="form-input mt-3" value={value} onChange={(event) => onChange(event.target.value)} placeholder="Your answer" />
  return <div className="mt-3 space-y-2">{options.map((option) => <label className="flex items-center gap-2 text-sm text-slate-700" key={option}><input type="radio" name={question.id} value={option} checked={value === option} onChange={() => onChange(option)} /> {option}</label>)}</div>
}

function groupQuestions(rows: ManagedQuestion[]) { return rows.reduce<Record<string, ManagedQuestion[]>>((grouped, item) => { (grouped[item.quiz_id] ??= []).push(item); return grouped }, {}) }