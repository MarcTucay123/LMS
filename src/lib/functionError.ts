export async function getFunctionErrorMessage(error: { message: string; context?: unknown }, fallback: string) {
  if (error.context instanceof Response) {
    const body = await error.context.clone().json().catch(() => null) as { error?: string } | null
    if (body?.error) return body.error
    if (error.context.status === 404) return fallback
  }

  const message = error.message.toLowerCase()
  if (message.includes('failed to send a request') || message.includes('failed to fetch') || message.includes('network')) return fallback
  return error.message
}