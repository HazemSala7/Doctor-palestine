import { AD_TARGETS, RESOURCE_MAP, RESOURCES, REVIEW_TARGETS } from '../resources'
import { buildSeed } from '../seed'
import { ApiError, type DataProvider, type ListParams, type Row, type Stats, type Values } from './types'

const KEY = 'tabebak-admin-db-v1'
const SETTINGS_DEFAULTS: Record<string, string> = {
  tagline: 'دليلك الطبي الشامل في فلسطين',
  about_us: 'أهلاً بكم في تطبيق طبيبك، دليل الأطباء والعيادات في فلسطين.',
  privacy_policy: 'نلتزم بحماية خصوصيتك.',
  support_whatsapp: '0594606276',
  reviews_auto_approve: '0',
}
const SEARCHABLE = ['name', 'title', 'address', 'mobile', 'location', 'description']
/** The same one-row-per-value rules the server enforces. */
const UNIQUE: Record<string, string[]> = { 'doctor-accounts': ['doctor_id', 'phone'] }

type Db = Record<string, Row[]>

let db: Db = load()

function load(): Db {
  try {
    const raw = localStorage.getItem(KEY)
    if (raw) return JSON.parse(raw)
  } catch {
    /* storage blocked or corrupt: fall back to fresh data */
  }
  return buildSeed()
}

function persist() {
  try {
    localStorage.setItem(KEY, JSON.stringify(db))
  } catch {
    throw new ApiError('مساحة التخزين في المتصفح ممتلئة، جرّب صورة أصغر أو أعد ضبط البيانات التجريبية')
  }
}

const table = (resource: string) => (db[resource] ??= [])

/** Shrinks an uploaded image so the browser store stays small. */
async function toDataUrl(file: File, max = 900): Promise<string> {
  const bitmap = await createImageBitmap(file)
  const scale = Math.min(1, max / Math.max(bitmap.width, bitmap.height))
  const canvas = document.createElement('canvas')
  canvas.width = Math.round(bitmap.width * scale)
  canvas.height = Math.round(bitmap.height * scale)
  canvas.getContext('2d')!.drawImage(bitmap, 0, 0, canvas.width, canvas.height)
  return canvas.toDataURL('image/webp', 0.82)
}

async function normalize(resource: string, values: Values): Promise<Record<string, unknown>> {
  const res = RESOURCE_MAP[resource]
  const out: Record<string, unknown> = {}
  const errors: Record<string, string> = {}
  for (const f of res.fields) {
    if (f.readOnly) continue
    let v = values[f.key]
    // Videos are too big for browser storage: they play for this session only.
    if (v instanceof File) v = f.type === 'video' ? URL.createObjectURL(v) : await toDataUrl(v)
    if (f.type === 'number' || f.type === 'relation' || f.type === 'target') v = v === '' || v == null ? null : Number(v)
    if (f.type === 'boolean') v = v ? 1 : 0
    if (typeof v === 'string') v = v.trim()
    if (f.required && (v == null || v === '')) errors[f.key] = `${f.label} مطلوب`
    out[f.key] = v ?? null
  }
  if (Object.keys(errors).length) throw new ApiError('تحقق من الحقول المطلوبة', 422, errors)
  return out
}

function assertUnique(resource: string, row: Record<string, unknown>, id?: number) {
  const errors: Record<string, string> = {}
  for (const col of UNIQUE[resource] ?? []) {
    if (table(resource).some((r) => r.id !== id && r[col] === row[col])) errors[col] = 'هذه القيمة مستخدمة في حساب آخر'
  }
  if (Object.keys(errors).length) throw new ApiError(Object.values(errors)[0], 422, errors)
}

/** Like the server, rows that belong to a doctor or centre name it. */
function withPlaceName(resource: string, rows: Row[]) {
  if (resource !== 'staff' && resource !== 'reviews') return rows
  return rows.map((r) => {
    const places = table(AD_TARGETS.find((t) => t.value === r.type)?.resource ?? '')
    return { ...r, place_name: places.find((p) => p.id === r.target_id)?.name ?? null }
  })
}

function compare(a: unknown, b: unknown) {
  if (typeof a === 'number' && typeof b === 'number') return a - b
  return String(a ?? '').localeCompare(String(b ?? ''), 'ar')
}

export const demoProvider: DataProvider = {
  mode: 'demo',

  async login(phone, password) {
    if (phone.trim() !== '123456789' || password !== '123456') {
      throw new ApiError('رقم الهاتف أو كلمة المرور غير صحيحة', 401)
    }
    return { token: 'demo', user: { name: 'مدير النظام', phone: phone.trim() } }
  },

  async list(resource, { page, perPage, q, sort, filters }: ListParams) {
    let rows = table(resource)
    const needle = q?.trim().toLowerCase()
    if (needle) {
      rows = rows.filter((r) =>
        String(r.id) === needle ||
        SEARCHABLE.some((k) => typeof r[k] === 'string' && r[k].toLowerCase().includes(needle)),
      )
    }
    for (const [k, v] of Object.entries(filters ?? {})) {
      if (v !== undefined && v !== '') rows = rows.filter((r) => String(r[k] ?? '') === v)
    }
    const key = sort?.replace(/^-/, '') || 'id'
    const dir = sort?.startsWith('-') || !sort ? -1 : 1
    rows = [...rows].sort((a, b) => dir * compare(a[key], b[key]))
    const total = rows.length
    const lastPage = Math.max(1, Math.ceil(total / perPage))
    return { data: withPlaceName(resource, rows.slice((page - 1) * perPage, page * perPage)), total, page, lastPage }
  },

  async all(resource) {
    return [...table(resource)].sort((a, b) => a.id - b.id)
  },

  async create(resource, values) {
    const rows = table(resource)
    const stamp = new Date().toISOString()
    const fields = await normalize(resource, values)
    assertUnique(resource, fields)
    const row: Row = {
      id: rows.reduce((m, r) => Math.max(m, r.id), 0) + 1,
      ...fields,
      created_at: stamp,
      updated_at: stamp,
    }
    rows.push(row)
    persist()
    return row
  },

  async update(resource, id, values) {
    const rows = table(resource)
    const i = rows.findIndex((r) => r.id === id)
    if (i < 0) throw new ApiError('السجل غير موجود', 404)
    const fields = await normalize(resource, values)
    assertUnique(resource, fields, id)
    rows[i] = { ...rows[i], ...fields, updated_at: new Date().toISOString() }
    persist()
    return rows[i]
  },

  async remove(resource, ids) {
    const drop = new Set(ids)
    db[resource] = table(resource).filter((r) => !drop.has(r.id))
    // Like the server, a deleted doctor or centre takes its own records with it.
    const type = REVIEW_TARGETS.find((t) => t.resource === resource)?.value
    if (type) {
      for (const child of ['staff', 'reviews']) db[child] = table(child).filter((r) => r.type !== type || !drop.has(r.target_id))
      if (type === 'doctor') db['doctor-accounts'] = table('doctor-accounts').filter((r) => !drop.has(r.doctor_id))
    }
    persist()
  },

  async stats(): Promise<Stats> {
    const counts = Object.fromEntries(RESOURCES.map((r) => [r.key, table(r.key).length]))
    const tally = (k: string) => {
      const m = new Map<number, number>()
      for (const d of table('doctors')) if (d[k] != null) m.set(d[k], (m.get(d[k]) ?? 0) + 1)
      return [...m].map(([id, count]) => ({ id, count }))
    }
    const recent = RESOURCES.filter((r) => !r.gallery)
      .flatMap((r) => table(r.key).map((row) => ({ resource: r.key, row })))
      .sort((a, b) => compare(b.row.created_at, a.row.created_at))
      .slice(0, 8)
    return { counts, doctorsByCity: tally('city_id'), doctorsByCategory: tally('category_id'), recent }
  },

  async settings() {
    return { ...SETTINGS_DEFAULTS, ...(table('settings')[0]?.values ?? {}) }
  },

  async saveSettings(values) {
    db.settings = [{ id: 1, values }]
    persist()
    return this.settings()
  },

  async reset() {
    db = buildSeed()
    persist()
  },
}
