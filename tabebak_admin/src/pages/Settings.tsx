import { useEffect, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Save, Settings as SettingsIcon } from 'lucide-react'
import { api, ApiError } from '../lib/api'
import { Button, Spinner, cx } from '../components/ui'
import { Toggle } from '../components/fields'

interface SettingField {
  key: string
  label: string
  /** `switch`: stored as '1' / '0'. */
  type: 'text' | 'textarea' | 'phone' | 'email' | 'url' | 'switch'
  placeholder?: string
  hint?: string
  rows?: number
}

const TEXT_HINT = 'نص عادي: كل سطر فقرة، والسطر الذي يبدأ بـ "- " يظهر كنقطة.'

const GROUPS: { title: string; emoji: string; fields: SettingField[] }[] = [
  {
    title: 'الواجهة',
    emoji: '✨',
    fields: [{ key: 'tagline', label: 'الشعار النصي', type: 'text', hint: 'يظهر تحت الشعار في صفحة «المزيد»' }],
  },
  {
    title: 'التواصل والدعم',
    emoji: '💬',
    fields: [
      { key: 'support_whatsapp', label: 'رقم واتساب الدعم', type: 'phone', placeholder: '059xxxxxxx', hint: 'زر «تواصل معنا عبر واتساب» وطلبات الأطباء لتفعيل الحجز' },
      { key: 'support_phone', label: 'رقم الهاتف', type: 'phone', placeholder: '09xxxxxxx' },
      { key: 'support_email', label: 'البريد الإلكتروني', type: 'email', placeholder: 'support@...' },
    ],
  },
  {
    title: 'روابط التواصل الاجتماعي',
    emoji: '🔗',
    fields: [
      { key: 'facebook_url', label: 'فيسبوك', type: 'url', placeholder: 'https://facebook.com/...' },
      { key: 'instagram_url', label: 'إنستغرام', type: 'url', placeholder: 'https://instagram.com/...' },
      { key: 'tiktok_url', label: 'تيك توك', type: 'url', placeholder: 'https://tiktok.com/@...' },
      { key: 'website_url', label: 'الموقع الإلكتروني', type: 'url', placeholder: 'https://...' },
    ],
  },
  {
    title: 'التقييمات',
    emoji: '⭐',
    fields: [
      {
        key: 'reviews_auto_approve',
        label: 'نشر التقييمات مباشرة',
        type: 'switch',
        hint: 'عند الإيقاف: يظهر التقييم في التطبيق بعد أن توافق عليه من قسم «التقييمات». عند التشغيل: يُنشر فوراً، ويمكنك رفضه لاحقاً.',
      },
    ],
  },
  {
    title: 'صفحات التطبيق',
    emoji: '📄',
    fields: [
      { key: 'about_us', label: 'من نحن', type: 'textarea', rows: 10, hint: TEXT_HINT },
      { key: 'privacy_policy', label: 'سياسة الخصوصية', type: 'textarea', rows: 16, hint: TEXT_HINT },
    ],
  },
]

const INPUT_TYPES = { text: 'text', phone: 'tel', email: 'email', url: 'url', switch: 'checkbox' } as const

/** Texts, contact details and links the app shows. Empty links are hidden in the app. */
export default function Settings() {
  const qc = useQueryClient()
  const { data, isLoading } = useQuery({ queryKey: ['settings'], queryFn: () => api.settings() })
  const [values, setValues] = useState<Record<string, string>>({})
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [dirty, setDirty] = useState(false)

  useEffect(() => {
    if (data) setValues(data)
  }, [data])

  const save = useMutation({
    mutationFn: () => api.saveSettings(values),
    onSuccess: (saved) => {
      qc.setQueryData(['settings'], saved)
      setDirty(false)
      setErrors({})
      toast.success('تم حفظ الإعدادات', { description: 'تظهر في التطبيق عند فتحه أو الرجوع إليه' })
    },
    onError: (err) => {
      if (err instanceof ApiError) setErrors(err.fieldErrors)
      toast.error(err instanceof Error ? err.message : 'حدث خطأ غير متوقع')
    },
  })

  const set = (key: string, v: string) => {
    setValues((s) => ({ ...s, [key]: v }))
    setErrors(({ [key]: _, ...rest }) => rest)
    setDirty(true)
  }

  if (isLoading) {
    return (
      <div className="grid h-64 place-items-center">
        <Spinner className="size-8" />
      </div>
    )
  }

  return (
    <form
      className="space-y-6 pb-24"
      onSubmit={(e) => {
        e.preventDefault()
        save.mutate()
      }}
    >
      <header className="animate-fade-up flex items-center gap-3">
        <div className="brand-gradient grid size-12 place-items-center rounded-2xl text-white shadow-lg">
          <SettingsIcon className="size-6" />
        </div>
        <div>
          <h1 className="text-2xl font-black">إعدادات التطبيق</h1>
          <p className="text-sm text-muted">النصوص وأرقام التواصل والروابط التي تظهر في التطبيق</p>
        </div>
      </header>

      {GROUPS.map((g, gi) => (
        <section
          key={g.title}
          className="animate-fade-up rounded-2xl border border-line bg-card p-5 shadow-sm"
          style={{ animationDelay: `${gi * 60}ms` }}
        >
          <h2 className="mb-4 text-base font-black">
            {g.emoji} {g.title}
          </h2>
          <div className="grid grid-cols-1 gap-x-4 gap-y-5 sm:grid-cols-2">
            {g.fields.map((f) => (
              <div key={f.key} className={cx(f.type === 'textarea' && 'sm:col-span-2')}>
                <label htmlFor={`s-${f.key}`} className="mb-1.5 block text-sm font-bold text-ink-2">
                  {f.label}
                </label>
                {f.type === 'switch' ? (
                  <div className="flex items-center gap-3">
                    <Toggle id={`s-${f.key}`} checked={values[f.key] === '1'} onChange={(on) => set(f.key, on ? '1' : '0')} />
                    <span className="text-sm font-bold text-ink-2">{values[f.key] === '1' ? 'مفعّل' : 'متوقف'}</span>
                  </div>
                ) : f.type === 'textarea' ? (
                  <textarea
                    id={`s-${f.key}`}
                    className="input leading-7"
                    rows={f.rows}
                    aria-invalid={!!errors[f.key]}
                    value={values[f.key] ?? ''}
                    onChange={(e) => set(f.key, e.target.value)}
                  />
                ) : (
                  <input
                    id={`s-${f.key}`}
                    className="input"
                    type={INPUT_TYPES[f.type]}
                    dir={f.type === 'text' ? undefined : 'ltr'}
                    placeholder={f.placeholder}
                    aria-invalid={!!errors[f.key]}
                    value={values[f.key] ?? ''}
                    onChange={(e) => set(f.key, e.target.value)}
                  />
                )}
                {errors[f.key] ? (
                  <p className="mt-1 text-xs font-bold text-red-500">{errors[f.key]}</p>
                ) : (
                  f.hint && <p className="mt-1 text-xs text-muted">{f.hint}</p>
                )}
              </div>
            ))}
          </div>
        </section>
      ))}

      {/* Stops at the sidebar, or it would cover the sign-out button. */}
      <div className="fixed inset-x-0 bottom-0 z-20 border-t border-line bg-bg/85 px-4 py-3 backdrop-blur-lg lg:start-72">
        <div className="mx-auto flex max-w-7xl items-center gap-3">
          <Button type="submit" loading={save.isPending} disabled={!dirty} icon={<Save className="size-4" />}>
            حفظ الإعدادات
          </Button>
          {dirty && <span className="text-sm text-muted">لديك تغييرات غير محفوظة</span>}
        </div>
      </div>
    </form>
  )
}
