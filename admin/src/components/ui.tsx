import { useEffect, useRef, useState, type ButtonHTMLAttributes, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { Loader2, X } from 'lucide-react'

const cx = (...c: (string | false | null | undefined)[]) => c.filter(Boolean).join(' ')
export { cx }

type Variant = 'primary' | 'ghost' | 'danger' | 'soft'

export function Button({
  variant = 'primary',
  loading,
  icon,
  className,
  children,
  ...rest
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant; loading?: boolean; icon?: ReactNode }) {
  const styles: Record<Variant, string> = {
    primary:
      'brand-gradient text-white shadow-lg shadow-blue-600/20 hover:shadow-blue-600/35 hover:brightness-110',
    soft: 'bg-brand-sky text-brand dark:bg-blue-500/15 dark:text-blue-300 hover:brightness-95',
    ghost: 'border border-line bg-card text-ink-2 hover:bg-card-2 hover:text-ink',
    danger: 'bg-red-600 text-white shadow-lg shadow-red-600/20 hover:bg-red-700',
  }
  return (
    <button
      {...rest}
      disabled={rest.disabled || loading}
      className={cx(
        'focus-ring inline-flex h-10 items-center justify-center gap-2 whitespace-nowrap rounded-xl px-4 text-sm font-bold transition active:scale-[.97] disabled:cursor-not-allowed disabled:opacity-60',
        styles[variant],
        className,
      )}
    >
      {loading ? <Loader2 className="size-4 animate-spin" /> : icon}
      {children}
    </button>
  )
}

export function IconButton({
  label,
  className,
  children,
  ...rest
}: ButtonHTMLAttributes<HTMLButtonElement> & { label: string }) {
  return (
    <button
      {...rest}
      title={label}
      aria-label={label}
      className={cx(
        'focus-ring grid size-9 place-items-center rounded-xl text-ink-2 transition hover:bg-card-2 hover:text-ink active:scale-95',
        className,
      )}
    >
      {children}
    </button>
  )
}

const avatarColors = ['#1565c0', '#00897b', '#5e35b1', '#d81b60', '#ef6c00', '#00838f', '#3949ab', '#43a047']

/** The record's image, or its first letter on a colored tile. */
export function Avatar({ src, name, size = 40, round }: { src?: string | null; name: string; size?: number; round?: boolean }) {
  const letter = name.replace(/^د\.\s*/, '').trim().charAt(0) || '؟'
  const color = avatarColors[[...name].reduce((s, c) => s + c.charCodeAt(0), 0) % avatarColors.length]
  // Broken links fall back to the letter tile.
  const [failed, setFailed] = useState<string | null>(null)
  return (
    <div
      className={cx('relative shrink-0 overflow-hidden', round ? 'rounded-full' : 'rounded-xl')}
      style={{ width: size, height: size }}
    >
      {src && failed !== src ? (
        <img src={src} alt="" loading="lazy" className="size-full object-cover" onError={() => setFailed(src)} />
      ) : (
        <div
          className="grid size-full place-items-center font-black text-white"
          style={{ background: `linear-gradient(135deg, ${color}, ${color}bb)`, fontSize: size * 0.42 }}
        >
          {letter}
        </div>
      )}
    </div>
  )
}

export function Spinner({ className }: { className?: string }) {
  return <Loader2 className={cx('animate-spin text-brand', className ?? 'size-6')} />
}

/** Locks page scroll and closes on Escape while open. */
function useOverlay(open: boolean, onClose: () => void) {
  const close = useRef(onClose)
  close.current = onClose
  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && close.current()
    window.addEventListener('keydown', onKey)
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      window.removeEventListener('keydown', onKey)
      document.body.style.overflow = prev
    }
  }, [open])
}

export function Drawer({
  open,
  onClose,
  title,
  subtitle,
  icon,
  footer,
  children,
}: {
  open: boolean
  onClose: () => void
  title: string
  subtitle?: string
  icon?: ReactNode
  footer?: ReactNode
  children: ReactNode
}) {
  useOverlay(open, onClose)
  if (!open) return null
  return createPortal(
    <div className="fixed inset-0 z-50">
      <div className="animate-fade absolute inset-0 bg-slate-950/40 backdrop-blur-[2px]" onClick={onClose} />
      <aside
        role="dialog"
        aria-modal="true"
        aria-label={title}
        className="animate-slide-in absolute inset-y-0 left-0 flex w-full max-w-2xl flex-col bg-card shadow-2xl"
      >
        <header className="flex items-center gap-3 border-b border-line px-6 py-4">
          {icon}
          <div className="min-w-0 flex-1">
            <h2 className="truncate text-lg font-black">{title}</h2>
            {subtitle && <p className="truncate text-xs text-muted">{subtitle}</p>}
          </div>
          <IconButton label="إغلاق (Esc)" onClick={onClose}>
            <X className="size-5" />
          </IconButton>
        </header>
        <div className="flex-1 overflow-y-auto px-6 py-5">{children}</div>
        {footer && <footer className="border-t border-line bg-card-2 px-6 py-3">{footer}</footer>}
      </aside>
    </div>,
    document.body,
  )
}

export function Modal({
  open,
  onClose,
  children,
  className,
}: {
  open: boolean
  onClose: () => void
  children: ReactNode
  className?: string
}) {
  useOverlay(open, onClose)
  if (!open) return null
  return createPortal(
    <div className="fixed inset-0 z-[60] grid place-items-start justify-items-center overflow-y-auto p-4 pt-[12vh]">
      <div className="animate-fade fixed inset-0 bg-slate-950/45 backdrop-blur-[2px]" onClick={onClose} />
      <div
        role="dialog"
        aria-modal="true"
        className={cx('animate-pop relative w-full rounded-2xl border border-line bg-card shadow-2xl', className ?? 'max-w-md')}
      >
        {children}
      </div>
    </div>,
    document.body,
  )
}

export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = 'حذف',
  loading,
  onConfirm,
  onClose,
}: {
  open: boolean
  title: string
  message: ReactNode
  confirmLabel?: string
  loading?: boolean
  onConfirm: () => void
  onClose: () => void
}) {
  return (
    <Modal open={open} onClose={onClose}>
      <div className="p-6">
        <div className="mb-4 grid size-12 place-items-center rounded-2xl bg-red-50 text-2xl dark:bg-red-500/15">🗑️</div>
        <h3 className="text-lg font-black">{title}</h3>
        <div className="mt-1 text-sm leading-relaxed text-ink-2">{message}</div>
        <div className="mt-6 flex gap-2">
          <Button variant="danger" loading={loading} onClick={onConfirm} autoFocus>
            {confirmLabel}
          </Button>
          <Button variant="ghost" onClick={onClose}>
            إلغاء
          </Button>
        </div>
      </div>
    </Modal>
  )
}

export function Kbd({ children }: { children: ReactNode }) {
  return (
    <kbd className="rounded-md border border-line bg-card-2 px-1.5 py-0.5 font-sans text-[10px] font-bold text-muted">
      {children}
    </kbd>
  )
}

export function EmptyState({ emoji, title, children }: { emoji: string; title: string; children?: ReactNode }) {
  return (
    <div className="animate-fade-up flex flex-col items-center px-6 py-16 text-center">
      <div className="mb-4 grid size-20 place-items-center rounded-3xl bg-brand-sky text-4xl dark:bg-blue-500/10">{emoji}</div>
      <h3 className="text-lg font-black">{title}</h3>
      <div className="mt-1 max-w-sm text-sm text-muted">{children}</div>
    </div>
  )
}
