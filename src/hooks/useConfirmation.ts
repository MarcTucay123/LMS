import { useContext } from 'react'
import { ConfirmationContext } from '../contexts/ConfirmationDialogContext'

export function useConfirmation() {
  const value = useContext(ConfirmationContext)
  if (!value) throw new Error('useConfirmation must be used inside ConfirmationDialogProvider.')
  return value
}