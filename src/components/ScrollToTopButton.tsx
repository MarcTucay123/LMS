import { useEffect, useState } from 'react'
import { ArrowUp } from 'lucide-react'

const visibilityThreshold = 300

export function ScrollToTopButton() {
  const [visible, setVisible] = useState(() => window.scrollY > visibilityThreshold)

  useEffect(() => {
    const updateVisibility = () => setVisible(window.scrollY > visibilityThreshold)
    window.addEventListener('scroll', updateVisibility, { passive: true })
    updateVisibility()
    return () => window.removeEventListener('scroll', updateVisibility)
  }, [])

  const scrollToTop = () => {
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    window.scrollTo({ top: 0, behavior: reduceMotion ? 'auto' : 'smooth' })
  }

  return (
    <button
      type="button"
      className={`print-hidden fixed bottom-5 right-4 z-[60] grid size-12 place-items-center rounded-full border border-blue-300 bg-brand-700 text-white shadow-lg shadow-blue-950/25 transition duration-200 hover:-translate-y-0.5 hover:bg-brand-800 focus-visible:translate-y-0 sm:bottom-6 sm:right-6 ${visible ? 'translate-y-0 opacity-100' : 'pointer-events-none translate-y-3 opacity-0'}`}
      onClick={scrollToTop}
      aria-label="Scroll to top"
      title="Back to top"
      aria-hidden={!visible}
      tabIndex={visible ? 0 : -1}
    >
      <ArrowUp size={22} strokeWidth={2.5} aria-hidden="true" />
    </button>
  )
}