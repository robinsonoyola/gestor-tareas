import {useOrganization} from '@/components/auth/OrganizationProvider'
import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Lock, AlertCircle, Info } from 'lucide-react'
import { supabase } from '@/lib/supabase'

export default function TaskAccessLogin() {
  const { accessCode } = useParams()
  const navigate = useNavigate()
  const organization=useOrganization()
  const [credentials, setCredentials] = useState({ email: '', password: '' })
  const [loading, setLoading] = useState(false)
  const [accessError, setAccessError] = useState('')

  useEffect(() => {
    setAccessError('')
    setCredentials(prev => ({ ...prev, password: '' }))
  }, [accessCode])

  const handleLogin = async (e) => {
    e.preventDefault()
    if (loading) return
    setLoading(true)
    setAccessError('')

    try {
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: credentials.email,
        password: credentials.password
      })
      if (authError || !authData?.user) {
        setAccessError('No se pudo iniciar sesión. Comprueba tus credenciales e inténtalo de nuevo.')
        return
      }

      const context=await supabase.rpc('mt_context')
      if(context.error && !['PGRST202','42883'].includes(context.error.code))throw context.error
      if(!context.error){
        const {data:access,error}=await supabase.rpc('mt_resolve_task_access',{p_code:accessCode})
        if(error||!access?.task_id)throw new Error('Enlace no disponible')
        await organization.selectOrganization(access.organization_id)
        toast.success('Acceso concedido')
        navigate(`/employee/task/${access.task_id}/work`)
        return
      }

      // Consultar solo después de autenticar: RLS conserva el control del acceso.
      // No exponer título, descripción ni códigos a visitantes sin sesión.
      const { data: codeData, error: codeError } = await supabase
        .from('task_access_codes')
        .select('task_id, expires_at')
        .eq('access_code', accessCode)
        .eq('is_active', true)
        .maybeSingle()

      if (codeError) throw codeError
      const expiresAt = codeData?.expires_at ? Date.parse(codeData.expires_at) : null
      if (!codeData?.task_id || (expiresAt !== null && (!Number.isFinite(expiresAt) || expiresAt <= Date.now()))) {
        setAccessError('El enlace no está disponible para tu cuenta. Puede haber expirado, estar desactivado o no corresponder a una tarea asignada.')
        return
      }

      const { data: assignmentData, error: assignmentError } = await supabase
        .from('task_assignments')
        .select('id')
        .eq('task_id', codeData.task_id)
        .eq('user_id', authData.user.id)
        .maybeSingle()

      if (assignmentError) throw assignmentError
      if (!assignmentData) {
        setAccessError('El enlace no está disponible para tu cuenta. Comprueba con tu administrador la asignación de la tarea.')
        return
      }

      toast.success('Acceso concedido')
      navigate(`/employee/task/${codeData.task_id}/work`)
    } catch (error) {
      console.error('Error al comprobar acceso a tarea:', error?.code || 'unknown')
      setAccessError('No se pudo comprobar el acceso. Inténtalo de nuevo; si continúa, contacta con tu administrador.')
    } finally {
      setCredentials(prev => ({ ...prev, password: '' }))
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-blue-600 flex items-center justify-center p-4">
      <Card className="w-full max-w-md bg-white text-gray-900">
        <CardHeader className="text-center">
          <div className="mx-auto w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mb-4">
            <Lock className="h-8 w-8 text-green-600" />
          </div>
          <CardTitle className="text-2xl">🔐 Acceso a Tarea</CardTitle>
          <CardDescription className="text-base text-gray-600">
            Inicia sesión para comprobar el enlace y tu asignación a la tarea.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Alert className="bg-blue-50 border-blue-200 mb-6">
            <Info className="h-4 w-4 text-blue-600" />
            <AlertDescription className="text-blue-800">
              <strong>Autenticación requerida:</strong> Introduce tus credenciales para acceder a la tarea.
            </AlertDescription>
          </Alert>

          {accessError && (
            <Alert role="alert" className="bg-red-50 border-red-200 mb-4">
              <AlertCircle className="h-4 w-4 text-red-600" />
              <AlertDescription className="text-red-800">{accessError}</AlertDescription>
            </Alert>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email" className="text-gray-900 font-semibold">
                Email *
              </Label>
              <Input
                id="email"
                type="email"
                value={credentials.email}
                onChange={(e) => setCredentials(prev => ({ ...prev, email: e.target.value }))}
                placeholder="tu-email@ejemplo.com"
                required
                className="border-gray-300"
                autoComplete="email"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="password" className="text-gray-900 font-semibold">
                Contraseña *
              </Label>
              <Input
                id="password"
                type="password"
                value={credentials.password}
                onChange={(e) => setCredentials(prev => ({ ...prev, password: e.target.value }))}
                placeholder="••••••••"
                required
                className="border-gray-300"
                autoComplete="current-password"
              />
            </div>

            <Button
              type="submit"
              disabled={loading}
              className="w-full bg-green-500 hover:bg-green-600 text-white"
              size="lg"
            >
              {loading ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                  Verificando...
                </>
              ) : (
                <>
                  🔓 Acceder a la Tarea
                </>
              )}
            </Button>
          </form>

          <div className="mt-6 text-center">
            <button
              onClick={() => navigate('/login')}
              className="text-sm text-gray-600 hover:text-gray-900 underline"
            >
              ← Volver al login principal
            </button>
          </div>

          <Alert className="bg-gray-50 border-gray-200 mt-6">
            <Lock className="h-4 w-4 text-gray-600" />
            <AlertDescription className="text-gray-700 text-xs">
              <strong>Seguridad:</strong> Este enlace es único y solo funciona si estás asignado a esta tarea.
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    </div>
  )
}
