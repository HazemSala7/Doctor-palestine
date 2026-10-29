import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { Navigate, useParams, useSearchParams } from 'react-router-dom'
import { toast } from 'sonner'
import {
  ArrowDownWideNarrow,
  ArrowUpNarrowWide,
  ChevronLeft,
  ChevronRight,
  Copy,
  Pencil,
  Plus,
  Search,
  Trash2,
  X,
  RefreshCw,
} from 'lucide-react'
import type { ListParams, Row } from '../lib/api'
import { RESOURCE_MAP, type Field, type Resource } from '../lib/resources'
import { prefetchList, rowTitle, useList, useLookup, useRemove } from '../lib/queries'
import { formatNumber, timeAgo, useDebounced, useHotkey } from '../lib/hooks'
import { Avatar, Button, ConfirmDialog, EmptyState, IconButton, Kbd, cx } from '../components/ui'
import { ResourceForm } from '../components/ResourceForm'

const PER_PAGE = [10, 25, 50, 100]

export default function ResourcePage() {
  const { resource: key = '' } = useParams()
  const resource = RESOURCE_MAP[key]
  if (!resource) return <Navigate to="/" replace />
  // Remount per resource so local state never leaks between sections.
  return <ResourceView key={key} resource={resource} />
}

function ResourceView({ resource }: { resource: Resource }) {
  const [sp, setSp] = useSearchParams()
  const page = Number(sp.get('page') ?? 1)
  const perPage = Number(sp.get('per') ?? (resource.gallery ? 25 : 10))
  const sort = sp.get('sort') ?? '-id'
  const [search, setSearch] = useState(sp.get('q') ?? '')
  const q = useDebounced(search.trim(), 250)
  const filterFields = resource.fields.filter((f) => f.filter)
  const filters = useMemo(
    () => Object.fromEntries(filterFields.map((f) => [f.key, sp.get(f.key) ?? undefined])),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [sp],
  )

  const update = useCallback(
    (patch: Record<string, string | number | undefined>, resetPage = true) => {
      setSp(
        (prev) => {
          const next = new URLSearchParams(prev)
          for (const [k, v] of Object.entries(patch)) {
            if (v === undefined || v === '') next.delete(k)
            else next.set(k, String(v))
          }
          if (resetPage && !('page' in patch)) next.delete('page')
          return next
        },
        { replace: true },
      )
    },
    [setSp],
  )

  useEffect(() => {
    if ((sp.get('q') ?? '') !== q) update({ q: q || undefined })
  }, [q]) // eslint-disable-line react-hooks/exhaustive-deps

  const params: ListParams = { page, perPage, q: q || undefined, sort, filters }
  const list = useList(resource.key, params)
  const rows = list.data?.data ?? []
  const total = list.data?.total ?? 0
  const lastPage = list.data?.lastPage ?? 1

  // Warm the next page so paging feels instant.
  useEffect(() => {
    if (list.data && page < lastPage) prefetchList(resource.key, { ...params, page: page + 1 })
  }, [list.data]) // eslint-disable-line react-hooks/exhaustive-deps

  const [editing, setEditing] = useState<Partial<Row> | null | undefined>(undefined)
  const [selected, setSelected] = useState<Set<number>>(new Set())
  const [confirmIds, setConfirmIds] = useState<number[] | null>(null)
  const remove = useRemove(resource.key)
  const searchRef = useRef<HTMLInputElement>(null)

  useEffect(() => setSelected(new Set()), [page, q, sort, filters])

  // Open the form straight away when arriving from "add" shortcuts (?new=1).
  useEffect(() => {
    if (sp.get('new')) {
      setEditing(null)
      update({ new: undefined }, false)
    }
  }, [sp]) // eslint-disable-line react-hooks/exhaustive-deps

  useHotkey('n', useCallback(() => setEditing(null), []))
  useHotkey('/', useCallback(() => searchRef.current?.focus(), []))

  const doDelete = async () => {
    if (!confirmIds) return
    const ids = confirmIds
    setConfirmIds(null)
    try {
      await remove.mutateAsync(ids)
      setSelected((s) => new Set([...s].filter((id) => !ids.includes(id))))
      toast.success(ids.length > 1 ? `تم حذف ${ids.length} سجلات` : 'تم الحذف')
      // Step back if the last row of the last page went away.
      if (rows.length === ids.length && page > 1) update({ page: page - 1 }, false)
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'تعذّر الحذف')
    }
  }

  const duplicate = (row: Row) => {
    const { id: _, created_at: __, updated_at: ___, ...rest } = row
    const t = resource.titleField
    setEditing(t !== 'id' ? { ...rest, [t]: `${rest[t]} (نسخة)` } : rest)
  }

  const allOnPage = rows.length > 0 && rows.every((r) => selected.has(r.id))
  const toggleAll = () =>
    setSelected((s) => {
      const next = new Set(s)
      rows.forEach((r) => (allOnPage ? next.delete(r.id) : next.add(r.id)))
      return next
    })
  const toggle = (id: number) =>
    setSelected((s) => {
      const next = new Set(s)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })

  const activeFilters = Object.values(filters).filter(Boolean).length + (q ? 1 : 0)
  const Icon = resource.icon

  return (
    <div className="animate-fade-up space-y-5">
      {/* Header */}
      <div className="flex flex-wrap items-center gap-4">
        <div
          className="grid size-14 place-items-center rounded-2xl text-white shadow-lg"
          style={{ background: `linear-gradient(135deg, ${resource.color}, ${resource.color}aa)` }}
        >
          <Icon className="size-7" />
        </div>
        <div className="flex-1">
          <h1 className="text-2xl font-black">{resource.label}</h1>
          <p className="text-sm text-muted">
            {list.isLoading ? 'جارِ التحميل...' : `${formatNumber(total)} ${activeFilters ? 'نتيجة مطابقة' : 'سجل'}`}
          </p>
        </div>
        <IconButton label="تحديث" onClick={() => list.refetch()}>
          <RefreshCw className={cx('size-4', list.isFetching && 'animate-spin')} />
        </IconButton>
        <Button onClick={() => setEditing(null)} icon={<Plus className="size-4" />}>
          إضافة {resource.singular}
          <Kbd>N</Kbd>
        </Button>
      </div>

      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-2 rounded-2xl border border-line bg-card p-2">
        <div className="relative min-w-56 flex-1">
          <Search className="pointer-events-none absolute top-1/2 right-3 size-4 -translate-y-1/2 text-muted" />
          <input
            ref={searchRef}
            className="input border-transparent bg-card-2 ps-9 pe-16"
            placeholder={`ابحث في ${resource.label}...`}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <span className="absolute top-1/2 left-3 -translate-y-1/2">
            {search ? (
              <button onClick={() => setSearch('')} className="text-muted hover:text-ink" aria-label="مسح البحث">
                <X className="size-4" />
              </button>
            ) : (
              <Kbd>/</Kbd>
            )}
          </span>
        </div>
        {filterFields.map((f) => (
          <FilterSelect key={f.key} field={f} value={filters[f.key]} onChange={(v) => update({ [f.key]: v })} />
        ))}
        {activeFilters > 0 && (
          <Button
            variant="ghost"
            onClick={() => {
              setSearch('')
              update(Object.fromEntries([...filterFields.map((f) => [f.key, undefined]), ['q', undefined]]))
            }}
          >
            مسح الفلاتر
          </Button>
        )}
      </div>

      {/* Bulk actions */}
      {selected.size > 0 && (
        <div className="animate-pop flex items-center gap-3 rounded-2xl bg-brand-dark px-4 py-2.5 text-white shadow-lg">
          <span className="font-bold">تم تحديد {formatNumber(selected.size)}</span>
          <button className="text-sm text-white/80 underline-offset-2 hover:underline" onClick={() => setSelected(new Set())}>
            إلغاء التحديد
          </button>
          <Button variant="danger" className="ms-auto h-9" icon={<Trash2 className="size-4" />} onClick={() => setConfirmIds([...selected])}>
            حذف المحدد
          </Button>
        </div>
      )}

      {/* Content */}
      <div className={cx('transition-opacity', list.isPlaceholderData && 'opacity-60')}>
        {list.isLoading ? (
          <TableSkeleton />
        ) : list.isError ? (
          <EmptyState emoji="⚠️" title="تعذّر تحميل البيانات">
            {(list.error as Error).message}
            <div className="mt-4">
              <Button variant="soft" onClick={() => list.refetch()}>
                إعادة المحاولة
              </Button>
            </div>
          </EmptyState>
        ) : rows.length === 0 ? (
          <EmptyState emoji={activeFilters ? '🔍' : resource.emoji} title={activeFilters ? 'لا توجد نتائج مطابقة' : `لا يوجد ${resource.label} بعد`}>
            {activeFilters ? 'جرّب كلمة بحث أخرى أو امسح الفلاتر.' : (
              <Button className="mt-4" onClick={() => setEditing(null)} icon={<Plus className="size-4" />}>
                أضف أول {resource.singular}
              </Button>
            )}
          </EmptyState>
        ) : resource.gallery ? (
          <Gallery
            resource={resource}
            rows={rows}
            selected={selected}
            onToggle={toggle}
            onEdit={setEditing}
            onDelete={(id) => setConfirmIds([id])}
          />
        ) : (
          <Table
            resource={resource}
            rows={rows}
            sort={sort}
            onSort={(k) => update({ sort: sort === k ? `-${k}` : k })}
            selected={selected}
            allOnPage={allOnPage}
            onToggle={toggle}
            onToggleAll={toggleAll}
            onEdit={setEditing}
            onDuplicate={duplicate}
            onDelete={(id) => setConfirmIds([id])}
          />
        )}
      </div>

      {total > 0 && (
        <Pagination
          page={page}
          lastPage={lastPage}
          total={total}
          perPage={perPage}
          onPage={(p) => update({ page: p === 1 ? undefined : p }, false)}
          onPerPage={(n) => update({ per: n })}
        />
      )}

      {editing !== undefined && <ResourceForm resource={resource} row={editing} onClose={() => setEditing(undefined)} />}

      <ConfirmDialog
        open={!!confirmIds}
        title={confirmIds && confirmIds.length > 1 ? `حذف ${confirmIds.length} سجلات؟` : `حذف ${resource.singular}؟`}
        message={
          <>
            {confirmIds?.length === 1 && (
              <b className="text-ink">{rowTitle(resource.key, rows.find((r) => r.id === confirmIds[0]) ?? { id: confirmIds[0] })}</b>
            )}
            <p>سيختفي من التطبيق فوراً. لا يمكن التراجع عن هذه العملية.</p>
          </>
        }
        loading={remove.isPending}
        onConfirm={doDelete}
        onClose={() => setConfirmIds(null)}
      />
    </div>
  )
}

function FilterSelect({ field, value, onChange }: { field: Field; value?: string; onChange: (v?: string) => void }) {
  const { rows } = useLookup(field.relation)
  const options =
    field.type === 'relation'
      ? rows.map((r) => ({ value: String(r.id), label: r.name as string }))
      : field.type === 'boolean'
        ? [
            { value: '1', label: 'مفعّل' },
            { value: '0', label: 'متوقف' },
          ]
        : field.options ?? []
  return (
    <select
      className={cx('input w-auto min-w-36 border-transparent bg-card-2', value && 'border-brand-light! text-brand font-bold')}
      value={value ?? ''}
      onChange={(e) => onChange(e.target.value || undefined)}
      aria-label={field.label}
    >
      <option value="">كل {field.label === 'المدينة' ? 'المدن' : field.label === 'التخصص' ? 'التخصصات' : field.label}</option>
      {options.map((o) => (
        <option key={o.value} value={o.value}>
          {o.label}
        </option>
      ))}
    </select>
  )
}

/** Renders one cell value the way a person would read it. */
function Cell({ field, row }: { field: Field; row: Row }) {
  const { byId } = useLookup(field.type === 'relation' ? field.relation : undefined)
  const v = row[field.key]
  if (v == null || v === '') return <span className="text-muted">—</span>
  switch (field.type) {
    case 'relation':
      return (
        <span className="inline-flex rounded-lg bg-card-2 px-2 py-0.5 text-xs font-bold text-ink-2">
          {(byId.get(Number(v))?.name as string) ?? `#${v}`}
        </span>
      )
    case 'select':
      return <span className="text-ink-2">{field.options?.find((o) => o.value === v)?.label ?? String(v)}</span>
    case 'boolean':
      return Number(v) ? (
        <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-bold text-emerald-700 dark:bg-emerald-500/15 dark:text-emerald-300">
          ● مفعّل
        </span>
      ) : (
        <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2 py-0.5 text-xs font-bold text-slate-500 dark:bg-slate-500/15">
          ○ متوقف
        </span>
      )
    case 'phone':
      return (
        <a dir="ltr" href={`tel:${v}`} onClick={(e) => e.stopPropagation()} className="text-ink-2 hover:text-brand">
          {String(v)}
        </a>
      )
    default:
      return <span className="line-clamp-1 text-ink-2">{String(v)}</span>
  }
}

function Table({
  resource,
  rows,
  sort,
  onSort,
  selected,
  allOnPage,
  onToggle,
  onToggleAll,
  onEdit,
  onDuplicate,
  onDelete,
}: {
  resource: Resource
  rows: Row[]
  sort: string
  onSort: (key: string) => void
  selected: Set<number>
  allOnPage: boolean
  onToggle: (id: number) => void
  onToggleAll: () => void
  onEdit: (row: Row) => void
  onDuplicate: (row: Row) => void
  onDelete: (id: number) => void
}) {
  const columns = resource.fields.filter((f) => f.column && f.key !== resource.titleField)
  const SortHead = ({ k, children, className }: { k: string; children: React.ReactNode; className?: string }) => {
    const active = sort.replace(/^-/, '') === k
    const SortIcon = sort.startsWith('-') ? ArrowDownWideNarrow : ArrowUpNarrowWide
    return (
      <th className={cx('px-3 py-3 text-start font-bold', className)}>
        <button onClick={() => onSort(k)} className={cx('inline-flex items-center gap-1 hover:text-ink', active && 'text-brand')}>
          {children}
          {active && <SortIcon className="size-3.5" />}
        </button>
      </th>
    )
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-line bg-card shadow-sm">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="border-b border-line bg-card-2 text-xs text-muted">
            <tr>
              <th className="w-10 px-3 py-3">
                <input type="checkbox" className="size-4 accent-brand" checked={allOnPage} onChange={onToggleAll} aria-label="تحديد الكل" />
              </th>
              <SortHead k={resource.titleField}>{resource.fields.find((f) => f.key === resource.titleField)?.label}</SortHead>
              {columns.map((f) => (
                <SortHead key={f.key} k={f.key} className="hidden md:table-cell">
                  {f.label}
                </SortHead>
              ))}
              <SortHead k="id" className="hidden lg:table-cell">
                أضيف
              </SortHead>
              <th className="w-32 px-3 py-3" />
            </tr>
          </thead>
          <tbody>
            {rows.map((row, i) => (
              <tr
                key={row.id}
                onClick={() => onEdit(row)}
                className={cx(
                  'group animate-fade-up cursor-pointer border-b border-line/70 transition last:border-0 hover:bg-card-2',
                  selected.has(row.id) && 'bg-brand-sky/50 dark:bg-blue-500/10',
                )}
                style={{ animationDelay: `${Math.min(i, 12) * 18}ms` }}
              >
                <td className="px-3 py-2.5" onClick={(e) => e.stopPropagation()}>
                  <input type="checkbox" className="size-4 accent-brand" checked={selected.has(row.id)} onChange={() => onToggle(row.id)} aria-label="تحديد" />
                </td>
                <td className="px-3 py-2.5">
                  <div className="flex items-center gap-3">
                    {resource.imageField && (
                      <Avatar src={row[resource.imageField]} name={rowTitle(resource.key, row)} round={resource.key === 'doctors'} />
                    )}
                    <div className="min-w-0">
                      <div className="truncate font-bold text-ink">{rowTitle(resource.key, row)}</div>
                      <div className="text-xs text-muted">#{row.id}</div>
                    </div>
                  </div>
                </td>
                {columns.map((f) => (
                  <td key={f.key} className="hidden max-w-60 px-3 py-2.5 md:table-cell">
                    <Cell field={f} row={row} />
                  </td>
                ))}
                <td className="hidden px-3 py-2.5 text-xs whitespace-nowrap text-muted lg:table-cell">{timeAgo(row.created_at)}</td>
                <td className="px-3 py-2.5" onClick={(e) => e.stopPropagation()}>
                  <div className="flex justify-end gap-0.5 opacity-60 transition group-hover:opacity-100">
                    <IconButton label="تعديل" onClick={() => onEdit(row)}>
                      <Pencil className="size-4" />
                    </IconButton>
                    <IconButton label="نسخ كسجل جديد" onClick={() => onDuplicate(row)}>
                      <Copy className="size-4" />
                    </IconButton>
                    <IconButton label="حذف" className="hover:bg-red-50! hover:text-red-600! dark:hover:bg-red-500/15!" onClick={() => onDelete(row.id)}>
                      <Trash2 className="size-4" />
                    </IconButton>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function Gallery({
  resource,
  rows,
  selected,
  onToggle,
  onEdit,
  onDelete,
}: {
  resource: Resource
  rows: Row[]
  selected: Set<number>
  onToggle: (id: number) => void
  onEdit: (row: Row) => void
  onDelete: (id: number) => void
}) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
      {rows.map((row, i) => (
        <div
          key={row.id}
          className={cx(
            'group animate-fade-up relative overflow-hidden rounded-2xl border bg-card shadow-sm transition hover:-translate-y-0.5 hover:shadow-xl',
            selected.has(row.id) ? 'border-brand-light ring-2 ring-brand-light' : 'border-line',
          )}
          style={{ animationDelay: `${i * 40}ms` }}
        >
          <button className="block aspect-[12/5] w-full bg-card-2" onClick={() => onEdit(row)}>
            {row[resource.imageField!] ? (
              <img src={row[resource.imageField!]} alt="" loading="lazy" className="size-full object-cover" />
            ) : (
              <span className="text-muted">بدون صورة</span>
            )}
          </button>
          <div className="flex items-center gap-2 px-3 py-2">
            <input type="checkbox" className="size-4 accent-brand" checked={selected.has(row.id)} onChange={() => onToggle(row.id)} aria-label="تحديد" />
            <span className="text-sm font-bold">#{row.id}</span>
            <span className="text-xs text-muted">{timeAgo(row.created_at)}</span>
            <div className="ms-auto flex gap-0.5">
              <IconButton label="تغيير الصورة" onClick={() => onEdit(row)}>
                <Pencil className="size-4" />
              </IconButton>
              <IconButton label="حذف" className="hover:bg-red-50! hover:text-red-600!" onClick={() => onDelete(row.id)}>
                <Trash2 className="size-4" />
              </IconButton>
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}

function Pagination({
  page,
  lastPage,
  total,
  perPage,
  onPage,
  onPerPage,
}: {
  page: number
  lastPage: number
  total: number
  perPage: number
  onPage: (p: number) => void
  onPerPage: (n: number) => void
}) {
  // Current page with two neighbours, plus first and last.
  const pages = [...new Set([1, page - 2, page - 1, page, page + 1, page + 2, lastPage])]
    .filter((p) => p >= 1 && p <= lastPage)
    .sort((a, b) => a - b)
  const from = (page - 1) * perPage + 1
  const to = Math.min(page * perPage, total)

  return (
    <div className="flex flex-wrap items-center justify-between gap-3 text-sm">
      <div className="flex items-center gap-2 text-muted">
        <span>
          عرض {formatNumber(from)}–{formatNumber(to)} من {formatNumber(total)}
        </span>
        <select className="input h-9 w-auto py-1" value={perPage} onChange={(e) => onPerPage(Number(e.target.value))} aria-label="عدد الصفوف">
          {PER_PAGE.map((n) => (
            <option key={n} value={n}>
              {n} / صفحة
            </option>
          ))}
        </select>
      </div>
      {lastPage > 1 && (
        <div className="flex items-center gap-1">
          <IconButton label="السابق" disabled={page <= 1} onClick={() => onPage(page - 1)} className="disabled:opacity-30">
            <ChevronRight className="size-4" />
          </IconButton>
          {pages.map((p, i) => (
            <span key={p} className="flex items-center gap-1">
              {i > 0 && p - pages[i - 1] > 1 && <span className="px-1 text-muted">…</span>}
              <button
                onClick={() => onPage(p)}
                className={cx(
                  'focus-ring size-9 rounded-xl font-bold transition',
                  p === page ? 'brand-gradient text-white shadow-md' : 'text-ink-2 hover:bg-card-2',
                )}
              >
                {p}
              </button>
            </span>
          ))}
          <IconButton label="التالي" disabled={page >= lastPage} onClick={() => onPage(page + 1)} className="disabled:opacity-30">
            <ChevronLeft className="size-4" />
          </IconButton>
        </div>
      )}
    </div>
  )
}

function TableSkeleton() {
  return (
    <div className="space-y-px overflow-hidden rounded-2xl border border-line bg-card p-4">
      {Array.from({ length: 6 }, (_, i) => (
        <div key={i} className="flex items-center gap-3 py-2.5">
          <div className="skeleton size-10 rounded-xl" />
          <div className="flex-1 space-y-2">
            <div className="skeleton h-3.5 w-1/3" />
            <div className="skeleton h-3 w-1/5" />
          </div>
          <div className="skeleton hidden h-3.5 w-24 md:block" />
          <div className="skeleton hidden h-3.5 w-24 md:block" />
        </div>
      ))}
    </div>
  )
}
