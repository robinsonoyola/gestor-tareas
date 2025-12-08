import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { supabase } from '@/lib/supabase'

export default function Login() {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [credentials, setCredentials] = useState({
    email: '',
    password: ''
  })

  const handleLogin = async (e) => {
    e.preventDefault()
    setLoading(true)

    try {
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: credentials.email,
        password: credentials.password
      })

      if (authError) throw authError

      const { data: userData, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('id', authData.user.id)
        .single()

      if (userError) throw userError

      toast.success('✅ Inicio de sesión exitoso')

      if (userData.is_admin) {
        navigate('/admin')
      } else {
        navigate('/employee')
      }
    } catch (error) {
      console.error('Error logging in:', error)
      toast.error('❌ Credenciales incorrectas')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <Card className="w-full max-w-md mx-4">
        <CardHeader className="space-y-1 text-center">
          <div className="mx-auto w-20 h-20 bg-white rounded-full flex items-center justify-center mb-4 shadow-lg">
            <span className="text-4xl">🏨</span>
          </div>
          <CardTitle className="text-3xl font-bold text-gray-900">Hotel Tareas</CardTitle>
          <CardDescription className="text-gray-600 text-base">
            Sistema de Gestión Hotelera
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
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

            <Button
              type="submit"
              disabled={loading}
              className="w-full h-12 text-base  bg-black cursor-pointer text-white font-semibold"
            >
              {loading ? (
                <>
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                  Iniciando sesión...
                </>
              ) : (
                '🔓 Iniciar Sesión'
              )}
            </Button>
          </form>

          <div className="mt-6 pt-6 border-t">
            <p className="text-sm text-gray-600 text-center mb-3">Usuarios de prueba:</p>
            <div className="space-y-2 text-xs text-gray-700">
              <div className="bg-blue-50 p-3 rounded-lg">
                <p className="font-semibold text-blue-900">👑 Administrador</p>
                <p className="mt-1">admin@hotel.com / admin123</p>
              </div>
              <div className="bg-green-50 p-3 rounded-lg">
                <p className="font-semibold text-green-900">👷 Empleado</p>
                <p className="mt-1">empleado@hotel.com / empleado123</p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}