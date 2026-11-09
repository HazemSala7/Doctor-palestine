import {
  keepPreviousData,
  QueryClient,
  useMutation,
  useQuery,
  useQueryClient,
} from '@tanstack/react-query'
import { useMemo } from 'react'
import { api, type ListParams, type ListResult, type Row, type Values } from './api'
import { RESOURCE_MAP } from './resources'

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 30_000, refetchOnWindowFocus: false, retry: 1 },
  },
})

export const keys = {
  list: (resource: string, params?: ListParams) =>
    params ? ['list', resource, params] : ['list', resource],
  all: (resource: string) => ['all', resource],
  stats: ['stats'],
}

export function useList(resource: string, params: ListParams) {
  return useQuery({
    queryKey: keys.list(resource, params),
    queryFn: () => api.list(resource, params),
    placeholderData: keepPreviousData,
  })
}

export function prefetchList(resource: string, params: ListParams) {
  return queryClient.prefetchQuery({
    queryKey: keys.list(resource, params),
    queryFn: () => api.list(resource, params),
  })
}

/** Whole small tables (cities, specialties) keyed by id, for labels and pickers. */
export function useLookup(resource: string | undefined) {
  const q = useQuery({
    queryKey: keys.all(resource ?? ''),
    queryFn: () => api.all(resource!),
    enabled: !!resource,
    staleTime: 5 * 60_000,
  })
  const byId = useMemo(() => new Map((q.data ?? []).map((r) => [r.id, r])), [q.data])
  return { rows: q.data ?? [], byId, isLoading: q.isLoading, isError: q.isError }
}

/** Every doctor's app login, keyed by doctor. */
export function useDoctorAccounts(enabled = true) {
  const { rows, isLoading, isError } = useLookup(enabled ? 'doctor-accounts' : undefined)
  const byDoctor = useMemo(() => new Map(rows.map((a) => [Number(a.doctor_id), a])), [rows])
  return { rows, byDoctor, isLoading, isError }
}

export const placeKey = (type: unknown, targetId: unknown) => `${type}:${Number(targetId)}`

/** Each doctor's or centre's team in display order. `type` undefined: not a place, nothing is fetched. */
export function useStaffByPlace(type: string | undefined) {
  const { rows, isLoading, isError } = useLookup(type ? 'staff' : undefined)
  const byPlace = useMemo(() => {
    const map = new Map<string, Row[]>()
    for (const m of rows) {
      const key = placeKey(m.type, m.target_id)
      map.set(key, [...(map.get(key) ?? []), m])
    }
    for (const team of map.values()) {
      team.sort((a, b) => Number(a.sort_order ?? 0) - Number(b.sort_order ?? 0) || a.id - b.id)
    }
    return map
  }, [rows])
  return { byPlace, isLoading, isError }
}

export function useStats() {
  return useQuery({ queryKey: keys.stats, queryFn: () => api.stats() })
}

function invalidate(qc: QueryClient, resource: string) {
  qc.invalidateQueries({ queryKey: keys.list(resource) })
  qc.invalidateQueries({ queryKey: keys.all(resource) })
  qc.invalidateQueries({ queryKey: keys.stats })
}

export function useSave(resource: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, values }: { id?: number; values: Values }) =>
      id ? api.update(resource, id, values) : api.create(resource, values),
    onSuccess: (row, { id }) => {
      // Show the edited row straight away, before the refetch lands.
      if (id) {
        qc.setQueriesData<ListResult>({ queryKey: keys.list(resource) }, (old) =>
          old ? { ...old, data: old.data.map((r) => (r.id === id ? row : r)) } : old,
        )
      }
      invalidate(qc, resource)
    },
  })
}

export function useRemove(resource: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (ids: number[]) => api.remove(resource, ids),
    // Rows vanish immediately; they come back if the server refuses.
    onMutate: async (ids) => {
      await qc.cancelQueries({ queryKey: keys.list(resource) })
      const snapshot = qc.getQueriesData<ListResult>({ queryKey: keys.list(resource) })
      const drop = new Set(ids)
      qc.setQueriesData<ListResult>({ queryKey: keys.list(resource) }, (old) =>
        old
          ? { ...old, data: old.data.filter((r) => !drop.has(r.id)), total: old.total - ids.length }
          : old,
      )
      return { snapshot }
    },
    onError: (_e, _ids, ctx) => ctx?.snapshot.forEach(([k, v]) => qc.setQueryData(k, v)),
    onSettled: () => invalidate(qc, resource),
  })
}

export function rowTitle(resource: string, row: Row) {
  const res = RESOURCE_MAP[resource]
  const v = row[res.titleField]
  return res.titleField === 'id' ? `${res.singular} #${row.id}` : String(v ?? '')
}
