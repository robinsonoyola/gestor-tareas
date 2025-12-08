import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Lock, AlertCircle, CheckCircle, Info } from 'lucide-react'
import { supabase } from '@/lib/supabase'

export default function TaskAccessLogin() {
  const { accessCode } = useParams()
  const navigate = useNavigate()
  
  const [credentials, setCredentials] = useState({
    email: '',
    password: ''
  })
  const [loading, setLoading] = useState(false)
  const [validatingCode, setValidatingCode] = useState(true)
  const [codeValid, setCodeValid] = useState(false)
  const [taskInfo, setTaskInfo] = useState(null)

  useEffect(() => {
    validateAccessCode()
  }, [accessCode])

  const validateAccessCode = async () => {
    try {
      setValidatingCode(true)

      const { data: codeData, error: codeError } = await supabase
        .from('task_access_codes')
        .select(`
          *,
          tasks (
            id,
            title,
            description
          )
        `)
        .eq('access_code', accessCode)
        .eq('is_active', true)
        .single()

      if (codeError || !codeData) {
        setCodeValid(false)
        toast.error('Código de acceso inválido o expirado')
        return
      }

      // Verificar si tiene fecha de expiración
      if (codeData.expires_at && new Date(codeData.expires_at) < new Date()) {
        setCodeValid(false)
        toast.error('Este código de acceso ha expirado')
        return
      }

      setCodeValid(true)
      setTaskInfo(codeData.tasks)
      toast.success('✅ Código válido')

    } catch (error) {
      console.error('Error validating code:', error)
      setCodeValid(false)
    } finally {
      setValidatingCode(false)
    }
  }

  const handleLogin = async (e) => {
    e.preventDefault()
    setLoading(true)

    try {
      // Autenticar usuario
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: credentials.email,
        password: credentials.password
      })

      if (authError) {
        toast.error('❌ Credenciales incorrectas')
        setLoading(false)
        return
      }

      // Verificar que el usuario esté asignado a esta tarea
      const { data: assignmentData, error: assignmentError } = await supabase
        .from('task_assignments')
        .select('*')
        .eq('task_id', taskInfo.id)
        .eq('user_id', authData.user.id)
        .single()

      if (assignmentError || !assignmentData) {
        // Cerrar sesión si no está asignado
        await supabase.auth.signOut()
        toast.error('❌ No tienes permiso para acceder a esta tarea')
        setLoading(false)
        return
      }

      toast.success('✅ Acceso concedido')
      
      // Redirigir a la tarea
      navigate(`/employee/task/${taskInfo.id}/work`)

    } catch (error) {
      console.error('Error during login:', error)
      toast.error('Error al iniciar sesión')
    } finally {
      setLoading(false)
    }
  }

  if (validatingCode) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center p-4">
        <Card className="w-full max-w-md">
          <CardContent className="pt-12 pb-12">
            <div className="text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
              <p className="mt-4 text-gray-600">Validando código de acceso...</p>
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  if (!codeValid) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-red-500 to-pink-600 flex items-center justify-center p-4">
        <Card className="w-full max-w-md">
          <CardHeader className="text-center">
            <div className="mx-auto w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-4">
              <AlertCircle className="h-8 w-8 text-red-600" />
            </div>
            <CardTitle className="text-2xl">❌ Código Inválido</CardTitle>
            <CardDescription>
              El código de acceso no es válido o ha expirado
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Alert className="bg-red-50 border-red-200 mb-4">
              <AlertCircle className="h-4 w-4 text-red-600" />
              <AlertDescription className="text-red-800">
                <strong>Posibles razones:</strong>
                <ul className="mt-2 space-y-1 text-sm list-disc list-inside">
                  <li>El código no existe</li>
                  <li>El código ha sido desactivado</li>
                  <li>El código ha expirado</li>
                  <li>El enlace fue copiado incorrectamente</li>
                </ul>
              </AlertDescription>
            </Alert>
            <Button
              onClick={() => navigate('/login')}
              className="w-full bg-gray-600 hover:bg-gray-700"
            >
              ← Ir al Login Principal
            </Button>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="mx-auto w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mb-4">
            <CheckCircle className="h-8 w-8 text-green-600" />
          </div>
          <CardTitle className="text-2xl">🔐 Acceso a Tarea</CardTitle>
          <CardDescription className="text-base">
            <strong className="text-gray-900">{taskInfo?.title}</strong>
          </CardDescription>
          {taskInfo?.description && (
            <p className="text-sm text-gray-600 mt-2">
              {taskInfo.description}
            </p>
          )}
        </CardHeader>
        <CardContent>
          <Alert className="bg-blue-50 border-blue-200 mb-6">
            <Info className="h-4 w-4 text-blue-600" />
            <AlertDescription className="text-blue-800">
              <strong>Autenticación requerida:</strong> Introduce tus credenciales para acceder a la tarea.
            </AlertDescription>
          </Alert>

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
