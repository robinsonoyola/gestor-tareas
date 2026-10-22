import { useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { initializePasswordRecovery, validateRecoveryPassword } from '@/lib/passwordRecovery'

export default function ResetPassword() {
  const navigate = useNavigate()
  const [callbackUrl] = useState(() => window.location.href)
  const setup = useRef(null)
  const [recovery, setRecovery] = useState(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [saved, setSaved] = useState(false)
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')

  useEffect(() => {
    let cancelled = false
    // Consume one recovery request even when StrictMode re-runs the effect.
    if (!setup.current) setup.current = initializePasswordRecovery(callbackUrl)
    window.history.replaceState(null, '', '/reset-password')
    setup.current.then(value => {
      if (!cancelled) setRecovery(value)
    }).catch(failure => {
      if (!cancelled) setError(failure.message)
    }).finally(() => {
      if (!cancelled) setLoading(false)
    })
    return () => { cancelled = true }
  }, [callbackUrl])

  const handleSave = async (event) => {
    event.preventDefault()
    if (!recovery || saving || saved) return
    setError('')
    try {
      validateRecoveryPassword(password, confirmation)
      setSaving(true)
      const { data, error: updateError } = await recovery.client.auth.updateUser({ password })
      if (updateError) throw updateError
      if (data?.user?.id !== recovery.user.id) throw new Error('No se confirmó el cambio de contraseña.')
      setSaved(true)
      // Clear only the isolated recovery session, never the main admin session.
      try { await recovery.client.auth.signOut({ scope: 'local' }) } catch { /* Local client is not persisted. */ }
    } catch (failure) {
      setError(failure.message || 'No se pudo actualizar la contraseña. Solicita otro enlace si ha expirado.')
    } finally {
      setPassword('')
      setConfirmation('')
      setSaving(false)
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-100 p-4">
      <Card className="w-full max-w-md bg-white text-gray-900">
        <CardHeader><CardTitle>Elegir nueva contraseña</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <Button type="button" variant="outline" onClick={()=>navigate('/login', {replace:true})}>← Atrás al inicio de sesión</Button>
          {loading && <p role="status">Comprobando el enlace de recuperación…</p>}
          {error && <p role="alert" className="rounded-md bg-red-50 p-3 text-sm text-red-800">{error}</p>}
          {saved ? (
            <div className="space-y-4">
              <p role="status">Contraseña actualizada. Ya puedes iniciar sesión con la nueva contraseña.</p>
              <Button type="button" onClick={() => navigate('/login', { replace: true })}>Ir al inicio de sesión</Button>
            </div>
          ) : recovery && !loading ? (
            <form onSubmit={handleSave} className="space-y-4">
              <p className="text-sm text-gray-600">Elige una contraseña para tu cuenta. No necesitas comunicarla al administrador.</p>
              <div className="space-y-2">
                <Label htmlFor="recovery-password">Nueva contraseña</Label>
                <Input id="recovery-password" type="password" autoComplete="new-password" minLength={8}
                  value={password} onChange={event => setPassword(event.target.value)} required disabled={saving} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="recovery-confirmation">Repetir contraseña</Label>
                <Input id="recovery-confirmation" type="password" autoComplete="new-password" minLength={8}
                  value={confirmation} onChange={event => setConfirmation(event.target.value)} required disabled={saving} />
              </div>
              <Button type="submit" disabled={saving} className="w-full bg-blue-600 text-white hover:bg-blue-700">
                {saving ? 'Guardando…' : 'Guardar nueva contraseña'}
              </Button>
            </form>
          ) : !loading && (
            <Button type="button" variant="outline" onClick={() => navigate('/login')}>Volver al inicio de sesión</Button>
          )}
        </CardContent>
      </Card>
    </main>
  )
}
