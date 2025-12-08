import { useState, useEffect } from 'react'
import { toast } from 'sonner'
import Layout from '@/components/layout/Layout'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { 
  Plus, 
  Edit, 
  Trash2, 
  ArrowLeft,
  Users,
  Mail,
  Phone,
  CheckCircle,
  XCircle,
  AlertCircle
} from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'

export default function EmployeeManager() {
  const navigate = useNavigate()
  const [employees, setEmployees] = useState([])
  const [loading, setLoading] = useState(true)
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)
  const [isEditModalOpen, setIsEditModalOpen] = useState(false)
  const [selectedEmployee, setSelectedEmployee] = useState(null)
  const [submitting, setSubmitting] = useState(false)
  
  const [employeeForm, setEmployeeForm] = useState({
    full_name: '',
    email: '',
    password: '',
    whatsapp: ''
  })

  useEffect(() => {
    fetchEmployees()
  }, [])

  const fetchEmployees = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('is_admin', false)
        .order('created_at', { ascending: false })

      if (error) throw error
      setEmployees(data || [])
    } catch (error) {
      console.error('Error fetching employees:', error)
      toast.error('Error al cargar empleados')
    } finally {
      setLoading(false)
    }
  }

  const handleCreateEmployee = async (e) => {
    e.preventDefault()
    setSubmitting(true)

    try {
      // Crear usuario en Supabase Auth
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: employeeForm.email,
        password: employeeForm.password,
        options: {
          data: {
            full_name: employeeForm.full_name
          }
        }
      })

      if (authError) throw authError

      // Insertar en tabla users
      const { error: dbError } = await supabase
        .from('users')
        .insert([{
          id: authData.user.id,
          email: employeeForm.email,
          full_name: employeeForm.full_name,
          whatsapp: employeeForm.whatsapp || null,
          is_admin: false
        }])

      if (dbError) throw dbError

      toast.success('✅ Empleado creado correctamente')
      setIsCreateModalOpen(false)
      resetForm()
      fetchEmployees()
    } catch (error) {
      console.error('Error creating employee:', error)
      toast.error('Error al crear empleado: ' + (error.message || 'Error desconocido'))
    } finally {
      setSubmitting(false)
    }
  }

  const handleEditEmployee = async (e) => {
    e.preventDefault()
    setSubmitting(true)

    try {
      // Actualizar en tabla users
      const { error: updateError } = await supabase
        .from('users')
        .update({
          full_name: employeeForm.full_name,
          email: employeeForm.email,
          whatsapp: employeeForm.whatsapp || null
        })
        .eq('id', selectedEmployee.id)

      if (updateError) throw updateError

      // Si se proporcionó una nueva contraseña, actualizarla
      if (employeeForm.password) {
        const { error: passwordError } = await supabase.auth.admin.updateUserById(
          selectedEmployee.id,
          { password: employeeForm.password }
        )

        if (passwordError) {
          console.error('Error updating password:', passwordError)
          toast.warning('⚠️ Empleado actualizado pero no se pudo cambiar la contraseña')
        }
      }

      toast.success('✅ Empleado actualizado correctamente')
      setIsEditModalOpen(false)
      setSelectedEmployee(null)
      resetForm()
      fetchEmployees()
    } catch (error) {
      console.error('Error updating employee:', error)
      toast.error('Error al actualizar empleado')
    } finally {
      setSubmitting(false)
    }
  }

  const handleDeleteEmployee = async (employeeId, employeeName) => {
    const confirm = window.confirm(`¿Estás seguro de eliminar al empleado "${employeeName}"?`)
    if (!confirm) return

    try {
      // Eliminar de la tabla users (las asignaciones de tareas se eliminan automáticamente por CASCADE)
      const { error } = await supabase
        .from('users')
        .delete()
        .eq('id', employeeId)

      if (error) throw error

      toast.success('✅ Empleado eliminado')
      fetchEmployees()
    } catch (error) {
      console.error('Error deleting employee:', error)
      toast.error('Error al eliminar empleado')
    }
  }

  const openEditModal = (employee) => {
    setSelectedEmployee(employee)
    setEmployeeForm({
      full_name: employee.full_name,
      email: employee.email,
      password: '',
      whatsapp: employee.whatsapp || ''
    })
    setIsEditModalOpen(true)
  }

  const resetForm = () => {
    setEmployeeForm({
      full_name: '',
      email: '',
      password: '',
      whatsapp: ''
    })
  }

  const getEmployeeStats = () => {
    return {
      total: employees.length,
      active: employees.length // Por ahora todos son activos
    }
  }

  const stats = getEmployeeStats()

  return (
    <Layout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">👥 Gestionar Empleados</h1>
            <p className="text-gray-900 mt-1">Administra tu equipo de trabajo</p>
          </div>
          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => navigate('/admin')}
              className="text-gray-900"
            >
              <ArrowLeft className="mr-2 h-4 w-4" />
              Volver
            </Button>
            <Button
              onClick={() => setIsCreateModalOpen(true)}
              className="bg-green-500 hover:bg-green-600 text-white"
            >
              <Plus className="mr-2 h-4 w-4" />
              Nuevo Empleado
            </Button>
          </div>
        </div>

        {/* Estadísticas */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                  <Users className="h-6 w-6 text-blue-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-900">Total Empleados</p>
                  <p className="text-3xl font-bold text-gray-900">{stats.total}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                  <CheckCircle className="h-6 w-6 text-green-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-900">Empleados Activos</p>
                  <p className="text-3xl font-bold text-gray-900">{stats.active}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Tabla de Empleados */}
        <Card>
          <CardHeader>
            <CardTitle className="text-gray-900">📋 Lista de Empleados</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="text-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
                <p className="mt-4 text-gray-900">Cargando empleados...</p>
              </div>
            ) : employees.length === 0 ? (
              <div className="text-center py-12">
                <Users className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-900 mb-4">No hay empleados registrados</p>
                <Button onClick={() => setIsCreateModalOpen(true)}>
                  <Plus className="mr-2 h-4 w-4" />
                  Crear Primer Empleado
                </Button>
              </div>
            ) : (
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="text-gray-900">Nombre Completo</TableHead>
                      <TableHead className="text-gray-900">Email</TableHead>
                      <TableHead className="text-gray-900">WhatsApp</TableHead>
                      <TableHead className="text-gray-900">Fecha Registro</TableHead>
                      <TableHead className="text-right text-gray-900">Acciones</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {employees.map((employee) => (
                      <TableRow key={employee.id}>
                        <TableCell className="font-medium text-gray-900">
                          {employee.full_name}
                        </TableCell>
                        <TableCell className="text-gray-900">
                          <div className="flex items-center gap-2">
                            <Mail className="h-4 w-4 text-gray-500" />
                            {employee.email}
                          </div>
                        </TableCell>
                        <TableCell className="text-gray-900">
                          {employee.whatsapp ? (
                            <div className="flex items-center gap-2">
                              <Phone className="h-4 w-4 text-gray-500" />
                              {employee.whatsapp}
                            </div>
                          ) : (
                            <span className="text-gray-500">-</span>
                          )}
                        </TableCell>
                        <TableCell className="text-gray-900">
                          {employee.created_at ? format(new Date(employee.created_at), 'PPP', { locale: es }) : '-'}
                        </TableCell>
                        <TableCell className="text-right space-x-2">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => openEditModal(employee)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => handleDeleteEmployee(employee.id, employee.full_name)}
                            className="text-red-600 hover:text-red-700"
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Modal Crear Empleado */}
      <Dialog open={isCreateModalOpen} onOpenChange={setIsCreateModalOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="text-gray-900">👤 Crear Nuevo Empleado</DialogTitle>
            <DialogDescription className="text-gray-900">
              Completa los datos del nuevo empleado
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleCreateEmployee} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="create-name" className="text-gray-900 font-semibold">
                Nombre Completo *
              </Label>
              <Input
                id="create-name"
                value={employeeForm.full_name}
                onChange={(e) => setEmployeeForm(prev => ({ ...prev, full_name: e.target.value }))}
                placeholder="Juan Pérez"
                required
                className="text-gray-900"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="create-email" className="text-gray-900 font-semibold">
                Email *
              </Label>
              <Input
                id="create-email"
                type="email"
                value={employeeForm.email}
                onChange={(e) => setEmployeeForm(prev => ({ ...prev, email: e.target.value }))}
                placeholder="empleado@hotel.com"
                required
                className="text-gray-900"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="create-password" className="text-gray-900 font-semibold">
                Contraseña *
              </Label>
              <Input
                id="create-password"
                type="password"
                value={employeeForm.password}
                onChange={(e) => setEmployeeForm(prev => ({ ...prev, password: e.target.value }))}
                placeholder="Mínimo 6 caracteres"
                required
                minLength={6}
                className="text-gray-900"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="create-whatsapp" className="text-gray-900 font-semibold">
                WhatsApp (opcional)
              </Label>
              <Input
                id="create-whatsapp"
                type="tel"
                value={employeeForm.whatsapp}
                onChange={(e) => setEmployeeForm(prev => ({ ...prev, whatsapp: e.target.value }))}
                placeholder="+34 600 000 000"
                className="text-gray-900"
              />
            </div>

            <Alert className="bg-blue-50 border-blue-200">
              <AlertCircle className="h-4 w-4 text-blue-600" />
              <AlertDescription className="text-blue-800 text-sm">
                El empleado recibirá un email de confirmación en su correo.
              </AlertDescription>
            </Alert>

            <Button
              type="submit"
              disabled={submitting}
              className="w-full bg-green-500 hover:bg-green-600 text-white"
            >
              {submitting ? '⏳ Creando...' : '✅ Crear Empleado'}
            </Button>
          </form>
        </DialogContent>
      </Dialog>

      {/* Modal Editar Empleado */}
      <Dialog open={isEditModalOpen} onOpenChange={setIsEditModalOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="text-gray-900">✏️ Editar Empleado</DialogTitle>
            <DialogDescription className="text-gray-900">
              Modifica los datos del empleado
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleEditEmployee} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="edit-name" className="text-gray-900 font-semibold">
                Nombre Completo *
              </Label>
              <Input
                id="edit-name"
                value={employeeForm.full_name}
                onChange={(e) => setEmployeeForm(prev => ({ ...prev, full_name: e.target.value }))}
                required
                className="text-gray-900"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-email" className="text-gray-900 font-semibold">
                Email *
              </Label>
              <Input
                id="edit-email"
                type="email"
                value={employeeForm.email}
                onChange={(e) => setEmployeeForm(prev => ({ ...prev, email: e.target.value }))}
                required
                className="text-gray-900"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-password" className="text-gray-900 font-semibold">
                Nueva Contraseña (dejar vacío para no cambiar)
              </Label>
              <Input
                id="edit-password"
                type="password"
                value={employeeForm.password}
                onChange={(e) => setEmployeeForm(prev => ({ ...prev, password: e.target.value }))}
                placeholder="Mínimo 6 caracteres"
                minLength={6}
                className="text-gray-900"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-whatsapp" className="text-gray-900 font-semibold">
                WhatsApp (opcional)
              </Label>
              <Input
                id="edit-whatsapp"
                type="tel"
                value={employeeForm.whatsapp}
                onChange={(e) => setEmployeeForm(prev => ({ ...prev, whatsapp: e.target.value }))}
                placeholder="+34 600 000 000"
                className="text-gray-900"
              />
            </div>

            <Button
              type="submit"
              disabled={submitting}
              className="w-full bg-blue-500 hover:bg-blue-600 text-white"
            >
              {submitting ? '⏳ Guardando...' : '💾 Guardar Cambios'}
            </Button>
          </form>
        </DialogContent>
      </Dialog>
    </Layout>
  )
}