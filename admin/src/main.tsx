import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { HashRouter, Navigate, Route, Routes } from 'react-router-dom'
import { QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from 'sonner'
import './index.css'
import { queryClient } from './lib/queries'
import { AuthProvider, useAuth } from './lib/auth'
import Layout from './components/Layout'
import Dashboard from './pages/Dashboard'
import ResourcePage from './pages/ResourcePage'
import Login from './pages/Login'

function Routed() {
  const { user } = useAuth()
  if (!user) return <Login />
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<Dashboard />} />
        <Route path="r/:resource" element={<ResourcePage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  )
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        {/* Hash routing lets the build be dropped into any folder on the server. */}
        <HashRouter>
          <Routed />
        </HashRouter>
        <Toaster position="bottom-left" dir="rtl" richColors closeButton toastOptions={{ style: { fontFamily: 'Cairo' } }} />
      </AuthProvider>
    </QueryClientProvider>
  </StrictMode>,
)
