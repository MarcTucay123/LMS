import { createContext } from 'react'

export interface ConfirmationOptions {
  title: string
  message: string
  confirmLabel?: string
  cancelLabel?: string
  tone?: 'danger' | 'warning' | 'neutral'
  icon?: 'delete' | 'logout' | 'warning' | 'question'
}

export interface ConfirmationContextValue {
  confirm: (options: ConfirmationOptions) => Promise<boolean>
}

export const ConfirmationContext = createContext<ConfirmationContextValue | null>(null)