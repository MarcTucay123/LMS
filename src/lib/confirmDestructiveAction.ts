import type { ConfirmationOptions } from '../contexts/ConfirmationDialogContext'

interface DestructiveActionConfirmation {
  action: 'delete' | 'remove'
  item: string
  detail?: string
}

export function destructiveActionConfirmation({ action, item, detail }: DestructiveActionConfirmation): ConfirmationOptions {
  const verb = action === 'delete' ? 'Delete' : 'Remove'
  return {
    title: `${verb} ${item}?`,
    message: detail ?? 'This action cannot be undone.',
    confirmLabel: verb,
    tone: 'danger',
    icon: 'delete',
  }
}