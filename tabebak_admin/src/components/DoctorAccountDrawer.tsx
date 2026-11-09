import { useMemo, useState, type ReactNode } from 'react'
import { toast } from 'sonner'
import { ArrowLeftRight, KeyRound, Link2, Plus, Save, Search, Trash2, Wand2 } from 'lucide-react'
import { ApiError, type Row, type Values } from '../lib/api'
import { useDoctorAccounts, useLookup, useRemove, useSave } from '../lib/queries'
import { Button, ConfirmDialog, Drawer, cx } from './ui'
import { Toggle } from './fields'

const RESOURCE = 'doctor-accounts'

/** The doctors table's "app account" cell: opens the drawer below. */
export function AccountChip({
  account,
  loading,
  failed,
  onClick,
}: {
  account?: Row
  loading: boolean
  failed: boolean
  onClick: () => void
}) {
  if (loading) return <div className="skeleton h-6 w-24 rounded-full" />
  if (failed) return <span className="text-muted" title="تعذّر تحميل الحسابات">—</span>
  if (!account) {
    return (
      <button
        onClick={onClick}
        className="focus-ring inline-flex items-center gap-1 rounded-full border border-dashed border-brand-light px-2.5 py-0.5 text-xs font-bold text-brand transition hover:bg-brand-sky dark:text-blue-300 dark:hover:bg-blue-500/15"
      >
        <Plus className="size-3" />
        ربط حساب
      </button>
    )
  }
  const active = !!Number(account.active)
  return (
    <button
      onClick={onClick}
      title="إدارة الحساب"
      className={cx(
        'focus-ring inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-bold transition hover:brightness-95',
        active
          ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-500/15 dark:text-emerald-300'
          : 'bg-slate-100 text-slate-500 dark:bg-slate-500/15',
      )}
    >
      {active ? '●' : '○ موقوف'}
      <span dir="ltr">{account.phone}</span>
    </button>
  )
}

/** A move keeps everything about the account except which doctor it serves. */
const movedTo = (account: Row, doctorId: number): Values => ({
  doctor_id: doctorId,
  phone: account.phone,
  password: '',
  active: Number(account.active) ? 1 : 0,
  booking_enabled: Number(account.booking_enabled) ? 1 : 0,
})

const errorText = (e: unknown) => (e instanceof Error ? e.message : 'حدث خطأ غير متوقع')

/** Create, edit, link, move or delete the app login of one doctor. */
export function DoctorAccountDrawer({ doctor, onClose }: { doctor: Row; onClose: () => void }) {
  const { rows: accounts, byDoctor } = useDoctorAccounts()
  const { rows: doctors, byId: doctorsById } = useLookup('doctors')
  const account = byDoctor.get(doctor.id)
  const [tab, setTab] = useState<'create' | 'link'>('create')

  return (
    <Drawer
      open
      onClose={onClose}
      title={account ? 'حساب الطبيب في التطبيق' : 'ربط حساب بالطبيب'}
      subtitle={String(doctor.name)}
      icon={
        <div className="grid size-11 place-items-center rounded-2xl bg-brand-dark text-white">
          <KeyRound className="size-5" />
        </div>
      }
    >
      {account ? (
        <div className="space-y-6">
          <AccountForm key={account.id} doctor={doctor} account={account} onDone={onClose} />
          <MoveAccount account={account} doctor={doctor} doctors={doctors} byDoctor={byDoctor} onDone={onClose} />
          <DeleteAccount account={account} doctor={doctor} onDone={onClose} />
        </div>
      ) : (
        <div className="space-y-5">
          <div className="grid grid-cols-2 gap-1 rounded-2xl bg-card-2 p-1" role="tablist">
            <TabButton active={tab === 'create'} onClick={() => setTab('create')} icon={<Plus className="size-4" />}>
              إنشاء حساب جديد
            </TabButton>
            <TabButton active={tab === 'link'} onClick={() => setTab('link')} icon={<Link2 className="size-4" />}>
              ربط حساب موجود
            </TabButton>
          </div>
          {tab === 'create' ? (
            <AccountForm doctor={doctor} onDone={onClose} />
          ) : (
            <LinkExisting doctor={doctor} accounts={accounts} doctorsById={doctorsById} onDone={onClose} />
          )}
        </div>
      )}
    </Drawer>
  )
}

function TabButton({ active, onClick, icon, children }: { active: boolean; onClick: () => void; icon: ReactNode; children: ReactNode }) {
  return (
    <button
      type="button"
      role="tab"
      aria-selected={active}
      onClick={onClick}
      className={cx(
        'focus-ring inline-flex h-10 items-center justify-center gap-2 rounded-xl text-sm font-bold transition',
        active ? 'bg-card text-brand shadow-sm dark:text-blue-300' : 'text-ink-2 hover:text-ink',
      )}
    >
      {icon}
      {children}
    </button>
  )
}

function Labeled({ id, label, hint, error, children }: { id?: string; label: string; hint?: string; error?: string; children: ReactNode }) {
  return (
    <div>
      <label htmlFor={id} className="mb-1.5 block text-sm font-bold text-ink-2">
        {label}
      </label>
      {children}
      {hint && !error && <p className="mt-1 text-xs text-muted">{hint}</p>}
      {error && <p className="mt-1 text-xs font-bold text-red-500">{error}</p>}
    </div>
  )
}

function randomPassword() {
  const [n] = crypto.getRandomValues(new Uint32Array(1))
  return String(10_000_000 + (n % 90_000_000))
}

function AccountForm({ doctor, account, onDone }: { doctor: Row; account?: Row; onDone: () => void }) {
  const [phone, setPhone] = useState(String(account?.phone ?? doctor.mobile ?? ''))
  const [password, setPassword] = useState('')
  const [active, setActive] = useState(account ? !!Number(account.active) : true)
  const [booking, setBooking] = useState(account ? !!Number(account.booking_enabled) : true)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const save = useSave(RESOURCE)

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    const found: Record<string, string> = {}
    if (!phone.trim()) found.phone = 'رقم الهاتف مطلوب'
    if (!account && !password) found.password = 'كلمة المرور مطلوبة لحساب جديد'
    else if (password && password.length < 6) found.password = 'يجب ألا تقل عن 6 أحرف'
    setErrors(found)
    if (Object.keys(found).length) return
    try {
      await save.mutateAsync({
        id: account?.id,
        values: { doctor_id: doctor.id, phone: phone.trim(), password, active: active ? 1 : 0, booking_enabled: booking ? 1 : 0 },
      })
      toast.success(account ? 'تم حفظ الحساب' : 'تم إنشاء الحساب وربطه بالطبيب', { description: String(doctor.name) })
      onDone()
    } catch (err) {
      if (err instanceof ApiError) setErrors(err.fieldErrors)
      toast.error(errorText(err))
    }
  }

  return (
    <form onSubmit={submit} className="space-y-5" noValidate>
      <Labeled id="acc-phone" label="رقم الهاتف (اسم المستخدم)" hint="يسجّل الطبيب الدخول في التطبيق بهذا الرقم" error={errors.phone}>
        <input
          id="acc-phone"
          className="input"
          dir="ltr"
          type="tel"
          autoFocus
          aria-invalid={!!errors.phone}
          placeholder="059xxxxxxx"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
        />
      </Labeled>
      <Labeled
        id="acc-password"
        label={account ? 'كلمة مرور جديدة' : 'كلمة المرور'}
        hint={account ? 'اتركها فارغة للإبقاء على الحالية. تغييرها يسجّل خروج الطبيب من التطبيق' : '6 أحرف على الأقل. أرسلها للطبيب بعد الحفظ'}
        error={errors.password}
      >
        <div className="flex gap-2">
          {/* Plain text: the admin reads it out to the doctor. */}
          <input
            id="acc-password"
            className="input"
            dir="ltr"
            autoComplete="off"
            aria-invalid={!!errors.password}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
          <Button type="button" variant="soft" icon={<Wand2 className="size-4" />} onClick={() => setPassword(randomPassword())}>
            توليد
          </Button>
        </div>
      </Labeled>
      <div className="grid gap-4 sm:grid-cols-2">
        <Switch id="acc-active" label="الحساب" on={active} onChange={setActive} labels={['مفعّل', 'موقوف']} />
        <Switch id="acc-booking" label="الحجز عبر التطبيق" on={booking} onChange={setBooking} labels={['يستقبل حجوزات', 'لا يستقبل حجوزات']} />
      </div>
      {errors.doctor_id && <p className="text-xs font-bold text-red-500">هذا الطبيب مربوط بحساب بالفعل</p>}
      <Button type="submit" loading={save.isPending} icon={<Save className="size-4" />}>
        {account ? 'حفظ التعديلات' : 'إنشاء الحساب'}
      </Button>
    </form>
  )
}

function Switch({ id, label, on, onChange, labels }: { id: string; label: string; on: boolean; onChange: (v: boolean) => void; labels: [string, string] }) {
  return (
    <Labeled id={id} label={label}>
      <div className="flex h-11 items-center gap-3">
        <Toggle id={id} checked={on} onChange={onChange} />
        <span className="text-sm text-ink-2">{labels[on ? 0 : 1]}</span>
      </div>
    </Labeled>
  )
}

function LinkExisting({
  doctor,
  accounts,
  doctorsById,
  onDone,
}: {
  doctor: Row
  accounts: Row[]
  doctorsById: Map<number, Row>
  onDone: () => void
}) {
  const [search, setSearch] = useState('')
  const [picked, setPicked] = useState<Row | null>(null)
  const save = useSave(RESOURCE)
  const owner = (a: Row) => (doctorsById.get(Number(a.doctor_id))?.name as string | undefined) ?? 'طبيب محذوف'

  const needle = search.trim()
  const shown = needle ? accounts.filter((a) => String(a.phone).includes(needle) || owner(a).includes(needle)) : accounts

  const link = async () => {
    if (!picked) return
    try {
      await save.mutateAsync({ id: picked.id, values: movedTo(picked, doctor.id) })
      toast.success('تم ربط الحساب بالطبيب', { description: String(doctor.name) })
      onDone()
    } catch (err) {
      setPicked(null)
      toast.error(errorText(err))
    }
  }

  if (!accounts.length) {
    return <p className="rounded-2xl bg-card-2 p-6 text-center text-sm text-muted">لا توجد حسابات بعد. أنشئ حساباً جديداً لهذا الطبيب.</p>
  }

  return (
    <div className="space-y-3">
      <div className="relative">
        <Search className="pointer-events-none absolute top-1/2 right-3 size-4 -translate-y-1/2 text-muted" />
        <input className="input ps-9" placeholder="ابحث برقم الهاتف أو اسم الطبيب..." value={search} onChange={(e) => setSearch(e.target.value)} />
      </div>
      {shown.length === 0 && <p className="p-4 text-center text-sm text-muted">لا توجد حسابات مطابقة</p>}
      <ul className="divide-y divide-line/70 overflow-hidden rounded-2xl border border-line">
        {shown.map((a) => (
          <li key={a.id}>
            <button type="button" onClick={() => setPicked(a)} className="flex w-full items-center gap-3 px-4 py-3 text-start transition hover:bg-card-2">
              <KeyRound className="size-4 shrink-0 text-muted" />
              <div className="min-w-0 flex-1">
                <div className="font-bold text-ink" dir="ltr" style={{ textAlign: 'right' }}>
                  {a.phone}
                </div>
                <div className="truncate text-xs text-muted">مربوط حالياً بـ {owner(a)}</div>
              </div>
              <span className="text-sm font-bold text-brand dark:text-blue-300">ربط</span>
            </button>
          </li>
        ))}
      </ul>
      <ConfirmDialog
        open={!!picked}
        emoji="🔗"
        title="ربط الحساب بهذا الطبيب؟"
        confirmLabel="ربط الحساب"
        loading={save.isPending}
        onConfirm={link}
        onClose={() => setPicked(null)}
        message={
          picked && (
            <p>
              سينتقل الحساب <b dir="ltr">{picked.phone}</b> من <b>{owner(picked)}</b> إلى <b>{String(doctor.name)}</b>. يصبح الطبيب السابق بدون حساب، وتُغلق
              الجلسة المفتوحة في التطبيق.
            </p>
          )
        }
      />
    </div>
  )
}

function MoveAccount({
  account,
  doctor,
  doctors,
  byDoctor,
  onDone,
}: {
  account: Row
  doctor: Row
  doctors: Row[]
  byDoctor: Map<number, Row>
  onDone: () => void
}) {
  const [target, setTarget] = useState('')
  const [confirming, setConfirming] = useState(false)
  const save = useSave(RESOURCE)
  // An account serves one doctor, so only doctors without one can receive it.
  const free = useMemo(() => doctors.filter((d) => !byDoctor.has(d.id)), [doctors, byDoctor])
  const targetDoctor = free.find((d) => String(d.id) === target)

  const move = async () => {
    if (!targetDoctor) return
    try {
      await save.mutateAsync({ id: account.id, values: movedTo(account, targetDoctor.id) })
      toast.success('تم نقل الحساب', { description: String(targetDoctor.name) })
      onDone()
    } catch (err) {
      setConfirming(false)
      toast.error(errorText(err))
    }
  }

  return (
    <section className="space-y-3 border-t border-line pt-5">
      <Labeled id="acc-move" label="نقل هذا الحساب إلى طبيب آخر" hint="تظهر هنا الأطباء الذين ليس لديهم حساب فقط">
        <div className="flex gap-2">
          <select id="acc-move" className="input" value={target} onChange={(e) => setTarget(e.target.value)}>
            <option value="">اختر الطبيب</option>
            {free.map((d) => (
              <option key={d.id} value={d.id}>
                {d.name} (#{d.id})
              </option>
            ))}
          </select>
          <Button type="button" variant="soft" disabled={!targetDoctor} icon={<ArrowLeftRight className="size-4" />} onClick={() => setConfirming(true)}>
            نقل
          </Button>
        </div>
      </Labeled>
      <ConfirmDialog
        open={confirming}
        emoji="🔁"
        title="نقل الحساب؟"
        confirmLabel="نقل الحساب"
        loading={save.isPending}
        onConfirm={move}
        onClose={() => setConfirming(false)}
        message={
          <p>
            سينتقل الحساب <b dir="ltr">{account.phone}</b> من <b>{String(doctor.name)}</b> إلى <b>{String(targetDoctor?.name ?? '')}</b>. يصبح{' '}
            {String(doctor.name)} بدون حساب، وتُغلق الجلسة المفتوحة في التطبيق.
          </p>
        }
      />
    </section>
  )
}

function DeleteAccount({ account, doctor, onDone }: { account: Row; doctor: Row; onDone: () => void }) {
  const [confirming, setConfirming] = useState(false)
  const remove = useRemove(RESOURCE)

  const destroy = async () => {
    try {
      await remove.mutateAsync([account.id])
      toast.success('تم حذف الحساب')
      onDone()
    } catch (err) {
      setConfirming(false)
      toast.error(errorText(err))
    }
  }

  return (
    <section className="border-t border-line pt-5">
      <Button
        type="button"
        variant="ghost"
        className="text-red-600! hover:bg-red-50! dark:hover:bg-red-500/15!"
        icon={<Trash2 className="size-4" />}
        onClick={() => setConfirming(true)}
      >
        حذف الحساب
      </Button>
      <ConfirmDialog
        open={confirming}
        title="حذف حساب الطبيب؟"
        confirmLabel="حذف الحساب"
        loading={remove.isPending}
        onConfirm={destroy}
        onClose={() => setConfirming(false)}
        message={
          <p>
            لن يتمكن <b>{String(doctor.name)}</b> من الدخول، ويتوقف الحجز عبر التطبيق عنده. المواعيد السابقة تبقى محفوظة.
          </p>
        }
      />
    </section>
  )
}
