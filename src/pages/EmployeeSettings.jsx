import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { useAuth } from '@/hooks/useAuth'
import Layout from '@/components/layout/Layout'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { User, Mail, Lock, Info } from 'lucide-react'
import { supabase } from '@/lib/supabase'

export default function EmployeeSettings() {
  const navigate = useNavigate()
  const { userData } = useAuth()

  // Estados para cambio de email
  const [emailForm, setEmailForm] = useState({
    currentEmail: userData?.email || '',
    newEmail: '',
    currentPassword: ''
  })
  const [loadingEmail, setLoadingEmail] = useState(false)

  // Estados para cambio de contraseña
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  })
  const [loadingPassword, setLoadingPassword] = useState(false)

  // Manejar cambio de email
  const handleEmailChange = async (e) => {
    e.preventDefault()
    setLoadingEmail(true)

    try {
      // Verificar que el nuevo email no esté vacío
      if (!emailForm.newEmail.trim()) {
        toast.error('Por favor ingresa un nuevo email')
        return
      }

      // Verificar formato de email
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      if (!emailRegex.test(emailForm.newEmail)) {
        toast.error('Por favor ingresa un email válido')
        return
      }

      // Actualizar email en Supabase Auth
      const { error: authError } = await supabase.auth.updateUser({
        email: emailForm.newEmail
      })

      if (authError) throw authError

      toast.success('Solicitud enviada. Confirma el cambio desde los correos que recibas.')

      // Limpiar formulario
      setEmailForm({
        currentEmail: emailForm.currentEmail,
        newEmail: '',
        currentPassword: ''
      })

    } catch (error) {
      console.error('Error updating email:', error)
      toast.error('Error al actualizar el email: ' + (error.message || 'Error desconocido'))
    } finally {
      setLoadingEmail(false)
    }
  }

  // Manejar cambio de contraseña
  const handlePasswordChange = async (e) => {
    e.preventDefault()
    setLoadingPassword(true)

    try {
      // Validar que la nueva contraseña tenga al menos 6 caracteres
      if (passwordForm.newPassword.length < 6) {
        toast.error('La contraseña debe tener al menos 6 caracteres')
        return
      }

      // Validar que las contraseñas coincidan
      if (passwordForm.newPassword !== passwordForm.confirmPassword) {
        toast.error('Las contraseñas no coinciden')
        return
      }

      // Actualizar contraseña en Supabase Auth
      const { error } = await supabase.auth.updateUser({
        password: passwordForm.newPassword
      })

      if (error) throw error

      toast.success('✅ Contraseña actualizada correctamente')

      // Limpiar formulario
      setPasswordForm({
        currentPassword: '',
        newPassword: '',
        confirmPassword: ''
      })

    } catch (error) {
      console.error('Error updating password:', error)
      toast.error('Error al actualizar la contraseña: ' + (error.message || 'Error desconocido'))
    } finally {
      setLoadingPassword(false)
    }
  }

  return (
    <Layout>
      <div className="space-y-6 max-w-4xl mx-auto">
        {/* Header */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">⚙️ Configuración</h1>
            <p className="text-gray-600 mt-1">Administra tu información personal y seguridad</p>
          </div>

        </div>

        {/* Mi Información */}
        <Card>
          <CardHeader className="  bg-white border-b border-gray-200 text-gray-900">
            <CardTitle className="flex items-center gap-2">
              <User className="h-5 w-5" />
              Mi Información
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <Label className="text-gray-700 font-semibold">Nombre:</Label>
                  <p className="text-gray-900 mt-1">{userData?.full_name || 'N/A'}</p>
                </div>
                <div>
                  <Label className="text-gray-700 font-semibold">Email actual:</Label>
                  <p className="text-gray-900 mt-1">{userData?.email || 'N/A'}</p>
                </div>
                <div>
                  <Label className="text-gray-700 font-semibold">ID:</Label>
                  <p className="text-gray-900 mt-1 font-mono text-sm">{userData?.id?.slice(0, 8) || 'N/A'}...</p>
                </div>
                <div>
                  <Label className="text-gray-700 font-semibold">WhatsApp:</Label>
                  <p className="text-gray-900 mt-1">{userData?.whatsapp || 'No registrado'}</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Cambiar Email */}
        <Card>
          <CardHeader className="  bg-white border-b border-gray-200 text-gray-900">
            <CardTitle className="flex items-center gap-2">
              <Mail className="h-5 w-5" />
              Cambiar Email
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-6">
            <Alert className="mb-4 bg-blue-50 border-blue-200">
              <Info className="h-4 w-4 text-blue-600" />
              <AlertDescription className="text-blue-800">
                📧 Para cambiar tu email, necesitas ingresar tu contraseña actual por seguridad.
              </AlertDescription>
            </Alert>

            <form onSubmit={handleEmailChange} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="current-email" className="text-gray-900 font-semibold">
                  Email actual
                </Label>
                <Input
                  id="current-email"
                  type="email"
                  value={emailForm.currentEmail}
                  disabled
                  className="bg-gray-100"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="new-email" className="text-gray-900 font-semibold">
                  Nuevo email *
                </Label>
                <Input
                  id="new-email"
                  type="email"
                  value={emailForm.newEmail}
                  onChange={(e) => setEmailForm(prev => ({ ...prev, newEmail: e.target.value }))}
                  placeholder="nuevo@email.com"
                  required
                  className="border-gray-300"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="email-password" className="text-gray-900 font-semibold">
                  Contraseña actual *
                </Label>
                <Input
                  id="email-password"
                  type="password"
                  value={emailForm.currentPassword}
                  onChange={(e) => setEmailForm(prev => ({ ...prev, currentPassword: e.target.value }))}
                  placeholder="Tu contraseña actual"
                  required
                  className="border-gray-300"
                />
              </div>

              <Button
                type="submit"
                disabled={loadingEmail}
                className="w-full bg-blue-500 hover:bg-blue-600 text-white"
              >
                {loadingEmail ? '⏳ Actualizando...' : '📧 Actualizar Email'}
              </Button>
            </form>
          </CardContent>
        </Card>

        {/* Cambiar Contraseña */}
        <Card>
          <CardHeader className="  bg-white border-b border-gray-200 text-gray-900">
            <CardTitle className="flex items-center gap-2">
              <Lock className="h-5 w-5" />
              Cambiar Contraseña
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-6">
            <Alert className="mb-4 bg-yellow-50 border-yellow-200">
              <Info className="h-4 w-4 text-yellow-600" />
              <AlertDescription className="text-yellow-800">
                🔒 Tu nueva contraseña debe tener al menos 6 caracteres. Se recomienda usar una combinación de letras, números y símbolos.
              </AlertDescription>
            </Alert>

            <form onSubmit={handlePasswordChange} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="current-password" className="text-gray-900 font-semibold">
                  Contraseña actual *
                </Label>
                <Input
                  id="current-password"
                  type="password"
                  value={passwordForm.currentPassword}
                  onChange={(e) => setPasswordForm(prev => ({ ...prev, currentPassword: e.target.value }))}
                  placeholder="Tu contraseña actual"
                  required
                  className="border-gray-300"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="new-password" className="text-gray-900 font-semibold">
                  Nueva contraseña *
                </Label>
                <Input
                  id="new-password"
                  type="password"
                  value={passwordForm.newPassword}
                  onChange={(e) => setPasswordForm(prev => ({ ...prev, newPassword: e.target.value }))}
                  placeholder="Mínimo 8 caracteres"
                  required
                  minLength={6}
                  className="border-gray-300"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="confirm-password" className="text-gray-900 font-semibold">
                  Confirmar nueva contraseña *
                </Label>
                <Input
                  id="confirm-password"
                  type="password"
                  value={passwordForm.confirmPassword}
                  onChange={(e) => setPasswordForm(prev => ({ ...prev, confirmPassword: e.target.value }))}
                  placeholder="Repite la nueva contraseña"
                  required
                  minLength={6}
                  className="border-gray-300"
                />
              </div>

              <Button
                type="submit"
                disabled={loadingPassword}
                className="w-full bg-red-500 hover:bg-red-600 text-white"
              >
                {loadingPassword ? '⏳ Actualizando...' : '🔒 Actualizar Contraseña'}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    </Layout>
  )
}
