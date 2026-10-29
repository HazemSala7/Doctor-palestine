import { useState } from 'react'
import { Eye, EyeOff, LogIn } from 'lucide-react'
import { api } from '../lib/api'
import { useAuth } from '../lib/auth'
import { Button } from '../components/ui'

export default function Login() {
  const { login } = useAuth()
  const demo = api.mode === 'demo'
  const [email, setEmail] = useState(demo ? 'admin@tabebak.ps' : '')
  const [password, setPassword] = useState(demo ? '123456' : '')
  const [show, setShow] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await login(email, password)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'تعذّر تسجيل الدخول')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="grid min-h-full lg:grid-cols-2">
      <div className="brand-gradient relative hidden overflow-hidden lg:flex lg:flex-col lg:items-center lg:justify-center lg:p-12">
        {[
          'top-[10%] right-[12%] size-40',
          'bottom-[12%] left-[10%] size-56',
          'top-[45%] left-[30%] size-20',
        ].map((c, i) => (
          <div key={i} className={`absolute rounded-full bg-white/10 ${c}`} style={{ animation: `fade-up 3s ${i}s ease-in-out infinite alternate` }} />
        ))}
        <img src="./logo.png" alt="" className="animate-pop relative size-40 rounded-[2.5rem] bg-white p-5 shadow-2xl" />
        <h1 className="relative mt-8 text-4xl font-black text-white">طبيبك</h1>
        <p className="relative mt-3 max-w-sm text-center text-lg text-white/85">
          دليلك الطبي في فلسطين — أدِر الأطباء والمراكز والمحتوى من مكان واحد.
        </p>
      </div>

      <div className="flex items-center justify-center p-6">
        <form onSubmit={submit} className="animate-fade-up w-full max-w-sm space-y-5">
          <img src="./logo.png" alt="" className="mx-auto size-20 rounded-3xl bg-white p-2 shadow-lg lg:hidden" />
          <div>
            <h2 className="text-3xl font-black">تسجيل الدخول</h2>
            <p className="mt-1 text-muted">أهلاً بعودتك! أدخل بيانات حساب المدير.</p>
          </div>
          {demo && (
            <div className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900 dark:border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-200">
              <b>وضع تجريبي:</b> البيانات محفوظة في هذا المتصفح فقط. البريد <span dir="ltr">admin@tabebak.ps</span> وكلمة المرور <span dir="ltr">123456</span>
            </div>
          )}
          <div>
            <label htmlFor="email" className="mb-1.5 block text-sm font-bold text-ink-2">
              البريد الإلكتروني
            </label>
            <input id="email" type="email" dir="ltr" required autoComplete="username" className="input h-12" value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
          <div>
            <label htmlFor="password" className="mb-1.5 block text-sm font-bold text-ink-2">
              كلمة المرور
            </label>
            <div className="relative">
              <input
                id="password"
                type={show ? 'text' : 'password'}
                dir="ltr"
                required
                autoComplete="current-password"
                className="input h-12 pl-11"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
              <button
                type="button"
                onClick={() => setShow(!show)}
                aria-label={show ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور'}
                className="absolute top-1/2 left-3 -translate-y-1/2 text-muted hover:text-ink"
              >
                {show ? <EyeOff className="size-5" /> : <Eye className="size-5" />}
              </button>
            </div>
          </div>
          {error && <p className="animate-pop rounded-xl bg-red-50 p-3 text-sm font-bold text-red-700 dark:bg-red-500/10 dark:text-red-300">{error}</p>}
          <Button type="submit" loading={loading} className="h-12 w-full text-base" icon={<LogIn className="size-5" />}>
            دخول
          </Button>
        </form>
      </div>
    </div>
  )
}
