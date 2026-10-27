import {tenantMode,currentOrganization} from '@/lib/organizationScope'
import {MobileEmployees} from './MobileRecords'
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
import { Link } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { createEmployeeAccount } from '@/lib/createEmployee'
import { requestEmployeePasswordReset } from '@/lib/passwordRecovery'
import { workRpc } from '@/lib/workflow'
import { normalizeWhatsApp } from '@/lib/whatsapp'

async function employeeEmailError(data, error, response) {
  const http = response || error?.context
  const status = http?.status
  let payload = data
  if (!payload && typeof http?.json === 'function') {
    try { payload = await (typeof http.clone === 'function' ? http.clone() : http).json() }
    catch { /* Fall back to the status-specific message. */ }
  }
  const serverMessage = typeof payload?.error === 'string' ? payload.error.trim().slice(0, 500) : ''
  let message
  if (status === 401) message = 'La sesión de administrador no fue aceptada. Cierra sesión, vuelve a entrar e intenta cambiar el correo.'
  else if (status === 404) message = 'No se encontró la función update-employee-email en este proyecto de Supabase.'
  else if (status === 403) message = serverMessage || 'Tu cuenta no tiene permiso para cambiar el correo de este empleado.'
  else if (serverMessage) message = serverMessage
  else if (error?.name === 'FunctionsFetchError') message = 'No se pudo conectar con el servicio que cambia el correo. Comprueba la conexión y recarga la lista antes de reintentar.'
  else if (status >= 500) message = 'El servicio no pudo completar el cambio de correo. Revisa los registros de update-employee-email en Supabase.'
  else message = 'El servidor no confirmó el cambio de correo. Recarga la lista antes de reintentar.'
  const result = new Error(message)
  result.code = status ? `EMPLOYEE_EMAIL_HTTP_${status}` : 'EMPLOYEE_EMAIL_UNCONFIRMED'
  return result
}

export default function EmployeeManager() {
  const navigate = useNavigate()
  const [search,setSearch]=useState('')
  const [roleFilter,setRoleFilter]=useState('')
  const [roles, setRoles] = useState([])
  const [assignments, setAssignments] = useState([])
  const [rolesReady, setRolesReady] = useState(false)
  const [roleError, setRoleError] = useState('')
  const [capacity, setCapacity] = useState(null)
  const [employees, setEmployees] = useState([])
  const [loading, setLoading] = useState(true)
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)
  const [isEditModalOpen, setIsEditModalOpen] = useState(false)
  const [selectedEmployee, setSelectedEmployee] = useState(null)
  const [submitting, setSubmitting] = useState(false)
  const [sendingReset, setSendingReset] = useState(false)
  const [whatsappError, setWhatsappError] = useState('')

  const [employeeForm, setEmployeeForm] = useState({
    full_name: '',
    email: '',
    password: '',
    role_id: '',
    whatsapp: ''
  })

  useEffect(() => {
    fetchEmployees()
    fetchCapacity()
    const refreshRoles = () => fetchRoles()
    refreshRoles()
    window.addEventListener('focus', refreshRoles)
    return () => window.removeEventListener('focus', refreshRoles)
  }, [])

  const fetchCapacity = async () => {
    if (!tenantMode()) return
    try { setCapacity(await workRpc('work_organization_capacity')) }
    catch { setCapacity(null) }
  }

  const fetchRoles = async () => {
    try {
      const data = await workRpc('work_roles_overview')
      setRoles(data.roles); setAssignments(data.assignments); setRolesReady(true); setRoleError('')
    } catch(e) { setRolesReady(false); setRoleError('No se pudieron cargar los roles. Comprueba que instalaste 15-ROLES-DE-EMPLEADOS.sql en Supabase.') }
  }
  const roleIdFor = id => assignments.find(a=>a.user_id===id)?.role_id || ''
  const roleNameFor = id => roles.find(r=>r.id===roleIdFor(id))?.name || 'Sin rol'
  const roleField = prefix => <div className="space-y-2"><Label htmlFor={prefix+'-role'}>Rol de trabajo</Label><select id={prefix+'-role'} className="w-full border rounded-md bg-white p-2" disabled={!rolesReady||submitting} value={employeeForm.role_id} onChange={e=>setEmployeeForm(prev=>({...prev,role_id:e.target.value}))}><option value="">Sin rol asignado</option>{roles.filter(r=>r.active||r.id===employeeForm.role_id).map(r=><option key={r.id} value={r.id}>{r.name}{r.active?'':' (desactivado)'}</option>)}</select><p className="text-xs text-gray-500">Crea y gestiona los roles en la sección Roles.</p></div>

  const fetchEmployees = async () => {
    try {
      setLoading(true)
      let data
      if(tenantMode())data=await workRpc('mt_employees')
      else {
        const response=await supabase.from('users').select('*').eq('is_admin',false).order('created_at',{ascending:false})
        if(response.error)throw response.error
        data=response.data
      }

      setEmployees(data || [])
    } catch (error) {
      console.error('Error fetching employees:', error)
      toast.error('Error al cargar empleados')
    } finally {
      setLoading(false)
    }
  }

  const handleWhatsappChange = (value) => {
    setWhatsappError('')
    setEmployeeForm(prev => ({ ...prev, whatsapp: value }))
  }

  const validateWhatsappField = () => {
    try { normalizeWhatsApp(employeeForm.whatsapp); setWhatsappError('') }
    catch (error) { setWhatsappError(error.message) }
  }

  const handleCreateEmployee = async (e) => {
    e.preventDefault()
    if (submitting || !rolesReady) return
    setSubmitting(true)
    try {
      const result = await createEmployeeAccount(employeeForm)
      toast.success(result.confirmationRequired
        ? 'Empleado creado. Debe confirmar su email antes de acceder.'
        : 'Empleado creado y perfil guardado correctamente')
      setIsCreateModalOpen(false)
      resetForm()
      await fetchEmployees(); await fetchRoles()
      await fetchCapacity()
    } catch (error) {
      console.error('Error creating employee:', error?.code || 'unknown')
      toast.error(error.message || 'No se pudo crear el empleado')
      if (error?.code === 'INVALID_WHATSAPP') setWhatsappError(error.message)
      // Never retain the initial password after a failed or partial attempt.
      setEmployeeForm(prev => ({ ...prev, password: '' }))
      if (error?.code === 'EMPLOYEE_PROFILE_INCOMPLETE') await fetchEmployees()
    } finally {
      setSubmitting(false)
    }
  }

  const handleEditEmployee = async (e) => {
    const operationOrganization=currentOrganization()
    e.preventDefault()
    if (submitting || !rolesReady) return
    setSubmitting(true)

    try {
      const whatsapp = normalizeWhatsApp(employeeForm.whatsapp)
      if (employeeForm.email.trim().toLowerCase() !== selectedEmployee.email.trim().toLowerCase()) {
        const { data, error, response } = await supabase.functions.invoke('update-employee-email', {
          body: { userId: selectedEmployee.id, email: employeeForm.email.trim().toLowerCase() }
        })
        if (error || !data?.success) {
          throw await employeeEmailError(data, error, response)
        }
      }
      if(operationOrganization!==currentOrganization())throw new Error('La empresa activa cambió. Revisa el empleado antes de guardar.')
      // Email changes are verified by the Auth service; profile and role save together.
      await workRpc('work_save_employee_profile', {p_user:selectedEmployee.id,p_name:employeeForm.full_name,p_whatsapp:whatsapp,p_role:employeeForm.role_id || null})
      await fetchRoles()

      toast.success('✅ Empleado actualizado correctamente')
      setIsEditModalOpen(false)
      setSelectedEmployee(null)
      resetForm()
      fetchEmployees()
    } catch (error) {
      console.error('Error updating employee:', error?.code || 'unknown')
      if (error?.code === 'INVALID_WHATSAPP') setWhatsappError(error.message)
      toast.error(error.message || 'Error al actualizar empleado')
    } finally {
      setSubmitting(false)
    }
  }

  const handleSendPasswordReset = async () => {
    if (!selectedEmployee?.id || sendingReset) return
    setSendingReset(true)
    try {
      await requestEmployeePasswordReset(selectedEmployee.id)
      toast.success('Solicitud aceptada. El empleado debe revisar su correo y la carpeta de spam.')
    } catch (error) {
      console.error('Error requesting password reset:', error?.code || 'unknown')
      toast.error(error.message || 'No se pudo solicitar la recuperación de contraseña')
    } finally {
      setSendingReset(false)
    }
  }

  const handleDeleteEmployee = async (employeeId, employeeName) => {
    const confirm = window.confirm(`¿Estás seguro de eliminar al empleado "${employeeName}"?`)
    if (!confirm) return

    try {
      if(tenantMode())await workRpc('mt_delete_employee',{p_user:employeeId})
      else {
        const {error}=await supabase.from('users').delete().eq('id',employeeId)
        if(error)throw error
      }

      toast.success('✅ Empleado eliminado')
      fetchEmployees()
    } catch (error) {
      console.error('Error deleting employee:', error)
      toast.error('Error al eliminar empleado')
    }
  }

  const openEditModal = (employee) => {
    setWhatsappError('')
    setSelectedEmployee(employee)
    setEmployeeForm({
      full_name: employee.full_name,
      email: employee.email,
      password: '',
      role_id: roleIdFor(employee.id),
      whatsapp: employee.whatsapp || ''
    })
    setIsEditModalOpen(true)
  }

  const resetForm = () => {
    setWhatsappError('')
    setEmployeeForm({
      full_name: '',
      email: '',
      password: '',
      role_id: '',
    whatsapp: ''
    })
  }

  const getEmployeeStats = () => {
    return {
      total: employees.length,
      withoutRole: employees.filter(e=>!roleIdFor(e.id)).length
    }
  }

  const filteredEmployees = employees.filter(e=>(e.full_name+' '+e.email+' '+(e.whatsapp||'')).toLocaleLowerCase('es').includes(search.toLocaleLowerCase('es')) && (!roleFilter||(roleFilter==='none'?!roleIdFor(e.id):roleIdFor(e.id)===roleFilter)))
  const stats = getEmployeeStats()
  const capacityReached = capacity && !capacity.can_add

  return (
    <Layout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">👥 Gestionar Empleados</h1>
            <p className="text-gray-900 mt-1">Administra tu equipo de trabajo</p>
          </div>
          <div className="flex flex-wrap gap-2">

            <Button variant="outline" asChild><Link to="/admin/team/roles">Roles</Link></Button>
            <Button variant="outline" asChild><Link to="/admin/team/areas">Áreas</Link></Button>
            <Button variant="outline" asChild><Link to="/admin/team/absences">Ausencias</Link></Button>

            <Button
              onClick={() => setIsCreateModalOpen(true)} disabled={capacityReached}
              className="bg-blue-600 hover:bg-blue-700 text-white"
            >
              <Plus className="mr-2 h-4 w-4" />
              Nuevo Empleado
            </Button>
          </div>
        </div>

        {roleError && <p role="alert" className="rounded-lg bg-red-50 text-red-800 p-4">{roleError} <Button variant="outline" onClick={fetchRoles}>Reintentar</Button></p>}
        {capacity && <Alert className={capacityReached?'border-amber-500 bg-amber-50':'bg-blue-50'}><AlertCircle className="h-4 w-4"/><AlertDescription className="text-gray-900"><strong>{capacity.used} de {capacity.limit} usuarios utilizados.</strong> {capacityReached?'Para añadir otra persona debe desactivar una cuenta o ampliar el límite contratado.':`Quedan ${capacity.available} plazas disponibles.`}</AlertDescription></Alert>}
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
                  <p className="text-sm text-gray-900">Sin rol asignado</p>
                  <p className="text-3xl font-bold text-gray-900">{rolesReady?stats.withoutRole:'—'}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="grid sm:grid-cols-2 gap-3"><Input aria-label="Buscar empleados" placeholder="Buscar por nombre, email o WhatsApp" value={search} onChange={e=>setSearch(e.target.value)}/><select aria-label="Filtrar empleados por rol" className="w-full border rounded-md bg-white p-2" value={roleFilter} onChange={e=>setRoleFilter(e.target.value)}><option value="">Todos los roles</option><option value="none">Sin rol asignado</option>{roles.map(r=><option key={r.id} value={r.id}>{r.name}</option>)}</select></div>
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
            ) : filteredEmployees.length === 0 ? (
              <div className="text-center py-12">
                <Users className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-900 mb-4">{employees.length?'No hay empleados con estos filtros':'No hay empleados registrados'}</p>
                <Button onClick={() => setIsCreateModalOpen(true)} disabled={capacityReached}>
                  <Plus className="mr-2 h-4 w-4" />
                  Crear Primer Empleado
                </Button>
              </div>
            ) : (
              <>
              <MobileEmployees items={filteredEmployees} roleName={roleNameFor} rolesReady={rolesReady} onPlan={employee=>navigate('/admin/planning?employee='+employee.id)} onHistory={employee=>navigate('/admin/checkins?employee='+employee.id)} onEdit={openEditModal} onDelete={handleDeleteEmployee}/>
              <div className="hidden md:block rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="text-gray-900">Nombre Completo</TableHead>
                      <TableHead className="text-gray-900">Rol</TableHead>
                      <TableHead className="text-gray-900">Email</TableHead>
                      <TableHead className="text-gray-900">WhatsApp</TableHead>
                      <TableHead className="text-gray-900">Fecha Registro</TableHead>
                      <TableHead className="text-right text-gray-900">Acciones</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredEmployees.map((employee) => (
                      <TableRow key={employee.id}>
                        <TableCell className="font-medium text-gray-900">
                          {employee.full_name}
                        </TableCell>
                        <TableCell className="text-gray-900">{rolesReady?roleNameFor(employee.id):'No disponible'}</TableCell>
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
                          <Button size="sm" variant="outline" onClick={()=>navigate('/admin/planning?employee='+employee.id)}>Planificación</Button>
                          <Button size="sm" variant="outline" onClick={()=>navigate('/admin/checkins?employee='+employee.id)}>Fichajes</Button>
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
              </>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Modal Crear Empleado */}
      <Dialog open={isCreateModalOpen} onOpenChange={setIsCreateModalOpen}>
        <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-gray-900">👤 Crear Nuevo Empleado</DialogTitle>
            <DialogDescription className="text-gray-900">
              Completa los datos del nuevo empleado
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleCreateEmployee} className="space-y-4">
            {roleField('create')}
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
                onChange={(e) => handleWhatsappChange(e.target.value)}
                onBlur={validateWhatsappField}
                inputMode="tel"
                autoComplete="tel"
                maxLength={32}
                aria-invalid={Boolean(whatsappError)}
                placeholder="+34 600 000 000"
                className="text-gray-900"
              />
              {whatsappError && <p role="alert" className="text-sm text-red-700">{whatsappError}</p>}
              <p className="text-xs text-gray-600">Opcional. Entre 7 y 15 dígitos; puedes incluir el prefijo de país.</p>
            </div>

            <Alert className="bg-blue-50 border-blue-200">
              <AlertCircle className="h-4 w-4 text-blue-600" />
              <AlertDescription className="text-blue-800 text-sm">
                El empleado recibirá un email de confirmación en su correo.
              </AlertDescription>
            </Alert>

            <Button
              type="submit"
              disabled={submitting || !rolesReady}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white"
            >
              {submitting ? '⏳ Creando...' : '✅ Crear Empleado'}
            </Button>
          </form>
        </DialogContent>
      </Dialog>

      {/* Modal Editar Empleado */}
      <Dialog open={isEditModalOpen} onOpenChange={setIsEditModalOpen}>
        <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-gray-900">✏️ Editar Empleado</DialogTitle>
            <DialogDescription className="text-gray-900">
              Modifica los datos del empleado
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleEditEmployee} className="space-y-4">
            {roleField('edit')}
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

            <div className="space-y-2 rounded-md border bg-blue-50 p-3">
              <p className="font-medium text-gray-900">Recuperar contraseña</p>
              <p className="text-sm text-gray-700">
                El empleado recibirá un enlace en su email guardado y elegirá una contraseña nueva.
                Guarda antes cualquier cambio de email.
              </p>
              <Button type="button" variant="outline" disabled={sendingReset || submitting}
                onClick={handleSendPasswordReset}>
                {sendingReset ? 'Solicitando envío…' : 'Enviar enlace de recuperación'}
              </Button>
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-whatsapp" className="text-gray-900 font-semibold">
                WhatsApp (opcional)
              </Label>
              <Input
                id="edit-whatsapp"
                type="tel"
                value={employeeForm.whatsapp}
                onChange={(e) => handleWhatsappChange(e.target.value)}
                onBlur={validateWhatsappField}
                inputMode="tel"
                autoComplete="tel"
                maxLength={32}
                aria-invalid={Boolean(whatsappError)}
                placeholder="+34 600 000 000"
                className="text-gray-900"
              />
              {whatsappError && <p role="alert" className="text-sm text-red-700">{whatsappError}</p>}
              <p className="text-xs text-gray-600">Opcional. Entre 7 y 15 dígitos; puedes incluir el prefijo de país.</p>
            </div>

            <Button
              type="submit"
              disabled={submitting || !rolesReady}
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
