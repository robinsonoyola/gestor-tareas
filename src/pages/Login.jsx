import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { supabase } from '@/lib/supabase'
import { requestPasswordReset } from '@/lib/passwordRecovery'

export default function Login() {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [resetMode, setResetMode] = useState(false)
  const [resetMessage, setResetMessage] = useState('')
  const [resetError, setResetError] = useState('')
  const [resetCooldown, setResetCooldown] = useState(0)
  const [credentials, setCredentials] = useState({
    email: '',
    password: ''
  })

  useEffect(() => {
    if (resetCooldown <= 0) return
    const timer = setTimeout(() => setResetCooldown(value => Math.max(0, value - 1)), 1000)
    return () => clearTimeout(timer)
  }, [resetCooldown])

  const toggleRecovery = () => {
    setResetMode(value => !value)
    setResetMessage('')
    setResetError('')
    setCredentials(value => ({ ...value, password: '' }))
  }

  const handleResetRequest = async (event) => {
    event.preventDefault()
    if (loading || resetCooldown > 0) return
    setLoading(true)
    setResetMessage('')
    setResetError('')
    try {
      await requestPasswordReset(credentials.email)
      setResetMessage('Si existe una cuenta con ese email, recibirás un enlace para elegir una contraseña nueva. Revisa también la carpeta de spam.')
      setResetCooldown(60)
    } catch (error) {
      console.error('Error requesting recovery:', error?.code || 'unknown')
      setResetError('No se pudo solicitar el enlace. Comprueba el email y vuelve a intentarlo más tarde.')
    } finally {
      setLoading(false)
    }
  }

  const handleLogin = async (e) => {
    e.preventDefault()
    setLoading(true)

    try {
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: credentials.email,
        password: credentials.password
      })

      if (authError) throw authError

      const context=await supabase.rpc('mt_context')
      if(context.error && !['PGRST202','42883'].includes(context.error.code))throw context.error
      let userData=context.data?.profile
      if(context.error){
        const response=await supabase.from('users').select('*').eq('id',authData.user.id).single()
        if(response.error)throw response.error
        userData=response.data
      }

      toast.success('✅ Inicio de sesión exitoso')

      if (userData?.is_admin) {
        navigate('/admin')
      } else {
        navigate('/employee')
      }
    } catch (error) {
      console.error('Error logging in:', error)
      toast.error(error?.code === 'invalid_credentials'
        ? '❌ Correo o contraseña incorrectos'
        : error?.message?.includes('AbortError')
          ? 'La sesión cambió durante el acceso. Vuelve a intentarlo.'
          : 'No se pudo completar el acceso. Comprueba la conexión o la configuración del proyecto.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-slate-100 via-white to-slate-200">
      <Card className="w-full max-w-md mx-4">
        <CardHeader className="space-y-1 text-center">
          <div className="mx-auto w-28 h-28 flex items-center justify-center mb-3">
            <img src="/ase-icon.svg" alt="Logo ASE" width="112" height="112" className="w-28 h-28 object-contain" />
          </div>
          <CardTitle className="text-3xl font-bold text-gray-900">{resetMode ? 'Recuperar contraseña' : 'ASE Work'}</CardTitle>
          <CardDescription className="text-gray-600 text-base">
            {resetMode ? 'Introduce tu email para solicitar un enlace de recuperación.' : 'Gestión de equipos y tareas'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {window.history.state?.idx>0 && <Button type="button" variant="outline" size="sm" className="mb-4" onClick={()=>navigate(-1)}>← Atrás</Button>}
          <form onSubmit={resetMode ? handleResetRequest : handleLogin} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email" className="text-gray-900 font-semibold">
                Email
              </Label>
              <Input
                id="email"
                type="email"
                value={credentials.email}
                onChange={(e) => setCredentials(prev => ({ ...prev, email: e.target.value }))}
                placeholder="usuario@hotel.com"
                required
                className="h-12 text-base"
                autoComplete="email"
              />
            </div>

            {!resetMode && (
            <div className="space-y-2">
              <Label htmlFor="password" className="text-gray-900 font-semibold">
                Contraseña
              </Label>
              <Input
                id="password"
                type="password"
                value={credentials.password}
                onChange={(e) => setCredentials(prev => ({ ...prev, password: e.target.value }))}
                placeholder="••••••••"
                required
                className="h-12 text-base"
                autoComplete="current-password"
              />
            </div>

            )}

            {resetMessage && <p role="status" className="rounded-md bg-green-50 p-3 text-sm text-green-800">{resetMessage}</p>}
            {resetError && <p role="alert" className="rounded-md bg-red-50 p-3 text-sm text-red-800">{resetError}</p>}

            <Button
              type="submit"
              disabled={loading || (resetMode && resetCooldown > 0)}
              className="w-full h-12 text-base  bg-blue-600 hover:bg-blue-700 cursor-pointer text-white font-semibold"
            >
              {loading ? (
                <>
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                  {resetMode ? 'Solicitando enlace…' : 'Iniciando sesión…'}
                </>
              ) : (
                resetMode ? (resetCooldown > 0 ? `Puedes volver a solicitarlo en ${resetCooldown}s` : 'Enviar enlace de recuperación') : '🔓 Iniciar Sesión'
              )}
            </Button>
          </form>

          <div className="mt-4 text-center">
            <button type="button" onClick={toggleRecovery} disabled={loading}
              className="text-sm font-medium text-blue-700 underline hover:text-blue-900 disabled:opacity-50">
              {resetMode ? 'Volver a iniciar sesión' : '¿Olvidaste tu contraseña?'}
            </button>
          </div>


        </CardContent>
      </Card>
    </div>
  )
}