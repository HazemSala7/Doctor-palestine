import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Plus, ArrowLeft } from 'lucide-react'
import { RESOURCE_MAP, RESOURCES } from '../lib/resources'
import { rowTitle, useLookup, useStats } from '../lib/queries'
import { formatNumber, timeAgo } from '../lib/hooks'
import { useAuth } from '../lib/auth'
import { Avatar, cx } from '../components/ui'

/** Animates a number up from 0 once it is known. */
function CountUp({ value }: { value: number }) {
  const [n, setN] = useState(0)
  useEffect(() => {
    let raf = 0
    const start = performance.now()
    const tick = (t: number) => {
      const p = Math.min(1, (t - start) / 700)
      setN(Math.round(value * (1 - Math.pow(1 - p, 3))))
      if (p < 1) raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [value])
  return <>{formatNumber(n)}</>
}

const CENTRES = RESOURCES.filter((r) => r.group === 'المراكز الطبية')

export default function Dashboard() {
  const { data, isLoading } = useStats()
  const { user } = useAuth()
  const cities = useLookup('cities')
  const categories = useLookup('doctor-categories')
  const navigate = useNavigate()
  const counts = data?.counts ?? {}
  const centresTotal = CENTRES.reduce((s, r) => s + (counts[r.key] ?? 0), 0)
  const hour = new Date().getHours()
  const greeting = hour < 12 ? 'صباح الخير' : 'مساء الخير'

  const tiles = [
    { label: 'الأطباء', value: counts.doctors, emoji: '🩺', to: '/r/doctors', from: '#0a3d91', toC: '#42a5f5' },
    { label: 'المراكز الطبية', value: centresTotal, emoji: '🏥', to: '/r/hospitals', from: '#00897b', toC: '#4dd0e1' },
    { label: 'المدن', value: counts.cities, emoji: '🗺️', to: '/r/cities', from: '#ef6c00', toC: '#ffb74d' },
    { label: 'الوظائف', value: counts.jobs, emoji: '💼', to: '/r/jobs', from: '#5e35b1', toC: '#9575cd' },
  ]

  return (
    <div className="space-y-6">
      {/* Hero */}
      <section className="brand-gradient animate-fade-up relative overflow-hidden rounded-3xl p-6 text-white shadow-xl shadow-blue-900/20 sm:p-8">
        <div className="absolute -top-16 -left-16 size-64 rounded-full bg-white/10" />
        <div className="absolute -bottom-24 left-40 size-56 rounded-full bg-white/5" />
        <div className="relative flex flex-wrap items-center gap-6">
          <div className="flex-1">
            <p className="text-white/80">
              {greeting}، {user?.name} 👋
            </p>
            <h1 className="mt-1 text-3xl font-black sm:text-4xl">لوحة تحكم طبيبك</h1>
            <p className="mt-2 max-w-lg text-white/85">
              أدِر الأطباء والمراكز الطبية والمحتوى في مكان واحد. كل تعديل يظهر في التطبيق مباشرة.
            </p>
            <div className="mt-5 flex flex-wrap gap-2">
              {['doctors', 'pharmacies', 'jobs', 'sliders'].map((k) => (
                <Link
                  key={k}
                  to={`/r/${k}?new=1`}
                  className="inline-flex items-center gap-1.5 rounded-xl bg-white/15 px-3.5 py-2 text-sm font-bold backdrop-blur transition hover:bg-white/25"
                >
                  <Plus className="size-4" /> {RESOURCE_MAP[k].singular}
                </Link>
              ))}
            </div>
          </div>
          <img src="./logo.png" alt="" className="hidden size-32 rounded-3xl bg-white p-3 shadow-2xl sm:block" />
        </div>
      </section>

      {/* Headline numbers */}
      <section className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        {tiles.map((t, i) => (
          <Link
            key={t.label}
            to={t.to}
            className="group animate-fade-up relative overflow-hidden rounded-2xl border border-line bg-card p-5 shadow-sm transition hover:-translate-y-1 hover:shadow-xl"
            style={{ animationDelay: `${80 + i * 60}ms` }}
          >
            <div
              className="absolute -top-6 -left-6 size-24 rounded-full opacity-15 transition group-hover:scale-125"
              style={{ background: `linear-gradient(135deg, ${t.from}, ${t.toC})` }}
            />
            <div className="text-3xl">{t.emoji}</div>
            <div className="mt-3 text-3xl font-black">
              {isLoading ? <span className="skeleton inline-block h-8 w-16" /> : <CountUp value={t.value ?? 0} />}
            </div>
            <div className="text-sm font-bold text-muted">{t.label}</div>
          </Link>
        ))}
      </section>

      <section className="grid gap-6 xl:grid-cols-5">
        {/* Records per section */}
        <Card title="عدد السجلات في كل قسم" className="xl:col-span-3">
          <BarList
            loading={isLoading}
            items={RESOURCES.filter((r) => r.key !== 'doctors').map((r) => ({
              key: r.key,
              label: r.label,
              emoji: r.emoji,
              value: counts[r.key] ?? 0,
              onClick: () => navigate(`/r/${r.key}`),
            }))}
          />
        </Card>

        {/* Recent */}
        <Card title="أحدث الإضافات" className="xl:col-span-2">
          {isLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 6 }, (_, i) => (
                <div key={i} className="skeleton h-12" />
              ))}
            </div>
          ) : (
            <ul className="-mx-2">
              {data?.recent.map(({ resource, row }, i) => {
                const res = RESOURCE_MAP[resource]
                return (
                  <li key={`${resource}-${row.id}`} className="animate-fade-up" style={{ animationDelay: `${i * 40}ms` }}>
                    <Link to={`/r/${resource}?q=${encodeURIComponent(rowTitle(resource, row))}`} className="flex items-center gap-3 rounded-xl p-2 transition hover:bg-card-2">
                      <Avatar src={res.imageField ? row[res.imageField] : null} name={rowTitle(resource, row)} size={38} round={resource === 'doctors'} />
                      <div className="min-w-0 flex-1">
                        <div className="truncate text-sm font-bold">{rowTitle(resource, row)}</div>
                        <div className="text-xs text-muted">
                          {res.emoji} {res.singular} · {timeAgo(row.created_at)}
                        </div>
                      </div>
                      <ArrowLeft className="size-4 text-muted" />
                    </Link>
                  </li>
                )
              })}
            </ul>
          )}
        </Card>
      </section>

      <section className="grid gap-6 lg:grid-cols-2">
        <Card title="الأطباء حسب المدينة">
          <BarList
            loading={isLoading || cities.isLoading}
            items={(data?.doctorsByCity ?? [])
              .map((c) => ({
                key: String(c.id),
                label: (cities.byId.get(c.id)?.name as string) ?? `#${c.id}`,
                value: c.count,
                onClick: () => navigate(`/r/doctors?city_id=${c.id}`),
              }))
              .sort((a, b) => b.value - a.value)}
          />
        </Card>
        <Card title="الأطباء حسب التخصص">
          <BarList
            loading={isLoading || categories.isLoading}
            items={(data?.doctorsByCategory ?? [])
              .map((c) => ({
                key: String(c.id),
                label: (categories.byId.get(c.id)?.name as string) ?? `#${c.id}`,
                value: c.count,
                onClick: () => navigate(`/r/doctors?category_id=${c.id}`),
              }))
              .sort((a, b) => b.value - a.value)}
          />
        </Card>
      </section>
    </div>
  )
}

function Card({ title, className, children }: { title: string; className?: string; children: React.ReactNode }) {
  return (
    <div className={cx('animate-fade-up rounded-2xl border border-line bg-card p-5 shadow-sm', className)} style={{ animationDelay: '200ms' }}>
      <h2 className="mb-4 font-black">{title}</h2>
      {children}
    </div>
  )
}

/**
 * Horizontal bars, one series, labelled directly. Each bar opens the
 * matching filtered list.
 */
function BarList({
  items,
  loading,
}: {
  items: { key: string; label: string; emoji?: string; value: number; onClick: () => void }[]
  loading?: boolean
}) {
  if (loading)
    return (
      <div className="space-y-3">
        {Array.from({ length: 6 }, (_, i) => (
          <div key={i} className="skeleton h-7" />
        ))}
      </div>
    )
  if (!items.length) return <p className="py-8 text-center text-sm text-muted">لا توجد بيانات بعد</p>
  const max = Math.max(...items.map((i) => i.value), 1)
  return (
    <ul className="space-y-1">
      {items.map((it, i) => (
        <li key={it.key}>
          <button
            onClick={it.onClick}
            title={`${it.label}: ${formatNumber(it.value)}`}
            className="group flex w-full items-center gap-3 rounded-lg px-1 py-1.5 text-sm transition hover:bg-card-2"
          >
            <span className="w-36 shrink-0 truncate text-start font-bold text-ink-2 group-hover:text-ink">
              {it.emoji && <span className="me-1">{it.emoji}</span>}
              {it.label}
            </span>
            <span className="relative h-5 flex-1">
              <span
                className="animate-grow-x absolute inset-y-0 right-0 rounded-s-[4px] rounded-e-[4px] bg-brand transition group-hover:bg-brand-light"
                style={{ width: `${Math.max((it.value / max) * 100, it.value ? 1.5 : 0)}%`, animationDelay: `${i * 35}ms` }}
              />
            </span>
            <span className="w-10 shrink-0 text-end font-black tabular-nums">{formatNumber(it.value)}</span>
          </button>
        </li>
      ))}
    </ul>
  )
}
