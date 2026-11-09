import { useRef, useState } from 'react'
import { toast } from 'sonner'
import { ArrowDown, ArrowRight, ArrowUp, Pencil, Plus, Save, Trash2, Users } from 'lucide-react'
import { ApiError, type Row, type Values } from '../lib/api'
import { RESOURCE_MAP, type Field } from '../lib/resources'
import { placeKey, useLookup, useRemove, useSave, useStaffByPlace } from '../lib/queries'
import { Avatar, Button, ConfirmDialog, Drawer, IconButton, cx } from './ui'
import { ImageField, RelationSelect, Toggle } from './fields'

const RESOURCE = 'staff'
const doctorField = RESOURCE_MAP[RESOURCE].fields.find((f) => f.key === 'doctor_id') as Field

/** The table's "team" cell: opens the drawer below. */
export function StaffChip({
  count,
  loading,
  failed,
  onClick,
}: {
  count: number
  loading: boolean
  failed: boolean
  onClick: () => void
}) {
  if (loading) return <div className="skeleton h-6 w-20 rounded-full" />
  if (failed) return <span className="text-muted" title="تعذّر تحميل الطاقم">—</span>
  if (!count) {
    return (
      <button
        onClick={onClick}
        className="focus-ring inline-flex items-center gap-1 rounded-full border border-dashed border-brand-light px-2.5 py-0.5 text-xs font-bold text-brand transition hover:bg-brand-sky dark:text-blue-300 dark:hover:bg-blue-500/15"
      >
        <Plus className="size-3" />
        إضافة طاقم
      </button>
    )
  }
  return (
    <button
      onClick={onClick}
      title="إدارة طاقم العمل"
      className="focus-ring inline-flex items-center gap-1.5 rounded-full bg-cyan-50 px-2.5 py-0.5 text-xs font-bold text-cyan-700 transition hover:brightness-95 dark:bg-cyan-500/15 dark:text-cyan-300"
    >
      <Users className="size-3.5" />
      {count}
    </button>
  )
}

const errorText = (e: unknown) => (e instanceof Error ? e.message : 'حدث خطأ غير متوقع')

/** Every staff field, so a partial change (order, visibility) keeps the rest. */
const valuesOf = (m: Row, change: Values = {}): Values => ({
  type: m.type,
  target_id: m.target_id,
  name: m.name,
  role: m.role,
  image: m.image ?? null,
  doctor_id: m.doctor_id ?? '',
  sort_order: m.sort_order ?? 0,
  active: Number(m.active) ? 1 : 0,
  bio: m.bio ?? '',
  ...change,
})

/** Lists one doctor's or centre's team, with add, edit, reorder, hide and delete. */
export function StaffDrawer({ type, targetId, title, onClose }: { type: string; targetId: number; title: string; onClose: () => void }) {
  const { byPlace } = useStaffByPlace(type)
  const team = byPlace.get(placeKey(type, targetId)) ?? []
  const [editing, setEditing] = useState<Row | 'new' | null>(null)
  const dirty = useRef(false)

  const openForm = (m: Row | 'new') => {
    dirty.current = false
    setEditing(m)
  }
  const leavingOk = () => !dirty.current || confirm('لديك تغييرات غير محفوظة، هل تريد الإغلاق بدونها؟')

  return (
    <Drawer
      open
      onClose={() => leavingOk() && onClose()}
      title={editing === 'new' ? 'إضافة عضو للطاقم' : editing ? 'تعديل عضو الطاقم' : 'طاقم العمل'}
      subtitle={title}
      icon={
        <div className="grid size-11 place-items-center rounded-2xl text-white" style={{ background: RESOURCE_MAP[RESOURCE].color }}>
          <Users className="size-5" />
        </div>
      }
    >
      {editing ? (
        <MemberForm
          type={type}
          targetId={targetId}
          member={editing === 'new' ? undefined : editing}
          nextOrder={team.reduce((max, m) => Math.max(max, Number(m.sort_order ?? 0)), 0) + 1}
          onDirty={() => (dirty.current = true)}
          onBack={() => leavingOk() && setEditing(null)}
          onSaved={() => {
            dirty.current = false
            setEditing(null)
          }}
        />
      ) : (
        <TeamList team={team} onAdd={() => openForm('new')} onEdit={openForm} />
      )}
    </Drawer>
  )
}

function TeamList({ team, onAdd, onEdit }: { team: Row[]; onAdd: () => void; onEdit: (m: Row) => void }) {
  const save = useSave(RESOURCE)
  const remove = useRemove(RESOURCE)
  const { byId: doctors } = useLookup('doctors')
  const [deleting, setDeleting] = useState<Row | null>(null)
  const [busy, setBusy] = useState(false)

  const run = async (work: () => Promise<unknown>) => {
    setBusy(true)
    try {
      await work()
    } catch (e) {
      toast.error(errorText(e))
    } finally {
      setBusy(false)
    }
  }

  // Positions are rewritten as 1, 2, 3...: rows can share a number after manual edits.
  const move = (from: number, to: number) =>
    run(async () => {
      const next = [...team]
      next.splice(to, 0, next.splice(from, 1)[0])
      for (const [i, m] of next.entries()) {
        if (Number(m.sort_order) !== i + 1) await save.mutateAsync({ id: m.id, values: valuesOf(m, { sort_order: i + 1 }) })
      }
    })

  const toggle = (m: Row) => run(() => save.mutateAsync({ id: m.id, values: valuesOf(m, { active: Number(m.active) ? 0 : 1 }) }))

  const destroy = async () => {
    if (!deleting) return
    const name = deleting.name
    await run(async () => {
      await remove.mutateAsync([deleting.id])
      toast.success('تم الحذف من الطاقم', { description: String(name) })
    })
    setDeleting(null)
  }

  if (!team.length) {
    return (
      <div className="rounded-2xl bg-card-2 p-10 text-center">
        <div className="mb-2 text-4xl">👥</div>
        <p className="font-bold text-ink-2">لا يوجد طاقم بعد</p>
        <p className="mt-1 text-sm text-muted">القسم لا يظهر في التطبيق حتى تضيف أول شخص.</p>
        <Button className="mt-4" icon={<Plus className="size-4" />} onClick={onAdd}>
          إضافة أول عضو
        </Button>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <p className="text-sm text-muted">يظهرون في التطبيق بهذا الترتيب</p>
        <Button icon={<Plus className="size-4" />} onClick={onAdd}>
          إضافة عضو
        </Button>
      </div>
      <ul className="divide-y divide-line/70 overflow-hidden rounded-2xl border border-line">
        {team.map((m, i) => {
          const visible = !!Number(m.active)
          const linked = m.doctor_id ? (doctors.get(Number(m.doctor_id))?.name as string | undefined) : undefined
          return (
            <li key={m.id} className={cx('flex items-center gap-3 px-3 py-2.5', !visible && 'bg-card-2/60')}>
              <div className="flex flex-col">
                <button
                  type="button"
                  aria-label={`تقديم ${m.name}`}
                  disabled={busy || i === 0}
                  onClick={() => move(i, i - 1)}
                  className="focus-ring rounded text-muted hover:text-ink disabled:opacity-25"
                >
                  <ArrowUp className="size-4" />
                </button>
                <button
                  type="button"
                  aria-label={`تأخير ${m.name}`}
                  disabled={busy || i === team.length - 1}
                  onClick={() => move(i, i + 1)}
                  className="focus-ring rounded text-muted hover:text-ink disabled:opacity-25"
                >
                  <ArrowDown className="size-4" />
                </button>
              </div>
              <div className={cx(!visible && 'opacity-50')}>
                <Avatar src={m.image} name={String(m.name)} round />
              </div>
              <div className="min-w-0 flex-1">
                <div className="truncate font-bold text-ink">{String(m.name)}</div>
                <div className="truncate text-xs text-muted">
                  {String(m.role)}
                  {linked && <span className="text-brand dark:text-blue-300"> • ملفه: {linked}</span>}
                </div>
              </div>
              <div className="flex items-center gap-2" title={visible ? 'يظهر في التطبيق' : 'مخفي'}>
                <Toggle checked={visible} onChange={() => !busy && toggle(m)} />
              </div>
              <IconButton label={`تعديل ${m.name}`} onClick={() => onEdit(m)}>
                <Pencil className="size-4" />
              </IconButton>
              <IconButton label={`حذف ${m.name}`} className="hover:bg-red-50! hover:text-red-600! dark:hover:bg-red-500/15!" onClick={() => setDeleting(m)}>
                <Trash2 className="size-4" />
              </IconButton>
            </li>
          )
        })}
      </ul>
      <ConfirmDialog
        open={!!deleting}
        title="حذف من الطاقم؟"
        loading={busy}
        onConfirm={destroy}
        onClose={() => setDeleting(null)}
        message={
          <p>
            سيختفي <b>{String(deleting?.name ?? '')}</b> من التطبيق فوراً. إذا كنت تريد إخفاءه مؤقتاً استخدم مفتاح الظهور بدلاً من الحذف.
          </p>
        }
      />
    </div>
  )
}

function MemberForm({
  type,
  targetId,
  member,
  nextOrder,
  onDirty,
  onBack,
  onSaved,
}: {
  type: string
  targetId: number
  member?: Row
  nextOrder: number
  onDirty: () => void
  onBack: () => void
  onSaved: () => void
}) {
  const [name, setName] = useState(String(member?.name ?? ''))
  const [role, setRole] = useState(String(member?.role ?? ''))
  const [bio, setBio] = useState(String(member?.bio ?? ''))
  const [image, setImage] = useState<File | string | null>(member?.image ?? null)
  const [doctorId, setDoctorId] = useState<unknown>(member?.doctor_id ?? '')
  const [active, setActive] = useState(member ? !!Number(member.active) : true)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const save = useSave(RESOURCE)

  const changed = <T,>(set: (v: T) => void) => (v: T) => {
    onDirty()
    set(v)
  }

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    const found: Record<string, string> = {}
    if (!name.trim()) found.name = 'الاسم مطلوب'
    if (!role.trim()) found.role = 'المسمى الوظيفي مطلوب'
    setErrors(found)
    if (Object.keys(found).length) return
    try {
      await save.mutateAsync({
        id: member?.id,
        values: {
          type,
          target_id: targetId,
          name: name.trim(),
          role: role.trim(),
          image,
          doctor_id: doctorId,
          sort_order: member?.sort_order ?? nextOrder,
          active: active ? 1 : 0,
          bio: bio.trim(),
        },
      })
      toast.success(member ? 'تم حفظ التعديلات' : 'تمت الإضافة للطاقم', { description: name.trim() })
      onSaved()
    } catch (err) {
      if (err instanceof ApiError) setErrors(err.fieldErrors)
      toast.error(errorText(err))
    }
  }

  return (
    <form onSubmit={submit} className="grid grid-cols-1 gap-x-4 gap-y-5 sm:grid-cols-2" noValidate>
      <Labeled id="staff-name" label="الاسم" required error={errors.name}>
        <input
          id="staff-name"
          className="input"
          autoFocus
          aria-invalid={!!errors.name}
          placeholder="مثال: د. سارة أحمد"
          value={name}
          onChange={(e) => changed(setName)(e.target.value)}
        />
      </Labeled>
      <Labeled id="staff-role" label="المسمى الوظيفي" required error={errors.role}>
        <input
          id="staff-role"
          className="input"
          aria-invalid={!!errors.role}
          placeholder="مثال: ممرضة، أخصائي أشعة"
          value={role}
          onChange={(e) => changed(setRole)(e.target.value)}
        />
      </Labeled>
      <div className="sm:col-span-2">
        <Labeled label="الصورة" error={errors.image}>
          <ImageField value={image} onChange={changed<File | null>(setImage)} wide />
        </Labeled>
      </div>
      <Labeled id="staff-doctor" label={doctorField.label} hint={doctorField.hint} error={errors.doctor_id}>
        <RelationSelect id="staff-doctor" field={doctorField} value={doctorId} onChange={changed<unknown>(setDoctorId)} />
      </Labeled>
      <Labeled id="staff-active" label="الظهور">
        <div className="flex h-11 items-center gap-3">
          <Toggle id="staff-active" checked={active} onChange={changed(setActive)} />
          <span className="text-sm text-ink-2">{active ? 'يظهر في التطبيق' : 'مخفي'}</span>
        </div>
      </Labeled>
      <div className="sm:col-span-2">
        <Labeled id="staff-bio" label="نبذة" error={errors.bio}>
          <textarea
            id="staff-bio"
            className="input"
            rows={3}
            placeholder="الخبرة، الشهادات، ما يقدّمه للمرضى..."
            value={bio}
            onChange={(e) => changed(setBio)(e.target.value)}
          />
        </Labeled>
      </div>
      <div className="flex gap-2 sm:col-span-2">
        <Button type="submit" loading={save.isPending} icon={<Save className="size-4" />}>
          {member ? 'حفظ التعديلات' : 'إضافة للطاقم'}
        </Button>
        <Button type="button" variant="ghost" icon={<ArrowRight className="size-4" />} onClick={onBack}>
          رجوع للقائمة
        </Button>
      </div>
    </form>
  )
}

function Labeled({
  id,
  label,
  required,
  hint,
  error,
  children,
}: {
  id?: string
  label: string
  required?: boolean
  hint?: string
  error?: string
  children: React.ReactNode
}) {
  return (
    <div>
      <label htmlFor={id} className="mb-1.5 flex items-center gap-1 text-sm font-bold text-ink-2">
        {label}
        {required && <span className="text-red-500">*</span>}
      </label>
      {children}
      {hint && !error && <p className="mt-1 text-xs text-muted">{hint}</p>}
      {error && <p className="mt-1 text-xs font-bold text-red-500">{error}</p>}
    </div>
  )
}
