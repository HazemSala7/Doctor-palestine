// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type Row = { id: number; [key: string]: any }

export interface Coordinates {
  lat: string
  lng: string
}

/** Form values: images are a File (new upload), a URL (unchanged) or null (removed). */
export type Values = Record<string, unknown>

export interface ListParams {
  page: number
  perPage: number
  q?: string
  sort?: string // "name" or "-name"
  filters?: Record<string, string | undefined>
}

export interface ListResult {
  data: Row[]
  total: number
  page: number
  lastPage: number
}

export interface Stats {
  counts: Record<string, number>
  doctorsByCity: { id: number; count: number }[]
  doctorsByCategory: { id: number; count: number }[]
  recent: { resource: string; row: Row }[]
}

export interface User {
  name: string
  email: string
}

export interface DataProvider {
  readonly mode: 'demo' | 'api'
  login(email: string, password: string): Promise<{ token: string; user: User }>
  list(resource: string, params: ListParams): Promise<ListResult>
  all(resource: string): Promise<Row[]>
  create(resource: string, values: Values): Promise<Row>
  update(resource: string, id: number, values: Values): Promise<Row>
  remove(resource: string, ids: number[]): Promise<void>
  stats(): Promise<Stats>
  /** Demo only: restore the sample data. */
  reset?(): Promise<void>
}

export class ApiError extends Error {
  status: number
  fieldErrors: Record<string, string>
  constructor(message: string, status = 0, fieldErrors: Record<string, string> = {}) {
    super(message)
    this.status = status
    this.fieldErrors = fieldErrors
  }
}
