import { RESOURCE_MAP } from '../resources'
import { ApiError, type DataProvider, type Row, type Values } from './types'

const BASE = (import.meta.env.VITE_API_URL ?? 'https://qadrs.com/clinics_backend/api').replace(/\/$/, '')
export const TOKEN_KEY = 'tabebak-admin-token'

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem(TOKEN_KEY)
  const headers = new Headers(init.headers)
  headers.set('Accept', 'application/json')
  if (token) headers.set('Authorization', `Bearer ${token}`)
  if (init.body && !(init.body instanceof FormData)) headers.set('Content-Type', 'application/json')

  let res: Response
  try {
    res = await fetch(`${BASE}/admin${path}`, { ...init, headers })
  } catch {
    throw new ApiError('تعذّر الاتصال بالسيرفر، تحقق من الإنترنت')
  }
  const body = res.status === 204 ? null : await res.json().catch(() => null)
  if (!res.ok) {
    if (res.status === 401) window.dispatchEvent(new Event('auth:expired'))
    const fieldErrors: Record<string, string> = {}
    for (const [k, v] of Object.entries(body?.errors ?? {})) fieldErrors[k] = Array.isArray(v) ? v[0] : String(v)
    throw new ApiError(body?.message ?? `خطأ من السيرفر (${res.status})`, res.status, fieldErrors)
  }
  return body as T
}

/**
 * Laravel only parses multipart bodies on POST, so updates are POSTed
 * with `_method=PUT`. Unchanged images (still URLs) are left out;
 * removed ones are sent as `<field>__remove`.
 */
function toFormData(resource: string, values: Values, method?: 'PUT') {
  const fd = new FormData()
  if (method) fd.append('_method', method)
  for (const f of RESOURCE_MAP[resource].fields) {
    const v = values[f.key]
    if (f.type === 'image') {
      if (v instanceof File) fd.append(f.key, v)
      else if (v == null) fd.append(`${f.key}__remove`, '1')
    } else if (f.type === 'coordinates') {
      fd.append(f.key, v ? JSON.stringify([v].flat()) : '')
    } else if (f.type === 'boolean') {
      fd.append(f.key, v ? '1' : '0')
    } else {
      fd.append(f.key, v == null ? '' : String(v))
    }
  }
  return fd
}

export const laravelProvider: DataProvider = {
  mode: 'api',

  login: (email, password) =>
    request('/login', { method: 'POST', body: JSON.stringify({ email, password }) }),

  async list(resource, { page, perPage, q, sort, filters }) {
    const qs = new URLSearchParams({ page: String(page), per_page: String(perPage) })
    if (q) qs.set('q', q)
    if (sort) qs.set('sort', sort)
    for (const [k, v] of Object.entries(filters ?? {})) if (v) qs.set(`filter[${k}]`, v)
    const res = await request<{ data: Row[]; total: number; current_page: number; last_page: number }>(
      `/${resource}?${qs}`,
    )
    return { data: res.data, total: res.total, page: res.current_page, lastPage: res.last_page }
  },

  all: (resource) => request<Row[]>(`/${resource}/all`),

  create: (resource, values) =>
    request<Row>(`/${resource}`, { method: 'POST', body: toFormData(resource, values) }),

  update: (resource, id, values) =>
    request<Row>(`/${resource}/${id}`, { method: 'POST', body: toFormData(resource, values, 'PUT') }),

  async remove(resource, ids) {
    await request(`/${resource}/bulk-delete`, { method: 'POST', body: JSON.stringify({ ids }) })
  },

  stats: () => request('/stats'),
}
