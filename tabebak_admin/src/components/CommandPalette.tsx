import { useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { CornerDownLeft, LayoutDashboard, Plus, Search } from 'lucide-react'
import { api } from '../lib/api'
import { RESOURCES } from '../lib/resources'
import { useDebounced } from '../lib/hooks'
import { Avatar, Kbd, Modal, cx } from './ui'

interface Item {
  id: string
  label: string
  hint: string
  icon: React.ReactNode
  run: () => void
}

/** Ctrl+K: jump to any section, start a new record, or find a doctor or centre by name. */
export function CommandPalette({ open, onClose }: { open: boolean; onClose: () => void }) {
  const navigate = useNavigate()
  const [text, setText] = useState('')
  const [active, setActive] = useState(0)
  const q = useDebounced(text.trim(), 200)
  const listRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (open) {
      setText('')
      setActive(0)
    }
  }, [open])

  const searchable = RESOURCES.filter((r) => !r.gallery)
  const records = useQuery({
    queryKey: ['palette', q],
    enabled: open && q.length >= 2,
    queryFn: async () => {
      const results = await Promise.all(
        searchable.map((r) =>
          api.list(r.key, { page: 1, perPage: 4, q }).then((res) => res.data.map((row) => ({ r, row }))),
        ),
      )
      return results.flat().slice(0, 12)
    },
  })

  const go = (to: string) => () => {
    navigate(to)
    onClose()
  }

  const items: Item[] = useMemo(() => {
    const needle = text.trim()
    const match = (s: string) => !needle || s.includes(needle)
    const nav: Item[] = [
      { id: 'home', label: 'الرئيسية', hint: 'انتقال', icon: <LayoutDashboard className="size-4" />, run: go('/') },
      ...RESOURCES.map((r) => ({
        id: `go-${r.key}`,
        label: r.label,
        hint: 'انتقال',
        icon: <span>{r.emoji}</span>,
        run: go(`/r/${r.key}`),
      })),
      ...RESOURCES.map((r) => ({
        id: `new-${r.key}`,
        label: `إضافة ${r.singular}`,
        hint: 'جديد',
        icon: <Plus className="size-4" />,
        run: go(`/r/${r.key}?new=1`),
      })),
    ].filter((i) => match(i.label))
    const found: Item[] = (records.data ?? []).map(({ r, row }) => {
      const title = String(row[r.titleField] ?? '')
      return {
        id: `rec-${r.key}-${row.id}`,
        label: title,
        hint: r.singular,
        icon: <Avatar src={r.imageField ? row[r.imageField] : null} name={title} size={26} round={r.key === 'doctors'} />,
        run: go(`/r/${r.key}?q=${encodeURIComponent(title)}`),
      }
    })
    return [...found, ...nav.slice(0, needle ? 8 : 6 + RESOURCES.length)]
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [text, records.data])

  useEffect(() => setActive(0), [items.length])
  useEffect(() => {
    listRef.current?.querySelector(`[data-i="${active}"]`)?.scrollIntoView({ block: 'nearest' })
  }, [active])

  const onKey = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      setActive((a) => Math.min(a + 1, items.length - 1))
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      setActive((a) => Math.max(a - 1, 0))
    } else if (e.key === 'Enter') {
      e.preventDefault()
      items[active]?.run()
    }
  }

  return (
    <Modal open={open} onClose={onClose} className="max-w-xl">
      <div className="flex items-center gap-3 border-b border-line px-4">
        <Search className="size-5 text-muted" />
        <input
          autoFocus
          value={text}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={onKey}
          placeholder="ابحث عن طبيب، مركز، أو اكتب «إضافة»..."
          className="h-14 flex-1 bg-transparent outline-none placeholder:text-muted"
        />
        <Kbd>Esc</Kbd>
      </div>
      <div ref={listRef} className="max-h-[50vh] overflow-y-auto p-2">
        {records.isFetching && <div className="skeleton mx-2 my-1 h-9" />}
        {items.length === 0 && !records.isFetching && <p className="py-10 text-center text-sm text-muted">لا توجد نتائج</p>}
        {items.map((it, i) => (
          <button
            key={it.id}
            data-i={i}
            onMouseMove={() => setActive(i)}
            onClick={it.run}
            className={cx(
              'flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-start text-sm transition',
              i === active ? 'bg-brand-sky text-brand dark:bg-blue-500/15 dark:text-blue-200' : 'text-ink-2',
            )}
          >
            <span className="grid size-7 place-items-center">{it.icon}</span>
            <span className="flex-1 truncate font-bold">{it.label}</span>
            <span className="text-xs text-muted">{it.hint}</span>
            {i === active && <CornerDownLeft className="size-3.5" />}
          </button>
        ))}
      </div>
    </Modal>
  )
}
