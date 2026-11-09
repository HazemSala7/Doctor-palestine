import { useState } from 'react'
import { ExternalLink, Eye, X } from 'lucide-react'
import type { Row } from '../lib/api'
import { useLookup } from '../lib/queries'
import { formatNumber } from '../lib/hooks'
import { IconButton, Modal } from './ui'

/** Plays a reel on the dashboard: the uploaded file if there is one, as the app does. */
export function ReelPreview({ reel, onClose }: { reel: Row; onClose: () => void }) {
  const { byId } = useLookup('doctors')
  const [failed, setFailed] = useState(false)
  const src: string | undefined = reel.video || reel.video_url || undefined
  const doctor = reel.doctor_id ? (byId.get(Number(reel.doctor_id))?.name as string | undefined) : undefined
  const visible = !!Number(reel.active)

  return (
    <Modal open onClose={onClose} className="max-w-sm">
      <div className="flex items-center gap-2 border-b border-line py-2 ps-4 pe-2">
        <h3 className="min-w-0 flex-1 truncate font-black">{String(reel.title ?? '')}</h3>
        <IconButton label="إغلاق" onClick={onClose}>
          <X className="size-4" />
        </IconButton>
      </div>
      <div className="p-4">
        {src && !failed ? (
          <video
            key={src}
            src={src}
            poster={reel.thumbnail || undefined}
            className="mx-auto max-h-[60vh] w-full rounded-2xl bg-black"
            controls
            autoPlay
            playsInline
            onError={() => setFailed(true)}
          />
        ) : (
          <div className="rounded-2xl bg-card-2 p-8 text-center text-sm text-muted">
            <div className="mb-2 text-3xl">🎬</div>
            <p className="font-bold text-ink-2">{src ? 'تعذّر تشغيل الفيديو' : 'لا يوجد فيديو لهذا الريل'}</p>
            {src && <p className="mt-1 text-xs">تأكد أن الرابط مباشر لملف فيديو، وأن الملف ما زال موجوداً.</p>}
            {src && (
              <a href={src} target="_blank" rel="noreferrer" className="mt-3 inline-flex items-center gap-1 text-xs font-bold text-brand dark:text-blue-300">
                <ExternalLink className="size-3.5" />
                فتح الرابط
              </a>
            )}
          </div>
        )}
        <div className="mt-3 flex flex-wrap items-center gap-2 text-xs">
          <span
            className={
              visible
                ? 'rounded-full bg-emerald-50 px-2 py-0.5 font-bold text-emerald-700 dark:bg-emerald-500/15 dark:text-emerald-300'
                : 'rounded-full bg-slate-100 px-2 py-0.5 font-bold text-slate-500 dark:bg-slate-500/15'
            }
          >
            {visible ? '● ظاهر في التطبيق' : '○ مخفي'}
          </span>
          <span className="inline-flex items-center gap-1 text-muted">
            <Eye className="size-3.5" />
            {formatNumber(Number(reel.views ?? 0))} مشاهدة
          </span>
          {doctor && <span className="font-bold text-ink-2">{doctor}</span>}
        </div>
        {reel.description && <p className="mt-2 text-sm leading-relaxed text-ink-2">{String(reel.description)}</p>}
      </div>
    </Modal>
  )
}
