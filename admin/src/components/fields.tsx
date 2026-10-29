import { useEffect, useMemo, useRef, useState } from 'react'
import { ImagePlus, MapPinned, Trash2, ExternalLink } from 'lucide-react'
import type { Coordinates } from '../lib/api'
import { AD_TARGETS, type Field } from '../lib/resources'
import { useLookup } from '../lib/queries'
import { cx } from './ui'

/** Accepts a picked, dropped or pasted image. Value: File | URL | null. */
export function ImageField({
  value,
  onChange,
  invalid,
  wide,
}: {
  value: unknown
  onChange: (v: File | null) => void
  invalid?: boolean
  wide?: boolean
}) {
  const input = useRef<HTMLInputElement>(null)
  const [drag, setDrag] = useState(false)
  const preview = useMemo(
    () => (value instanceof File ? URL.createObjectURL(value) : typeof value === 'string' && value ? value : null),
    [value],
  )
  useEffect(() => () => {
    if (value instanceof File && preview) URL.revokeObjectURL(preview)
  }, [value, preview])

  const take = (files?: FileList | null) => {
    const f = files?.[0]
    if (f && f.type.startsWith('image/')) onChange(f)
  }

  return (
    <div
      tabIndex={0}
      onClick={() => input.current?.click()}
      onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && input.current?.click()}
      onPaste={(e) => take(e.clipboardData.files)}
      onDragOver={(e) => {
        e.preventDefault()
        setDrag(true)
      }}
      onDragLeave={() => setDrag(false)}
      onDrop={(e) => {
        e.preventDefault()
        setDrag(false)
        take(e.dataTransfer.files)
      }}
      aria-invalid={invalid}
      className={cx(
        'focus-ring group relative flex cursor-pointer items-center justify-center overflow-hidden rounded-2xl border-2 border-dashed transition',
        wide ? 'h-44' : 'h-36',
        drag ? 'border-brand-light bg-brand-sky/60 dark:bg-blue-500/10' : 'border-line bg-card-2 hover:border-brand-light',
        invalid && 'border-red-500',
      )}
    >
      {preview ? (
        <>
          <img src={preview} alt="" className="size-full object-cover" />
          <div className="absolute inset-0 flex items-center justify-center gap-2 bg-slate-950/50 opacity-0 transition group-hover:opacity-100 group-focus:opacity-100">
            <span className="rounded-lg bg-white/90 px-3 py-1.5 text-xs font-bold text-slate-800">تغيير</span>
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation()
                onChange(null)
              }}
              className="flex items-center gap-1 rounded-lg bg-red-600 px-3 py-1.5 text-xs font-bold text-white"
            >
              <Trash2 className="size-3.5" /> إزالة
            </button>
          </div>
        </>
      ) : (
        <div className="pointer-events-none text-center text-muted">
          <ImagePlus className="mx-auto mb-2 size-8 text-brand-light" />
          <p className="text-sm font-bold text-ink-2">اسحب صورة هنا أو اضغط للاختيار</p>
          <p className="text-xs">يمكنك أيضاً لصق صورة (Ctrl+V)</p>
        </div>
      )}
      <input ref={input} type="file" accept="image/*" hidden onChange={(e) => take(e.target.files)} />
    </div>
  )
}

/** The backend stores `[{lat, lng}]`; the form edits the first point. */
export function CoordinatesField({ value, onChange }: { value: unknown; onChange: (v: Coordinates | null) => void }) {
  const point = (Array.isArray(value) ? value[0] : value) as Coordinates | null | undefined
  const lat = point?.lat ?? ''
  const lng = point?.lng ?? ''
  const valid = lat !== '' && lng !== '' && !isNaN(+lat) && !isNaN(+lng)
  const outside = valid && (+lat < 29 || +lat > 34 || +lng < 33.5 || +lng > 36.5)

  const set = (next: Partial<Coordinates>) => {
    const p = { lat: String(lat), lng: String(lng), ...next }
    onChange(p.lat === '' && p.lng === '' ? null : p)
  }

  // Pasting "31.9, 35.2" or a Google Maps link fills both boxes.
  const onPaste = (e: React.ClipboardEvent) => {
    const text = e.clipboardData.getData('text')
    const m = text.match(/(-?\d{1,3}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)/)
    if (m) {
      e.preventDefault()
      set({ lat: m[1], lng: m[2] })
    }
  }

  const d = 0.008
  const map = valid
    ? `https://www.openstreetmap.org/export/embed.html?bbox=${+lng - d},${+lat - d},${+lng + d},${+lat + d}&layer=mapnik&marker=${lat},${lng}`
    : null

  return (
    <div className="space-y-2">
      <div className="grid grid-cols-2 gap-2" onPaste={onPaste}>
        <input
          className="input"
          dir="ltr"
          inputMode="decimal"
          placeholder="خط العرض lat"
          value={lat}
          onChange={(e) => set({ lat: e.target.value })}
        />
        <input
          className="input"
          dir="ltr"
          inputMode="decimal"
          placeholder="خط الطول lng"
          value={lng}
          onChange={(e) => set({ lng: e.target.value })}
        />
      </div>
      <p className="text-xs text-muted">
        نصيحة: الصق الإحداثيات أو رابط Google Maps مباشرة في أحد الحقلين وسيتم تعبئتهما تلقائياً.
      </p>
      {outside && (
        <p className="rounded-lg bg-amber-50 px-3 py-2 text-xs font-bold text-amber-800 dark:bg-amber-500/10 dark:text-amber-300">
          ⚠️ هذا الموقع خارج فلسطين، تأكد من الإحداثيات.
        </p>
      )}
      {map ? (
        <div className="relative overflow-hidden rounded-2xl border border-line">
          <iframe title="الخريطة" src={map} className="h-48 w-full" loading="lazy" />
          <a
            href={`https://www.google.com/maps?q=${lat},${lng}`}
            target="_blank"
            rel="noreferrer"
            className="absolute bottom-2 left-2 flex items-center gap-1 rounded-lg bg-white/95 px-2.5 py-1 text-xs font-bold text-slate-800 shadow"
          >
            <ExternalLink className="size-3.5" /> Google Maps
          </a>
        </div>
      ) : (
        <div className="flex h-20 items-center justify-center gap-2 rounded-2xl border border-dashed border-line text-sm text-muted">
          <MapPinned className="size-5" /> أدخل الإحداثيات لعرض الخريطة
        </div>
      )}
    </div>
  )
}

export function RelationSelect({
  field,
  value,
  onChange,
  invalid,
  id,
}: {
  field: Field
  value: unknown
  onChange: (v: string) => void
  invalid?: boolean
  id: string
}) {
  const { rows, isLoading } = useLookup(field.relation)
  return (
    <select
      id={id}
      className="input"
      aria-invalid={invalid}
      value={value == null ? '' : String(value)}
      onChange={(e) => onChange(e.target.value)}
    >
      <option value="">{isLoading ? 'جارِ التحميل...' : `اختر ${field.label}`}</option>
      {rows.map((r) => (
        <option key={r.id} value={r.id}>
          {r.name}
        </option>
      ))}
    </select>
  )
}

/** Advertisement target: records of whichever section the `type` field names. */
export function TargetSelect({
  type,
  value,
  onChange,
  id,
}: {
  type: unknown
  value: unknown
  onChange: (v: string) => void
  id: string
}) {
  const target = AD_TARGETS.find((t) => t.value === type)
  const { rows, isLoading } = useLookup(target?.resource)
  if (!target) {
    return <div className="input text-muted">اختر «يفتح عند الضغط» أولاً</div>
  }
  return (
    <select id={id} className="input" value={value == null ? '' : String(value)} onChange={(e) => onChange(e.target.value)}>
      <option value="">{isLoading ? 'جارِ التحميل...' : `اختر ${target.label}`}</option>
      {rows.map((r) => (
        <option key={r.id} value={r.id}>
          {r.name ?? r.title} (#{r.id})
        </option>
      ))}
    </select>
  )
}

export function Toggle({ checked, onChange, id }: { checked: boolean; onChange: (v: boolean) => void; id?: string }) {
  return (
    <button
      id={id}
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className={cx(
        'focus-ring relative h-7 w-12 rounded-full transition',
        checked ? 'bg-emerald-500' : 'bg-slate-300 dark:bg-slate-600',
      )}
    >
      <span
        className={cx(
          'absolute top-1 size-5 rounded-full bg-white shadow transition-all',
          checked ? 'right-6' : 'right-1',
        )}
      />
    </button>
  )
}
