import type { ClassScheduleMeeting } from '../types/database'

function formatTime(value: string) {
  const [hourText, minute = '00'] = value.split(':')
  const hour = Number(hourText)
  if (!Number.isFinite(hour)) return value
  const period = hour >= 12 ? 'PM' : 'AM'
  const displayHour = hour % 12 || 12
  return `${displayHour}:${minute} ${period}`
}

export function formatScheduleMeeting(meeting: ClassScheduleMeeting) {
  return `${meeting.day_of_week} · ${formatTime(meeting.start_time)}–${formatTime(meeting.end_time)}`
}

export function scheduleRoomLabel(meeting: ClassScheduleMeeting) {
  return `${meeting.room_code} · ${meeting.class_type}`
}