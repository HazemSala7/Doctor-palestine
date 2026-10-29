import { useEffect, useRef, useState } from 'react'
import { toast } from 'sonner'
import { Save, Plus } from 'lucide-react'
import { ApiError, type Row, type Values } from '../lib/api'
import type { Field, Resource } from '../lib/resources'
import { useSave } from '../lib/queries'
import { Button, Drawer, Kbd, cx } from './ui'
import { CoordinatesField, ImageField, RelationSelect, TargetSelect, Toggle } from './fields'

function initialValues(resource: Resource, row: Partial<Row> | null): Values {
  const v: Values = {}
  for (const f of resource.fields) {
    v[f.key] = row?.[f.key] ?? (f.type === 'boolean' ? 1 : f.type === 'image' || f.type === 'coordinates' ? null : '')
  }
  return v
}

/**
 * Create / edit drawer. `row` with an id edits it; without one (or null)
 * creates a new record, prefilled when duplicating.
 */
export function ResourceForm({
  resource,
  row,
  onClose,
}: {
  resource: Resource
  row: Partial<Row> | null
  onClose: () => void
}) {
  const editingId = row?.id
  const [values, setValues] = useState<Values>(() => initialValues(resource, row))
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [dirty, setDirty] = useState(false)
  const save = useSave(resource.key)
  const form = useRef<HTMLFormElement>(null)
  const addAnother = useRef(false)

  const set = (key: string, v: unknown) => {
    // A new target section invalidates the picked record.
    setValues((s) => ({ ...s, [key]: v, ...(key === 'type' && 'target_id' in s ? { target_id: '' } : {}) }))
    setErrors((e) => {
      if (!e[key]) return e
      const { [key]: _, ...rest } = e
      return rest
    })
    setDirty(true)
  }

  const close = () => {
    if (dirty && !save.isPending && !confirm('لديك تغييرات غير محفوظة، هل تريد الإغلاق بدونها؟')) return
    onClose()
  }

  const validate = () => {
    const errs: Record<string, string> = {}
    for (const f of resource.fields) {
      const v = values[f.key]
      if (f.required && (v == null || v === '')) errs[f.key] = `${f.label} مطلوب`
    }
    setErrors(errs)
    return !Object.keys(errs).length
  }

  const submit = async (e?: React.FormEvent) => {
    e?.preventDefault()
    if (save.isPending) return
    if (!validate()) {
      form.current?.querySelector<HTMLElement>('[aria-invalid="true"]')?.focus()
      return
    }
    try {
      const saved = await save.mutateAsync({ id: editingId, values })
      toast.success(editingId ? 'تم حفظ التعديلات' : `تمت إضافة ${resource.singular} بنجاح`, {
        description: String(saved[resource.titleField] ?? ''),
      })
      if (addAnother.current) {
        setValues(initialValues(resource, null))
        setDirty(false)
        form.current?.querySelector<HTMLElement>('input,select,textarea')?.focus()
      } else {
        onClose()
      }
    } catch (err) {
      if (err instanceof ApiError && Object.keys(err.fieldErrors).length) setErrors(err.fieldErrors)
      toast.error(err instanceof Error ? err.message : 'حدث خطأ غير متوقع')
    } finally {
      addAnother.current = false
    }
  }

  // Ctrl+S saves from anywhere in the drawer.
  const submitRef = useRef(submit)
  submitRef.current = submit
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {
        e.preventDefault()
        submitRef.current()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  const Icon = resource.icon
  return (
    <Drawer
      open
      onClose={close}
      title={editingId ? `تعديل ${resource.singular}` : `إضافة ${resource.singular} جديد`}
      subtitle={editingId ? String(row?.[resource.titleField] ?? `#${editingId}`) : resource.label}
      icon={
        <div className="grid size-11 place-items-center rounded-2xl text-white" style={{ background: resource.color }}>
          <Icon className="size-5" />
        </div>
      }
      footer={
        <div className="flex flex-wrap items-center gap-2">
          <Button type="submit" form="resource-form" loading={save.isPending} icon={<Save className="size-4" />}>
            {editingId ? 'حفظ التعديلات' : 'حفظ'}
          </Button>
          {!editingId && (
            <Button
              variant="soft"
              type="submit"
              form="resource-form"
              disabled={save.isPending}
              onClick={() => (addAnother.current = true)}
              icon={<Plus className="size-4" />}
            >
              حفظ وإضافة آخر
            </Button>
          )}
          <Button variant="ghost" type="button" onClick={close}>
            إلغاء
          </Button>
          <span className="ms-auto hidden items-center gap-1 text-xs text-muted sm:flex">
            <Kbd>Ctrl</Kbd>+<Kbd>S</Kbd> للحفظ
          </span>
        </div>
      }
    >
      <form ref={form} id="resource-form" onSubmit={submit} className="grid grid-cols-1 gap-x-4 gap-y-5 sm:grid-cols-2" noValidate>
        {resource.fields.map((f, i) => (
          <FieldRow key={f.key} field={f} error={errors[f.key]} index={i}>
            {f.type === 'target' ? (
              <TargetSelect id={`f-${f.key}`} type={values.type} value={values[f.key]} onChange={(v) => set(f.key, v)} />
            ) : (
              renderInput(f, values[f.key], (v) => set(f.key, v), !!errors[f.key], i === 0)
            )}
          </FieldRow>
        ))}
      </form>
    </Drawer>
  )
}

function FieldRow({ field, error, index, children }: { field: Field; error?: string; index: number; children: React.ReactNode }) {
  return (
    <div
      className={cx('animate-fade-up', (field.wide || field.type === 'textarea' || field.type === 'coordinates') && 'sm:col-span-2')}
      style={{ animationDelay: `${index * 25}ms` }}
    >
      <label htmlFor={`f-${field.key}`} className="mb-1.5 flex items-center gap-1 text-sm font-bold text-ink-2">
        {field.label}
        {field.required && <span className="text-red-500">*</span>}
      </label>
      {children}
      {error && <p className="mt-1 text-xs font-bold text-red-500">{error}</p>}
    </div>
  )
}

function renderInput(f: Field, value: unknown, onChange: (v: unknown) => void, invalid: boolean, autoFocus: boolean) {
  const id = `f-${f.key}`
  const common = { id, 'aria-invalid': invalid, className: 'input' }
  switch (f.type) {
    case 'textarea':
      return (
        <textarea {...common} rows={4} placeholder={f.placeholder} value={String(value ?? '')} onChange={(e) => onChange(e.target.value)} />
      )
    case 'image':
      return <ImageField value={value} onChange={onChange} invalid={invalid} wide={f.wide} />
    case 'coordinates':
      return <CoordinatesField value={value} onChange={onChange} />
    case 'relation':
      return <RelationSelect id={id} field={f} value={value} onChange={onChange} invalid={invalid} />
    case 'select':
      return (
        <select {...common} value={String(value ?? '')} onChange={(e) => onChange(e.target.value)}>
          <option value="">اختر {f.label}</option>
          {f.options!.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      )
    case 'boolean':
      return (
        <div className="flex h-11 items-center gap-3">
          <Toggle id={id} checked={!!Number(value)} onChange={(v) => onChange(v ? 1 : 0)} />
          <span className="text-sm text-ink-2">{Number(value) ? 'ظاهر في التطبيق' : 'مخفي'}</span>
        </div>
      )
    default:
      return (
        <input
          {...common}
          autoFocus={autoFocus}
          type={f.type === 'number' ? 'number' : f.type === 'date' ? 'date' : f.type === 'phone' ? 'tel' : 'text'}
          dir={f.type === 'phone' || f.type === 'number' ? 'ltr' : undefined}
          placeholder={f.placeholder}
          value={String(value ?? '')}
          onChange={(e) => onChange(e.target.value)}
        />
      )
  }
}
