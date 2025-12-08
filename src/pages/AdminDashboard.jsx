import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import Layout from '@/components/layout/Layout'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
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
import { Checkbox } from '@/components/ui/checkbox'
import { 
  Plus, 
  Edit, 
  Trash2, 
  Calendar,
  Users,
  CheckSquare,
  QrCode,
  MapPin
} from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { supabase } from '@/lib/supabase'

export default function AdminDashboard() {
  const navigate = useNavigate()
  const [tasks, setTasks] = useState([])
  const [employees, setEmployees] = useState([])
  const [loading, setLoading] = useState(true)
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)
  const [isEditModalOpen, setIsEditModalOpen] = useState(false)
  const [selectedTask, setSelectedTask] = useState(null)
  
  const [taskForm, setTaskForm] = useState({
    title: '',
    description: '',
    schedule_type: 'daily',
    schedule_date: '',
    status: 'pending',
    assigned_users: []
  })

  useEffect(() => {
    fetchTasks()
    fetchEmployees()
  }, [])

  const fetchTasks = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('tasks')
        .select(`
          *,
          task_assignments (
            user_id,
            users (
              id,
              full_name,
              email
            )
          )
        `)
        .order('created_at', { ascending: false })

      if (error) throw error

      const tasksWithUsers = data.map(task => {
        const assignedUsers = []
        if (task.task_assignments) {
          task.task_assignments.forEach(assignment => {
            if (assignment.users) {
              assignedUsers.push(assignment.users)
            }
          })
        }
        return {
          ...task,
          assigned_users: assignedUsers,
          assigned_names: assignedUsers.map(u => u.full_name).join(', ') || 'Sin asignar'
        }
      })

      setTasks(tasksWithUsers)
    } catch (error) {
      console.error('Error fetching tasks:', error)
      toast.error('Error al cargar las tareas')
    } finally {
      setLoading(false)
    }
  }

  const fetchEmployees = async () => {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('is_admin', false)
        .order('full_name')

      if (error) throw error
      setEmployees(data || [])
    } catch (error) {
      console.error('Error fetching employees:', error)
    }
  }

  const handleCreateTask = async (e) => {
    e.preventDefault()

    try {
      const { data: newTask, error: taskError } = await supabase
        .from('tasks')
        .insert([{
          title: taskForm.title,
          description: taskForm.description,
          schedule_type: taskForm.schedule_type,
          schedule_date: taskForm.schedule_date || null,
          status: taskForm.status
        }])
        .select()
        .single()

      if (taskError) throw taskError

      if (taskForm.assigned_users.length > 0) {
        const assignments = taskForm.assigned_users.map(userId => ({
          task_id: newTask.id,
          user_id: userId
        }))

        const { error: assignError } = await supabase
          .from('task_assignments')
          .insert(assignments)

        if (assignError) throw assignError
      }

      toast.success('✅ Tarea creada correctamente')
      setIsCreateModalOpen(false)
      resetForm()
      fetchTasks()
    } catch (error) {
      console.error('Error creating task:', error)
      toast.error('Error al crear la tarea')
    }
  }

  const handleEditTask = async (e) => {
    e.preventDefault()

    try {
      const { error: updateError } = await supabase
        .from('tasks')
        .update({
          title: taskForm.title,
          description: taskForm.description,
          schedule_type: taskForm.schedule_type,
          schedule_date: taskForm.schedule_date || null,
          status: taskForm.status
        })
        .eq('id', selectedTask.id)

      if (updateError) throw updateError

      const { error: deleteError } = await supabase
        .from('task_assignments')
        .delete()
        .eq('task_id', selectedTask.id)

      if (deleteError) throw deleteError

      if (taskForm.assigned_users.length > 0) {
        const assignments = taskForm.assigned_users.map(userId => ({
          task_id: selectedTask.id,
          user_id: userId
        }))

        const { error: assignError } = await supabase
          .from('task_assignments')
          .insert(assignments)

        if (assignError) throw assignError
      }

      toast.success('✅ Tarea actualizada correctamente')
      setIsEditModalOpen(false)
      setSelectedTask(null)
      resetForm()
      fetchTasks()
    } catch (error) {
      console.error('Error updating task:', error)
      toast.error('Error al actualizar la tarea')
    }
  }

  const handleDeleteTask = async (taskId) => {
    if (!window.confirm('¿Estás seguro de eliminar esta tarea?')) return

    try {
      const { error } = await supabase
        .from('tasks')
        .delete()
        .eq('id', taskId)

      if (error) throw error

      toast.success('✅ Tarea eliminada')
      fetchTasks()
    } catch (error) {
      console.error('Error deleting task:', error)
      toast.error('Error al eliminar la tarea')
    }
  }

  const openEditModal = (task) => {
    setSelectedTask(task)
    setTaskForm({
      title: task.title,
      description: task.description || '',
      schedule_type: task.schedule_type,
      schedule_date: task.schedule_date || '',
      status: task.status,
      assigned_users: task.assigned_users.map(u => u.id)
    })
    setIsEditModalOpen(true)
  }

  const resetForm = () => {
    setTaskForm({
      title: '',
      description: '',
      schedule_type: 'daily',
      schedule_date: '',
      status: 'pending',
      assigned_users: []
    })
  }

  const toggleUserAssignment = (userId) => {
    setTaskForm(prev => ({
      ...prev,
      assigned_users: prev.assigned_users.includes(userId)
        ? prev.assigned_users.filter(id => id !== userId)
        : [...prev.assigned_users, userId]
    }))
  }

  const getStatusBadge = (status) => {
    const variants = {
      pending: { bg: 'bg-yellow-100', text: 'text-yellow-800', label: 'Pendiente' },
      in_progress: { bg: 'bg-blue-100', text: 'text-blue-800', label: 'En Progreso' },
      completed: { bg: 'bg-green-100', text: 'text-green-800', label: 'Completada' }
    }
    const variant = variants[status] || variants.pending
    return <Badge className={`${variant.bg} ${variant.text} border-0`}>{variant.label}</Badge>
  }

  return (
    <Layout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">🏨 Panel de Administración</h1>
            <p className="text-gray-900 mt-1">Gestiona tareas, empleados y configuraciones</p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card className="cursor-pointer hover:shadow-lg transition-shadow" onClick={() => setIsCreateModalOpen(true)}>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="mx-auto w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mb-3">
                  <Plus className="h-6 w-6 text-blue-600" />
                </div>
                <h3 className="font-semibold text-gray-900">Crear Tarea</h3>
                <p className="text-sm text-gray-900 mt-1">Asigna nuevas tareas a tus empleados</p>
              </div>
            </CardContent>
          </Card>

          <Card className="cursor-pointer hover:shadow-lg transition-shadow" onClick={() => navigate('/admin/employees')}>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="mx-auto w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center mb-3">
                  <Users className="h-6 w-6 text-purple-600" />
                </div>
                <h3 className="font-semibold text-gray-900">Gestionar Empleados</h3>
                <p className="text-sm text-gray-900 mt-1">Administra tu equipo de trabajo</p>
              </div>
            </CardContent>
          </Card>

          <Card className="cursor-pointer hover:shadow-lg transition-shadow" onClick={() => navigate('/admin/qr-generator')}>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="mx-auto w-12 h-12 bg-indigo-100 rounded-full flex items-center justify-center mb-3">
                  <QrCode className="h-6 w-6 text-indigo-600" />
                </div>
                <h3 className="font-semibold text-gray-900">Códigos QR</h3>
                <p className="text-sm text-gray-900 mt-1">Genera QR para fichajes</p>
              </div>
            </CardContent>
          </Card>

          <Card className="cursor-pointer hover:shadow-lg transition-shadow" onClick={() => navigate('/admin/gps-locations')}>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="mx-auto w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mb-3">
                  <MapPin className="h-6 w-6 text-red-600" />
                </div>
                <h3 className="font-semibold text-gray-900">Ubicaciones GPS</h3>
                <p className="text-sm text-gray-900 mt-1">Configura validación de ubicación</p>
              </div>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="text-gray-900">📋 Tareas Creadas</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="text-center py-8">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
                <p className="mt-4 text-gray-900">Cargando tareas...</p>
              </div>
            ) : tasks.length === 0 ? (
              <div className="text-center py-12">
                <CheckSquare className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-900 mb-4">No hay tareas creadas</p>
                <Button onClick={() => setIsCreateModalOpen(true)}>
                  Crear Primera Tarea
                </Button>
              </div>
            ) : (
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="text-gray-900">Título</TableHead>
                      <TableHead className="text-gray-900">Tipo</TableHead>
                      <TableHead className="text-gray-900">Fecha</TableHead>
                      <TableHead className="text-gray-900">Asignados</TableHead>
                      <TableHead className="text-gray-900">Estado</TableHead>
                      <TableHead className="text-right text-gray-900">Acciones</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {tasks.map((task) => (
                      <TableRow key={task.id}>
                        <TableCell className="font-medium text-gray-900">{task.title}</TableCell>
                        <TableCell className="text-gray-900">
                          {task.schedule_type === 'daily' && '🔄 Diaria'}
                          {task.schedule_type === 'weekly' && '📅 Semanal'}
                          {task.schedule_type === 'monthly' && '📆 Mensual'}
                          {task.schedule_type === 'custom_date' && '📅 Fecha específica'}
                        </TableCell>
                        <TableCell className="text-gray-900">
                          {task.schedule_date ? format(new Date(task.schedule_date), 'PPP', { locale: es }) : '-'}
                        </TableCell>
                        <TableCell className="text-gray-900">{task.assigned_names}</TableCell>
                        <TableCell>{getStatusBadge(task.status)}</TableCell>
                        <TableCell className="text-right space-x-2">
                          <Button size="sm" variant="outline" onClick={() => openEditModal(task)}>
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button size="sm" variant="outline" onClick={() => handleDeleteTask(task.id)} className="text-red-600 hover:text-red-700">
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

      <Dialog open={isCreateModalOpen} onOpenChange={setIsCreateModalOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle className="text-gray-900">Crear Nueva Tarea</DialogTitle>
            <DialogDescription className="text-gray-900">Completa los datos de la nueva tarea</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleCreateTask} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="title" className="text-gray-900 font-semibold">Título *</Label>
              <Input id="title" value={taskForm.title} onChange={(e) => setTaskForm(prev => ({ ...prev, title: e.target.value }))} required className="text-gray-900" />
            </div>

            <div className="space-y-2">
              <Label htmlFor="description" className="text-gray-900 font-semibold">Descripción</Label>
              <Textarea id="description" value={taskForm.description} onChange={(e) => setTaskForm(prev => ({ ...prev, description: e.target.value }))} rows={3} className="text-gray-900" />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="schedule_type" className="text-gray-900 font-semibold">Tipo de programación *</Label>
                <Select value={taskForm.schedule_type} onValueChange={(value) => setTaskForm(prev => ({ ...prev, schedule_type: value }))}>
                  <SelectTrigger className="text-gray-900">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="daily">Diaria</SelectItem>
                    <SelectItem value="weekly">Semanal</SelectItem>
                    <SelectItem value="monthly">Mensual</SelectItem>
                    <SelectItem value="custom_date">Fecha específica</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {taskForm.schedule_type === 'custom_date' && (
                <div className="space-y-2">
                  <Label htmlFor="schedule_date" className="text-gray-900 font-semibold">Fecha *</Label>
                  <Input id="schedule_date" type="date" value={taskForm.schedule_date} onChange={(e) => setTaskForm(prev => ({ ...prev, schedule_date: e.target.value }))} required className="text-gray-900" />
                </div>
              )}
            </div>

            <div className="space-y-2">
              <Label className="text-gray-900 font-semibold">Asignar a empleados</Label>
              <div className="border rounded-md p-4 max-h-48 overflow-y-auto space-y-2">
                {employees.map((employee) => (
                  <div key={employee.id} className="flex items-center space-x-2">
                    <Checkbox id={`emp-${employee.id}`} checked={taskForm.assigned_users.includes(employee.id)} onCheckedChange={() => toggleUserAssignment(employee.id)} />
                    <label htmlFor={`emp-${employee.id}`} className="text-sm text-gray-900 cursor-pointer">{employee.full_name} ({employee.email})</label>
                  </div>
                ))}
              </div>
            </div>

            <Button type="submit" className="w-full">Crear Tarea</Button>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={isEditModalOpen} onOpenChange={setIsEditModalOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle className="text-gray-900">Editar Tarea</DialogTitle>
            <DialogDescription className="text-gray-900">Modifica los datos de la tarea</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleEditTask} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="edit-title" className="text-gray-900 font-semibold">Título *</Label>
              <Input id="edit-title" value={taskForm.title} onChange={(e) => setTaskForm(prev => ({ ...prev, title: e.target.value }))} required className="text-gray-900" />
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-description" className="text-gray-900 font-semibold">Descripción</Label>
              <Textarea id="edit-description" value={taskForm.description} onChange={(e) => setTaskForm(prev => ({ ...prev, description: e.target.value }))} rows={3} className="text-gray-900" />
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-status" className="text-gray-900 font-semibold">Estado *</Label>
              <Select value={taskForm.status} onValueChange={(value) => setTaskForm(prev => ({ ...prev, status: value }))}>
                <SelectTrigger className="text-gray-900">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pending">Pendiente</SelectItem>
                  <SelectItem value="in_progress">En Progreso</SelectItem>
                  <SelectItem value="completed">Completada</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label className="text-gray-900 font-semibold">Asignar a empleados</Label>
              <div className="border rounded-md p-4 max-h-48 overflow-y-auto space-y-2">
                {employees.map((employee) => (
                  <div key={employee.id} className="flex items-center space-x-2">
                    <Checkbox id={`edit-emp-${employee.id}`} checked={taskForm.assigned_users.includes(employee.id)} onCheckedChange={() => toggleUserAssignment(employee.id)} />
                    <label htmlFor={`edit-emp-${employee.id}`} className="text-sm text-gray-900 cursor-pointer">{employee.full_name} ({employee.email})</label>
                  </div>
                ))}
              </div>
            </div>

            <Button type="submit" className="w-full">Guardar Cambios</Button>
          </form>
        </DialogContent>
      </Dialog>
    </Layout>
  )
}