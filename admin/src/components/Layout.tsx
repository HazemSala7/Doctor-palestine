import { useCallback, useEffect, useState } from 'react'
import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { LayoutDashboard, LogOut, Menu, Moon, RotateCcw, Search, Sun, X } from 'lucide-react'
import { toast } from 'sonner'
import { api } from '../lib/api'
import { GROUPS, RESOURCES } from '../lib/resources'
import { prefetchList, queryClient, useStats } from '../lib/queries'
import { formatNumber, useHotkey, useTheme } from '../lib/hooks'
import { useAuth } from '../lib/auth'
import { CommandPalette } from './CommandPalette'
import { Avatar, IconButton, Kbd, cx } from './ui'

export default function Layout() {
  const [paletteOpen, setPaletteOpen] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)
  const [dark, setDark] = useTheme()
  const { user, logout } = useAuth()
  const { data: stats } = useStats()
  const location = useLocation()

  useEffect(() => setMenuOpen(false), [location.pathname])
  useHotkey('k', useCallback(() => setPaletteOpen(true), []), { mod: true })

  const resetDemo = async () => {
    if (!confirm('سيتم حذف كل التغييرات وإرجاع البيانات التجريبية الأصلية. متابعة؟')) return
    await api.reset?.()
    await queryClient.invalidateQueries()
    toast.success('تمت إعادة البيانات التجريبية')
  }

  const sidebar = (
    <nav className="flex h-full flex-col">
      <div className="flex items-center gap-3 px-5 py-5">
        <img src="./logo.png" alt="" className="size-11 rounded-2xl bg-white p-1 shadow-md" />
        <div>
          <div className="text-lg leading-tight font-black">طبيبك</div>
          <div className="text-xs text-muted">لوحة التحكم</div>
        </div>
      </div>
      <div className="flex-1 space-y-5 overflow-y-auto px-3 pb-4">
        <NavItem to="/" end icon={<LayoutDashboard className="size-[18px]" />} label="الرئيسية" />
        {GROUPS.map((g) => (
          <div key={g}>
            <div className="mb-1 px-3 text-[11px] font-black tracking-wide text-muted">{g}</div>
            {RESOURCES.filter((r) => r.group === g).map((r) => (
              <NavItem
                key={r.key}
                to={`/r/${r.key}`}
                icon={<r.icon className="size-[18px]" />}
                label={r.label}
                count={stats?.counts[r.key]}
                color={r.color}
                // Fetch the first page on hover so the click lands on data.
                onHover={() => prefetchList(r.key, { page: 1, perPage: r.gallery ? 25 : 10, sort: '-id', filters: {} })}
              />
            ))}
          </div>
        ))}
      </div>
      <div className="border-t border-line p-3">
        <div className="flex items-center gap-3 rounded-xl p-2">
          <Avatar name={user?.name ?? 'م'} size={36} round />
          <div className="min-w-0 flex-1">
            <div className="truncate text-sm font-bold">{user?.name}</div>
            <div className="truncate text-xs text-muted" dir="ltr">
              {user?.email}
            </div>
          </div>
          <IconButton label="تسجيل الخروج" onClick={logout}>
            <LogOut className="size-4" />
          </IconButton>
        </div>
      </div>
    </nav>
  )

  return (
    <div className="flex min-h-full">
      <aside className="sticky top-0 hidden h-screen w-72 shrink-0 border-e border-line bg-card lg:block">{sidebar}</aside>

      {menuOpen && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <div className="animate-fade absolute inset-0 bg-slate-950/40" onClick={() => setMenuOpen(false)} />
          <aside className="animate-fade absolute inset-y-0 right-0 w-72 bg-card shadow-2xl">
            <IconButton label="إغلاق" className="absolute top-5 left-3" onClick={() => setMenuOpen(false)}>
              <X className="size-5" />
            </IconButton>
            {sidebar}
          </aside>
        </div>
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 flex items-center gap-3 border-b border-line bg-bg/80 px-4 py-3 backdrop-blur-lg sm:px-6">
          <IconButton label="القائمة" className="lg:hidden" onClick={() => setMenuOpen(true)}>
            <Menu className="size-5" />
          </IconButton>
          <button
            onClick={() => setPaletteOpen(true)}
            className="focus-ring flex h-10 max-w-md flex-1 items-center gap-2 rounded-xl border border-line bg-card px-3 text-sm text-muted transition hover:border-brand-light"
          >
            <Search className="size-4" />
            <span className="flex-1 text-start">بحث سريع وانتقال...</span>
            <Kbd>Ctrl K</Kbd>
          </button>
          <div className="ms-auto flex items-center gap-1">
            {api.mode === 'demo' ? (
              <>
                <span className="hidden rounded-full bg-amber-100 px-3 py-1 text-xs font-bold text-amber-800 sm:inline dark:bg-amber-500/15 dark:text-amber-300">
                  وضع تجريبي
                </span>
                <IconButton label="إعادة البيانات التجريبية" onClick={resetDemo}>
                  <RotateCcw className="size-4" />
                </IconButton>
              </>
            ) : (
              <span className="hidden items-center gap-1.5 rounded-full bg-emerald-100 px-3 py-1 text-xs font-bold text-emerald-800 sm:inline-flex dark:bg-emerald-500/15 dark:text-emerald-300">
                <span className="size-2 animate-pulse rounded-full bg-emerald-500" /> متصل بالسيرفر
              </span>
            )}
            <IconButton label={dark ? 'الوضع الفاتح' : 'الوضع الداكن'} onClick={() => setDark(!dark)}>
              {dark ? <Sun className="size-4" /> : <Moon className="size-4" />}
            </IconButton>
          </div>
        </header>
        <main className="mx-auto w-full max-w-7xl flex-1 p-4 sm:p-6">
          <Outlet />
        </main>
      </div>

      <CommandPalette open={paletteOpen} onClose={() => setPaletteOpen(false)} />
    </div>
  )
}

function NavItem({
  to,
  end,
  icon,
  label,
  count,
  color,
  onHover,
}: {
  to: string
  end?: boolean
  icon: React.ReactNode
  label: string
  count?: number
  color?: string
  onHover?: () => void
}) {
  return (
    <NavLink
      to={to}
      end={end}
      onMouseEnter={onHover}
      className={({ isActive }) =>
        cx(
          'group flex items-center gap-3 rounded-xl px-3 py-2 text-sm font-bold transition',
          isActive ? 'brand-gradient text-white shadow-md shadow-blue-600/25' : 'text-ink-2 hover:bg-card-2 hover:text-ink',
        )
      }
    >
      {({ isActive }) => (
        <>
          <span style={!isActive && color ? { color } : undefined}>{icon}</span>
          <span className="flex-1">{label}</span>
          {count !== undefined && (
            <span
              className={cx(
                'rounded-md px-1.5 text-[11px] tabular-nums',
                isActive ? 'bg-white/20 text-white' : 'bg-card-2 text-muted group-hover:bg-card',
              )}
            >
              {formatNumber(count)}
            </span>
          )}
        </>
      )}
    </NavLink>
  )
}
