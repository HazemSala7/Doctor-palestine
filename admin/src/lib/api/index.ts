import { demoProvider } from './demo'
import { laravelProvider } from './laravel'

export * from './types'

/** Picked at build time: VITE_DATA_SOURCE=api talks to Laravel, anything else stays local. */
export const api = import.meta.env.VITE_DATA_SOURCE === 'api' ? laravelProvider : demoProvider
